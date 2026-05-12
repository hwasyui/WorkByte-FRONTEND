import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/appeal_model.dart';

class AppealService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  /// POST /appeals
  /// [targetType] : 'user' | 'job_post'
  Future<AppealModel> submitAppeal({
    required String token,
    required String targetType,
    required String targetId,
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/appeals'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'target_type': targetType,
        'target_id': targetId,
        'message': message,
      }),
    );

    final body = jsonDecode(response.body);
    debugPrint('POST /appeals response: $body');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final inner = body['details'] ?? body['data'] ?? body;
      return AppealModel.fromJson(inner as Map<String, dynamic>);
    }

    throw Exception(
      body['details'] ??
          body['message'] ??
          body['detail'] ??
          'Failed to submit appeal',
    );
  }

  /// GET /appeals/mine
  Future<List<AppealModel>> getMyAppeals(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/appeals/mine'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);
    debugPrint('GET /appeals/mine response: $body');

    if (response.statusCode == 200) {
      final inner = body['details'] ?? body['data'] ?? body;
      final list = inner is List ? inner : (inner['appeals'] as List? ?? []);
      return list
          .map((e) => AppealModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      body['details'] ??
          body['message'] ??
          body['detail'] ??
          'Failed to load appeals',
    );
  }
}
