import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/proposal_model.dart';
import 'upload_service.dart';

class ProposalService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  final _uploadService = UploadService(); // ← single instance

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── Proposals ─────────────────────────────────────────────────────────────

  /// GET /proposals/job-post/:jobPostId
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

  /// GET /proposals/freelancer/:freelancerId
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

  /// GET /proposals/:proposalId
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

  /// POST /proposals
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

  /// Full submit: create proposal → upload files → register in DB
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
    // Step 1 — create proposal record
    final proposal = await createProposal(token, {
      'job_post_id': jobPostId,
      'job_role_id': jobRoleId,
      'freelancer_id': freelancerId,
      'cover_letter': coverLetter,
      'proposed_budget': proposedBudget,
      if (proposedDuration != null && proposedDuration.isNotEmpty)
        'proposed_duration': proposedDuration,
    });

    // Step 2 — upload each file, then register in proposal_file table
    for (final file in files) {
      if (file.path == null) continue;
      await _uploadProposalFile(
        token: token,
        proposalId: proposal.proposalId,
        file: file,
      );
    }

    return proposal;
  }

  // ── File Upload ───────────────────────────────────────────────────────────

  Future<void> _uploadProposalFile({
    required String token,
    required String proposalId,
    required PlatformFile file,
  }) async {
    // Step 1 — upload via UploadService to proposal-files bucket
    final uploaded = await _uploadService.uploadPlatformFile(
      token,
      file,
      bucket: 'proposal-files',
    );

    if (uploaded == null)
      throw Exception('Upload returned null for ${file.name}');

    final res = await http.post(
      Uri.parse('$_baseUrl/proposal-files'),
      headers: _headers(token),
      body: jsonEncode({
        'proposal_id': proposalId,
        'file_url': uploaded['file_url'],
        'file_name': uploaded['file_name'],
        'file_type': uploaded['file_type'],
        'file_size': uploaded['file_size'],
      }),
    );

    debugPrint('POST /proposal-files → ${res.statusCode}');
    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(
        body['details'] ?? 'Failed to register file ${file.name}',
      );
    }
  }

  // ── Other endpoints ───────────────────────────────────────────────────────

  /// PUT /proposals/:proposalId
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

  /// DELETE /proposals/:proposalId
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

  /// POST /messages
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
