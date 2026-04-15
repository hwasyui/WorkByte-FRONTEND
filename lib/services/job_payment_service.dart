// ── lib/services/job_payment_service.dart ───────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/job_payment_model.dart';

class JobPaymentService {
  static final String baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/+$'),
    '',
  );

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── Create payment record ─────────────────────────────────────────────────
  Future<JobPaymentModel> createPayment(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/job-payments'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    debugPrint('POST /job-payments → ${res.statusCode} $body');
    if (res.statusCode == 200 || res.statusCode == 201) {
      return JobPaymentModel.fromJson(body['details'] ?? body['data'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to create payment');
  }

  // ── Create a single milestone ─────────────────────────────────────────────
  Future<JobMilestoneModel> createMilestone(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/job-milestones'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    debugPrint('POST /job-milestones → ${res.statusCode} $body');
    if (res.statusCode == 200 || res.statusCode == 201) {
      return JobMilestoneModel.fromJson(
        body['details'] ?? body['data'] ?? body,
      );
    }
    throw Exception(body['details'] ?? 'Failed to create milestone');
  }
}
