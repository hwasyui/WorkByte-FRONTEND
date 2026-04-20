import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/contract_message_model.dart';

class ContractMessageService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<ContractMessageModel>> getMessagesByContract(
    String token,
    String contractId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/messages/contract/$contractId'),
      headers: _headers(token),
    );

    final body = jsonDecode(res.body);
    debugPrint('GET /messages/contract/$contractId → ${res.statusCode}');

    if (res.statusCode == 200) {
      final list = body['details'] ?? body['data'] ?? body;
      return (list as List)
          .map((e) => ContractMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to load messages');
  }

  Future<ContractMessageModel> sendMessage({
    required String token,
    required String contractId,
    required String messageText,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/messages'),
      headers: _headers(token),
      body: jsonEncode({
        'contract_id': contractId,
        'message_text': messageText.trim(),
      }),
    );

    final body = jsonDecode(res.body);
    debugPrint('POST /messages → ${res.statusCode}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      return ContractMessageModel.fromJson(
        body['details'] ?? body['data'] ?? body,
      );
    }
    throw Exception(body['details'] ?? 'Failed to send message');
  }

  Future<void> markMessagesAsRead({
    required String token,
    required String contractId,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/messages/contract/$contractId/read'),
      headers: _headers(token),
    );

    final body = jsonDecode(res.body);
    debugPrint('PUT /messages/contract/$contractId/read → ${res.statusCode}');

    if (res.statusCode != 200) {
      throw Exception(body['details'] ?? 'Failed to mark messages as read');
    }
  }
}
