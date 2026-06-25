import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/report_model.dart';

class ReportService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  /// GET /reports/reasons
  Future<List<String>> getReportReasons(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/reports/reasons'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);
    debugPrint('GET /reports/reasons response: $body');

    if (response.statusCode == 200) {
      final inner = body['details'] ?? body['data'] ?? body;
      if (inner is List) return List<String>.from(inner);
      if (inner is Map && inner['reasons'] != null) {
        return List<String>.from(inner['reasons']);
      }
    }

    throw Exception(
      body['details'] ??
          body['message'] ??
          body['detail'] ??
          'Failed to load report reasons',
    );
  }

  /// POST /reports
  /// [reportedType]   : 'freelancer' | 'client' | 'job_post'
  /// [reportedUserId] : required for freelancer / client reports
  /// [jobPostId]      : required for job_post reports
  Future<ReportModel> createReport({
    required String token,
    required String reportedType,
    String? reportedUserId,
    String? jobPostId,
    required List<String> reasons,
    String? customReason,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/reports'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'reported_type': reportedType,
        if (reportedUserId != null) 'reported_user_id': reportedUserId,
        if (jobPostId != null) 'job_post_id': jobPostId,
        'reasons': reasons,
        if (customReason != null && customReason.isNotEmpty)
          'custom_reason': customReason,
      }),
    );

    final body = jsonDecode(response.body);
    debugPrint('POST /reports response: $body');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final inner = body['details'] ?? body['data'] ?? body;
      return ReportModel.fromJson(inner as Map<String, dynamic>);
    }

    throw Exception(
      body['details'] ??
          body['message'] ??
          body['detail'] ??
          'Failed to submit report',
    );
  }
}
