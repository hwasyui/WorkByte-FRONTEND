import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/contract_submission_model.dart';

class ContractSubmissionService {
  final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _jsonHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  String _guessMime(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const map = {
      'pdf': 'application/pdf',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'zip': 'application/zip',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  String _extractErrorMessage(
    http.Response res, {
    String fallback = 'Request failed',
  }) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final details = decoded['details'];
        if (details is String && details.trim().isNotEmpty) {
          return details;
        }
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
        final error = decoded['error'];
        if (error is String && error.trim().isNotEmpty) {
          return error;
        }
      }
    } catch (_) {}
    return fallback;
  }

  List<ContractSubmissionModel> _parseSubmissionList(String body) {
    final decoded = jsonDecode(body);

    final rawList = decoded is Map<String, dynamic>
        ? (decoded['details'] ?? decoded['data'] ?? decoded['result'] ?? [])
        : decoded;

    if (rawList is! List) return [];

    return rawList
        .map((e) => ContractSubmissionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  ContractSubmissionModel _parseSingleSubmission(String body) {
    final decoded = jsonDecode(body);

    final raw = decoded is Map<String, dynamic>
        ? (decoded['details'] ??
              decoded['data'] ??
              decoded['result'] ??
              decoded)
        : decoded;

    return ContractSubmissionModel.fromJson(raw as Map<String, dynamic>);
  }

  Future<List<ContractSubmissionModel>> getSubmissionsByContract(
    String token,
    String contractId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/contract-submissions/contract/$contractId'),
      headers: _jsonHeaders(token),
    );

    if (res.statusCode == 200) {
      return _parseSubmissionList(res.body);
    }

    throw Exception(
      _extractErrorMessage(
        res,
        fallback: 'Failed to fetch contract submissions',
      ),
    );
  }

  Future<ContractSubmissionModel> createSubmission({
    required String token,
    required String contractId,
    required List<File> files,
    String? note,
  }) async {
    final uri = Uri.parse('$_baseUrl/contract-submissions');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['contract_id'] = contractId;

    if (note != null && note.trim().isNotEmpty) {
      request.fields['note'] = note.trim();
    }

    for (final file in files) {
      final fileName = file.path.split('/').last;
      request.files.add(
        await http.MultipartFile.fromPath(
          'files',
          file.path,
          filename: fileName,
          contentType: MediaType.parse(_guessMime(fileName)),
        ),
      );
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return _parseSingleSubmission(res.body);
    }

    throw Exception(
      _extractErrorMessage(
        res,
        fallback: 'Failed to create contract submission',
      ),
    );
  }

  Future<ContractSubmissionModel> requestRevisionForLatestSubmission({
    required String token,
    required String contractId,
    String? note,
  }) async {
    final res = await http.put(
      Uri.parse(
        '$_baseUrl/contract-submissions/contract/$contractId/request-revision',
      ),
      headers: _jsonHeaders(token),
      body: jsonEncode({'note': note}), // ← add this
    );

    if (res.statusCode == 200) {
      return _parseSingleSubmission(res.body);
    }

    throw Exception(
      _extractErrorMessage(
        res,
        fallback: 'Failed to request revision for latest submission',
      ),
    );
  }

  Future<ContractSubmissionModel> approveLatestSubmission({
    required String token,
    required String contractId,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/contract-submissions/contract/$contractId/approve'),
      headers: _jsonHeaders(token),
    );

    if (res.statusCode == 200) {
      return _parseSingleSubmission(res.body);
    }

    throw Exception(
      _extractErrorMessage(
        res,
        fallback: 'Failed to approve latest submission',
      ),
    );
  }
}
