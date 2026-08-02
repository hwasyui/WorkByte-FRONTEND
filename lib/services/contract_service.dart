import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/contract_model.dart';
import 'session_guard.dart';

class ContractService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<ContractModel>> getAllContracts(String token) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/contracts'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final details = body['details'];
      final list = (details is Map && details['items'] != null)
          ? details['items']
          : (details is List ? details : (body['data'] ?? []));
      return (list as List)
          .map((e) => ContractModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to load contracts');
  }

  Future<List<ContractModel>> getContractsByClient(
    String token,
    String clientId,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/contracts/client/$clientId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts/client/$clientId status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final details = body['details'];
      final list = (details is Map && details['items'] != null)
          ? details['items']
          : (details is List ? details : (body['data'] ?? []));
      return (list as List)
          .map((e) => ContractModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to load contracts');
  }

  Future<List<ContractModel>> getContractsByFreelancer(
    String token,
    String freelancerId,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/contracts/freelancer/$freelancerId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts/freelancer/$freelancerId status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final details = body['details'];
      final list = (details is Map && details['items'] != null)
          ? details['items']
          : (details is List ? details : (body['data'] ?? []));
      return (list as List)
          .map((e) => ContractModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to load contracts');
  }

  Future<ContractModel> getContractById(String token, String contractId) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/contracts/$contractId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts/$contractId status: ${res.statusCode}');
    if (res.statusCode == 200) {
      return ContractModel.fromJson(body['data'] ?? body['details'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to load contract');
  }

  Future<Map<String, dynamic>> getContractGenerationData(
    String token,
    String contractId,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/contracts/$contractId/generation-data'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint(
      'GET /contracts/$contractId/generation-data status: ${res.statusCode}',
    );
    if (res.statusCode == 200) {
      return body['data'] ?? body['details'] ?? {};
    }
    throw Exception(body['details'] ?? 'Failed to load generation data');
  }

  Future<String> getContractPdfUrl(String token, String contractId) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/contracts/$contractId/pdf-url'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts/$contractId/pdf-url status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final data = (body['details'] ?? body['data']) as Map<String, dynamic>?;
      final pdfUrl =
          data?['pdf_url'] as String? ?? data?['contract_pdf_url'] as String?;
      if (pdfUrl == null || pdfUrl.isEmpty) {
        throw Exception('PDF URL not found');
      }
      return pdfUrl;
    }
    throw Exception(body['details'] ?? 'Failed to get PDF URL');
  }

  Future<ContractModel> createContract(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.post(
        Uri.parse('$_baseUrl/contracts'),
        headers: _headers(t),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('POST /contracts status: ${res.statusCode}');
    if (res.statusCode == 201) {
      return ContractModel.fromJson(body['data'] ?? body['details'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to create contract');
  }

  Future<ContractModel> generateContractPdf(
    String token,
    String contractId,
    Map<String, dynamic> generationData,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.post(
        Uri.parse('$_baseUrl/contracts/$contractId/generate'),
        headers: _headers(t),
        body: jsonEncode(generationData),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('POST /contracts/$contractId/generate status: ${res.statusCode}');
    if (res.statusCode == 200) {
      return ContractModel.fromJson(body['data'] ?? body['details'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to generate contract');
  }

  Future<ContractModel> updateContract(
    String token,
    String contractId,
    Map<String, dynamic> data,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.put(
        Uri.parse('$_baseUrl/contracts/$contractId'),
        headers: _headers(t),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('PUT /contracts/$contractId status: ${res.statusCode}');
    if (res.statusCode == 200) {
      return ContractModel.fromJson(body['data'] ?? body['details'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to update contract');
  }

  Future<ContractModel> raiseDispute(
    String token,
    String contractId,
    String reason,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.put(
        Uri.parse('$_baseUrl/contracts/$contractId/dispute'),
        headers: _headers(t),
        body: jsonEncode({'reason': reason}),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('PUT /contracts/$contractId/dispute status: ${res.statusCode}');
    if (res.statusCode == 200) {
      return ContractModel.fromJson(body['details'] ?? body['data'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to raise dispute');
  }

  Future<ContractModel> cancelContract(
    String token,
    String contractId, {
    String? reason,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.put(
        Uri.parse('$_baseUrl/contracts/$contractId/cancel'),
        headers: {
          'Authorization': 'Bearer $t',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        }),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);

    if (res.statusCode == 200) {
      final raw = body['details'] ?? body['data'] ?? body;
      return ContractModel.fromJson(raw as Map<String, dynamic>);
    }

    throw Exception(
      body['details'] ?? body['message'] ?? 'Failed to cancel contract',
    );
  }
}
