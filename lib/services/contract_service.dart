import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/contract_model.dart';

class ContractService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── GET /contracts ────────────────────────────────────────────────────────

  /// GET /contracts
  Future<List<ContractModel>> getAllContracts(String token) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/contracts'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts → ${res.statusCode}');
    if (res.statusCode == 200) {
      final list = body['data'] ?? body['details'] ?? [];
      return (list as List)
          .map((e) => ContractModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to load contracts');
  }

  /// GET /contracts/client/:clientId
  Future<List<ContractModel>> getContractsByClient(
    String token,
    String clientId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/contracts/client/$clientId'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts/client/$clientId → ${res.statusCode}');
    if (res.statusCode == 200) {
      final list = body['data'] ?? body['details'] ?? [];
      return (list as List)
          .map((e) => ContractModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to load contracts');
  }

  /// GET /contracts/freelancer/:freelancerId
  Future<List<ContractModel>> getContractsByFreelancer(
    String token,
    String freelancerId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/contracts/freelancer/$freelancerId'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts/freelancer/$freelancerId → ${res.statusCode}');
    if (res.statusCode == 200) {
      final list = body['data'] ?? body['details'] ?? [];
      return (list as List)
          .map((e) => ContractModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to load contracts');
  }

  /// GET /contracts/:contractId
  Future<ContractModel> getContractById(String token, String contractId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/contracts/$contractId'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts/$contractId → ${res.statusCode}');
    if (res.statusCode == 200) {
      return ContractModel.fromJson(body['data'] ?? body['details'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to load contract');
  }

  /// GET /contracts/:contractId/generation-data
  Future<Map<String, dynamic>> getContractGenerationData(
    String token,
    String contractId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/contracts/$contractId/generation-data'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts/$contractId/generation-data → ${res.statusCode}');
    if (res.statusCode == 200) {
      return body['data'] ?? body['details'] ?? {};
    }
    throw Exception(body['details'] ?? 'Failed to load generation data');
  }

  /// GET /contracts/:contractId/pdf-url
  Future<String> getContractPdfUrl(String token, String contractId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/contracts/$contractId/pdf-url'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts/$contractId/pdf-url → ${res.statusCode}');
    if (res.statusCode == 200) {
      final data = (body['details'] ?? body['data']) as Map<String, dynamic>?;
      final pdfUrl = data?['pdf_url'] as String? ?? data?['contract_pdf_url'] as String?;
      if (pdfUrl == null || pdfUrl.isEmpty) {
        throw Exception('PDF URL not found');
      }
      return pdfUrl;
    }
    throw Exception(body['details'] ?? 'Failed to get PDF URL');
  }

  // ── POST /contracts ───────────────────────────────────────────────────────

  /// POST /contracts - Create a new contract
  Future<ContractModel> createContract(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/contracts'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final body = jsonDecode(res.body);
    debugPrint('POST /contracts → ${res.statusCode}');
    if (res.statusCode == 201) {
      return ContractModel.fromJson(body['data'] ?? body['details'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to create contract');
  }

  /// POST /contracts/:contractId/generate - Generate PDF
  Future<ContractModel> generateContractPdf(
    String token,
    String contractId,
    Map<String, dynamic> generationData,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/contracts/$contractId/generate'),
      headers: _headers(token),
      body: jsonEncode(generationData),
    );
    final body = jsonDecode(res.body);
    debugPrint('POST /contracts/$contractId/generate → ${res.statusCode}');
    if (res.statusCode == 200) {
      return ContractModel.fromJson(body['data'] ?? body['details'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to generate contract');
  }

  // ── PUT /contracts/:contractId ────────────────────────────────────────────

  /// PUT /contracts/:contractId - Update contract status
  Future<ContractModel> updateContract(
    String token,
    String contractId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/contracts/$contractId'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final body = jsonDecode(res.body);
    debugPrint('PUT /contracts/$contractId → ${res.statusCode}');
    if (res.statusCode == 200) {
      return ContractModel.fromJson(body['data'] ?? body['details'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to update contract');
  }
}
