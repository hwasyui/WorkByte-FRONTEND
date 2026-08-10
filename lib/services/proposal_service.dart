import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/utils/moderation_display.dart';
import '../models/proposal_model.dart';
import '../models/role_bid_group_model.dart';
import 'session_guard.dart';

class ProposalFailureException implements Exception {
  final String message;

  final bool blockedByModeration;

  const ProposalFailureException(
    this.message, {
    this.blockedByModeration = false,
  });

  @override
  String toString() => message;
}

class ProposalService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, String> _authHeader(String token) => {
    'Authorization': 'Bearer $token',
  };

  /// Builds `$_baseUrl$path` with only the non-null params attached, so a call
  /// that passes nothing hits exactly the same URL it always did and keeps the
  /// backend's own defaults.
  Uri _uri(String path, [Map<String, String?> params = const {}]) {
    final uri = Uri.parse('$_baseUrl$path');
    final query = {
      for (final entry in params.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
    return query.isEmpty ? uri : uri.replace(queryParameters: query);
  }

  List<ProposalModel> _parseProposalList(dynamic body) {
    final list = body['details'] ?? body['data'] ?? body;
    return (list as List)
        .map((e) => ProposalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// [sortBy] accepts relevance | submitted_at | proposed_budget | rating |
  /// total_jobs. Note that `relevance` across a whole post only ranks roughly:
  /// scores are computed per role, so bids on different roles are not really
  /// comparable. Use [getProposalsByJobRole] or [getProposalsGroupedByRole]
  /// when the ranking has to hold up.
  Future<List<ProposalModel>> getProposalsByJobPost(
    String token,
    String jobPostId, {
    String? jobRoleId,
    String? status,
    String? sortBy,
    String? sortOrder,
  }) async {
    final uri = _uri('/proposals/job-post/$jobPostId', {
      'job_role_id': jobRoleId,
      'status': status,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    });
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(uri, headers: _headers(t))
          .timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET ${uri.path}${uri.hasQuery ? '?${uri.query}' : ''} status: ${res.statusCode}');
    if (res.statusCode == 200) {
      return _parseProposalList(body);
    }
    throw Exception(body['details'] ?? 'Failed to load proposals');
  }

  /// Bids on a single role — the scope where `relevance_score` is directly
  /// comparable between proposals. Defaults to the backend's relevance sort.
  Future<List<ProposalModel>> getProposalsByJobRole(
    String token,
    String jobRoleId, {
    String? status,
    String? sortBy,
    String? sortOrder,
  }) async {
    final uri = _uri('/proposals/job-role/$jobRoleId', {
      'status': status,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    });
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(uri, headers: _headers(t))
          .timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET ${uri.path}${uri.hasQuery ? '?${uri.query}' : ''} status: ${res.statusCode}');
    if (res.statusCode == 200) {
      return _parseProposalList(body);
    }
    throw Exception(body['details'] ?? 'Failed to load role proposals');
  }

  /// Every role on a post with its own independently sorted bid list,
  /// including roles nobody has bid on yet.
  Future<List<RoleBidGroup>> getProposalsGroupedByRole(
    String token,
    String jobPostId, {
    String? status,
    String? sortBy,
    String? sortOrder,
  }) async {
    final uri = _uri('/proposals/job-post/$jobPostId/by-role', {
      'status': status,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    });
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(uri, headers: _headers(t))
          .timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET ${uri.path}${uri.hasQuery ? '?${uri.query}' : ''} status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final payload = body['details'] ?? body['data'] ?? body;
      final roles = (payload as Map<String, dynamic>)['roles'] as List? ?? const [];
      return roles
          .map((e) => RoleBidGroup.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to load proposals by role');
  }

  Future<List<ProposalModel>> getProposalsByFreelancer(
    String token,
    String freelancerId,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/proposals/freelancer/$freelancerId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /proposals/freelancer/$freelancerId status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final list = body['details'] ?? body['data'] ?? body;
      return (list as List)
          .map((e) => ProposalModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to load proposals');
  }

  Future<ProposalModel> getProposalById(String token, String proposalId) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/proposals/$proposalId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return ProposalModel.fromJson(body['details'] ?? body['data'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to load proposal');
  }

  Future<ProposalModel> createProposal(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.post(
        Uri.parse('$_baseUrl/proposals'),
        headers: _headers(t),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('POST /proposals status: ${res.statusCode}');
    if (res.statusCode == 200 || res.statusCode == 201) {
      return ProposalModel.fromJson(body['details'] ?? body['data'] ?? body);
    }
    throw ProposalFailureException(
      (body['details'] ?? 'Failed to create proposal').toString(),
      blockedByModeration: isModerationBlockedBody(body),
    );
  }

  Future<ProposalModel> submitProposal({
    required String token,
    required String jobPostId,
    required String jobRoleId,
    required String freelancerId,
    required String coverLetter,
    required double proposedBudget,
    String? proposedDuration,
    List<PlatformFile> files = const [],
  }) async {
    final proposal = await createProposal(token, {
      'job_post_id': jobPostId,
      'job_role_id': jobRoleId,
      'freelancer_id': freelancerId,
      'cover_letter': coverLetter,
      'proposed_budget': proposedBudget,
      if (proposedDuration != null && proposedDuration.isNotEmpty)
        'proposed_duration': proposedDuration,
    });

    if (files.isNotEmpty) {
      final dartFiles = files
          .where((f) => f.path != null)
          .map((f) => File(f.path!))
          .toList();

      if (dartFiles.isNotEmpty) {
        await _uploadProposalFiles(
          token: token,
          proposalId: proposal.proposalId,
          files: dartFiles,
        );
      }
    }

    return proposal;
  }

  Future<void> _uploadProposalFiles({
    required String token,
    required String proposalId,
    required List<File> files,
  }) async {
    final uri = Uri.parse('$_baseUrl/proposal-files');

    final res = await SessionGuard.guard(token, (t) async {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(_authHeader(t))
        ..fields['proposal_id'] = proposalId;

      for (final file in files) {
        final fileName = file.path.split('/').last;
        final mimeType = _guessMime(fileName);
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            file.path,
            contentType: MediaType.parse(mimeType),
            filename: fileName,
          ),
        );
      }

      debugPrint('Uploading ${files.length} file(s) to /proposal-files');
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      return http.Response.fromStream(streamed);
    });
    debugPrint('POST /proposal-files status: ${res.statusCode}, body: ${res.body}');

    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['details'] ?? 'Failed to upload proposal files');
    }
  }

  String _guessMime(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const map = {
      'pdf': 'application/pdf',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'doc': 'application/msword',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'xls': 'application/vnd.ms-excel',
      'txt': 'text/plain',
      'zip': 'application/zip',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  Future<ProposalModel> updateProposal(
    String token,
    String proposalId,
    Map<String, dynamic> data,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.put(
        Uri.parse('$_baseUrl/proposals/$proposalId'),
        headers: _headers(t),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('PUT /proposals/$proposalId status: ${res.statusCode}');
    if (res.statusCode == 200) {
      return ProposalModel.fromJson(body['details'] ?? body['data'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to update proposal');
  }

  Future<ProposalModel> updateProposalStatus(
    String token,
    String proposalId,
    String status,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.patch(
        Uri.parse('$_baseUrl/proposals/$proposalId/status?status=$status'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('PATCH /proposals/$proposalId/status status: ${res.statusCode}');
    if (res.statusCode == 200) {
      return ProposalModel.fromJson(body['details'] ?? body['data'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to update proposal status');
  }

  Future<void> deleteProposal(String token, String proposalId) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.delete(
        Uri.parse('$_baseUrl/proposals/$proposalId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['details'] ?? 'Failed to delete proposal');
    }
  }

  Future<void> sendMessage(
    String token, {
    required String senderId,
    required String receiverId,
    required String messageText,
    String? contractId,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.post(
        Uri.parse('$_baseUrl/messages'),
        headers: _headers(t),
        body: jsonEncode({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'message_text': messageText,
          if (contractId != null) 'contract_id': contractId,
        }),
      ).timeout(const Duration(seconds: 20)),
    );
    debugPrint('POST /messages status: ${res.statusCode}');
    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['details'] ?? 'Failed to send message');
    }
  }
}
