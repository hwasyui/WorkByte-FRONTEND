import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/guideline_ack_model.dart';
import 'session_guard.dart';

class GuidelineService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  String _extractError(http.Response response, String fallback) {
    try {
      if (response.body.isNotEmpty && response.body.startsWith('{')) {
        final body = jsonDecode(response.body);
        return body['details'] ?? body['message'] ?? body['detail'] ?? fallback;
      }
      return response.body.isNotEmpty ? response.body : fallback;
    } catch (e) {
      return fallback;
    }
  }

  /// GET /users/{user_id}/guidelines-ack
  Future<GuidelineAckStatus> getAckStatus({
    required String token,
    required String userId,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/$userId/guidelines-ack'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 20));

    debugPrint('GET /users/$userId/guidelines-ack status: ${response.statusCode}');
    SessionGuard.check(response);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final inner = body['details'] ?? body['data'] ?? body;
      return GuidelineAckStatus.fromJson(inner as Map<String, dynamic>);
    }

    throw Exception(_extractError(response, 'Failed to load guidelines status'));
  }

  /// POST /users/{user_id}/guidelines-ack
  Future<GuidelineAckStatus> ackSection({
    required String token,
    required String userId,
    required String section,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/$userId/guidelines-ack'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'section': section}),
    ).timeout(const Duration(seconds: 20));

    debugPrint('POST /users/$userId/guidelines-ack status: ${response.statusCode}');
    SessionGuard.check(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body);
      final inner = body['details'] ?? body['data'] ?? body;
      return GuidelineAckStatus.fromJson(inner as Map<String, dynamic>);
    }

    throw Exception(_extractError(response, 'Failed to acknowledge guidelines'));
  }
}
