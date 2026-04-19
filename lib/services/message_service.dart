import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MessageService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// POST /messages
  /// Send a message to another user
  Future<Map<String, dynamic>> sendMessage(
    String token,
    String senderId,
    String receiverId,
    String messageText, {
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

    final body = jsonDecode(res.body);
    debugPrint('POST /messages → ${res.statusCode}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      return body['details'] ?? body['data'] ?? body;
    }

    throw Exception(body['details'] ?? 'Failed to send message');
  }
}
