import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CvAnalysisService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Future<Map<String, dynamic>> analyzeCV(String token, File cvFile) async {
    final uri = Uri.parse('$_baseUrl/cv_analysis/analyze');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('cv_file', cvFile.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(response.body);

    debugPrint('POST /cv_analysis/analyze status=${response.statusCode} body=$body');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return (body['details'] ?? body['data'] ?? body) as Map<String, dynamic>;
    }

    throw Exception(body['details'] ?? body['message'] ?? body['detail'] ?? 'CV analysis failed');
  }
}
