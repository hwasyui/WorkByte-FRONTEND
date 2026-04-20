import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/proposal_model.dart';

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

  Future<List<ProposalModel>> getProposalsByJobPost(
    String token,
    String jobPostId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/proposals/job-post/$jobPostId'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /proposals/job-post/$jobPostId → ${res.statusCode}');
    if (res.statusCode == 200) {
      final list = body['details'] ?? body['data'] ?? body;
      return (list as List)
          .map((e) => ProposalModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to load proposals');
  }

  Future<List<ProposalModel>> getProposalsByFreelancer(
    String token,
    String freelancerId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/proposals/freelancer/$freelancerId'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /proposals/freelancer/$freelancerId → ${res.statusCode}');
    if (res.statusCode == 200) {
      final list = body['details'] ?? body['data'] ?? body;
      return (list as List)
          .map((e) => ProposalModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to load proposals');
  }

  Future<ProposalModel> getProposalById(String token, String proposalId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/proposals/$proposalId'),
      headers: _headers(token),
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
    final res = await http.post(
      Uri.parse('$_baseUrl/proposals'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final body = jsonDecode(res.body);
    debugPrint('POST /proposals → ${res.statusCode}');
    if (res.statusCode == 200 || res.statusCode == 201) {
      return ProposalModel.fromJson(body['details'] ?? body['data'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to create proposal');
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

    // Step 2 — upload all files in one multipart POST to /proposal-files
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

  /// Single multipart POST — backend handles Supabase upload + DB record creation
  Future<void> _uploadProposalFiles({
    required String token,
    required String proposalId,
    required List<File> files,
  }) async {
    final uri = Uri.parse('$_baseUrl/proposal-files');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authHeader(token))
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
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    debugPrint('POST /proposal-files → ${res.statusCode}: ${res.body}');

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
    final res = await http.put(
      Uri.parse('$_baseUrl/proposals/$proposalId'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final body = jsonDecode(res.body);
    debugPrint('PUT /proposals/$proposalId → ${res.statusCode}');
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
    final res = await http.patch(
      Uri.parse('$_baseUrl/proposals/$proposalId/status?status=$status'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    debugPrint('PATCH /proposals/$proposalId/status → ${res.statusCode}');
    if (res.statusCode == 200) {
      return ProposalModel.fromJson(body['details'] ?? body['data'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to update proposal status');
  }

  Future<void> deleteProposal(String token, String proposalId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/proposals/$proposalId'),
      headers: _headers(token),
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
    final res = await http.post(
      Uri.parse('$_baseUrl/messages'),
      headers: _headers(token),
      body: jsonEncode({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message_text': messageText,
        if (contractId != null) 'contract_id': contractId,
      }),
    );
    debugPrint('POST /messages → ${res.statusCode}');
    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['details'] ?? 'Failed to send message');
    }
  }
}
