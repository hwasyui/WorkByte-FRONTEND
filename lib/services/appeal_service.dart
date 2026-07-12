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
    ).timeout(const Duration(seconds: 20));

    debugPrint('POST /appeals status: ${response.statusCode}');
    debugPrint('POST /appeals body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final body = jsonDecode(response.body);
        final inner = body['details'] ?? body['data'] ?? body;
        return AppealModel.fromJson(inner as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Error parsing appeal response: $e');
        throw Exception('Failed to parse appeal response: $e');
      }
    }

    // Try to parse error response - handle both JSON and plain text
    String errorMsg = 'HTTP ${response.statusCode}: Failed to submit appeal';
    try {
      if (response.body.isNotEmpty && response.body.startsWith('{')) {
        final body = jsonDecode(response.body);
        errorMsg = body['details'] ??
            body['message'] ??
            body['detail'] ??
            errorMsg;
      } else {
        // Plain text response
        errorMsg = response.body.isNotEmpty
            ? response.body
            : errorMsg;
      }
    } catch (e) {
      debugPrint('Error parsing error response: $e');
      // Keep default errorMsg
    }
    throw Exception(errorMsg);
  }

  /// GET /appeals/mine
  Future<List<AppealModel>> getMyAppeals(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/appeals/mine'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 20));

    debugPrint('GET /appeals/mine status: ${response.statusCode}');
    debugPrint('GET /appeals/mine body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final body = jsonDecode(response.body);
        final inner = body['details'] ?? body['data'] ?? body;
        final list = inner is List ? inner : (inner['appeals'] as List? ?? []);
        return list
            .map((e) => AppealModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error parsing appeals response: $e');
        throw Exception('Failed to parse appeals response: $e');
      }
    }

    String errorMsg = 'HTTP ${response.statusCode}: Failed to load appeals';
    try {
      if (response.body.isNotEmpty && response.body.startsWith('{')) {
        final body = jsonDecode(response.body);
        errorMsg = body['details'] ??
            body['message'] ??
            body['detail'] ??
            errorMsg;
      } else {
        errorMsg = response.body.isNotEmpty ? response.body : errorMsg;
      }
    } catch (e) {
      debugPrint('Error parsing error response: $e');
    }
    throw Exception(errorMsg);
  }

  /// GET /appeals/status
  /// Check appeal eligibility and remaining attempts for a target
  /// Returns: {state, can_appeal, appeals_remaining, message}
  Future<Map<String, dynamic>> getAppealStatus({
    required String token,
    required String targetType,
    required String targetId,
  }) async {
    final uri = Uri.parse('$_baseUrl/appeals/status').replace(
      queryParameters: {
        'target_type': targetType,
        'target_id': targetId,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 20));

    debugPrint('GET /appeals/status status: ${response.statusCode}');
    debugPrint('GET /appeals/status body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final body = jsonDecode(response.body);
        final inner = body['details'] ?? body['data'] ?? body;
        return inner is Map<String, dynamic>
            ? inner
            : <String, dynamic>{};
      } catch (e) {
        debugPrint('Error parsing appeal status response: $e');
        throw Exception('Failed to parse appeal status response: $e');
      }
    }

    String errorMsg = 'HTTP ${response.statusCode}: Failed to check appeal status';
    try {
      if (response.body.isNotEmpty && response.body.startsWith('{')) {
        final body = jsonDecode(response.body);
        errorMsg = body['details'] ??
            body['message'] ??
            body['detail'] ??
            errorMsg;
      } else {
        errorMsg = response.body.isNotEmpty ? response.body : errorMsg;
      }
    } catch (e) {
      debugPrint('Error parsing error response: $e');
    }
    throw Exception(errorMsg);
  }
}
