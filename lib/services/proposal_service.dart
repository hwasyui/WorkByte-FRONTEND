import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/proposal_model.dart';

class ProposalService {
  static final String baseUrl = (dotenv.env['BACKEND_URL'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// GET /proposals/job-post/:jobPostId
  Future<List<ProposalModel>> getProposalsByJobPost(
    String token,
    String jobPostId,
  ) async {
    final res = await http.get(
      Uri.parse('$baseUrl/proposals/job-post/$jobPostId'),
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
      Uri.parse('$baseUrl/proposals/freelancer/$freelancerId'),
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
      Uri.parse('$baseUrl/proposals/$proposalId'),
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
      Uri.parse('$baseUrl/proposals'),
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

  /// PUT /proposals/:proposalId — used for accept, reject, or any field update
  Future<ProposalModel> updateProposal(
    String token,
    String proposalId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/proposals/$proposalId'),
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
      Uri.parse('$baseUrl/proposals/$proposalId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['details'] ?? 'Failed to delete proposal');
    }
  }

  /// POST /messages — send a direct message to a freelancer
  Future<void> sendMessage(
    String token, {
    required String senderId,
    required String receiverId,
    required String messageText,
    String? contractId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/messages'),
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
