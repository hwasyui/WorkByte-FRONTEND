import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../models/cv_suggested_profile.dart';

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

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(response.body);

    debugPrint(
      'POST /cv_analysis/analyze status=${response.statusCode} body=$body',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return (body['details'] ?? body['data'] ?? body) as Map<String, dynamic>;
    }

    throw Exception(
      body['details'] ??
          body['message'] ??
          body['detail'] ??
          'CV analysis failed',
    );
  }

  /// Upload CV via /cv_upload — returns the full response body.
  /// Check [is_initial] in the result to decide which screen to show next.
  Future<Map<String, dynamic>> uploadCV(String token, File cvFile) async {
    final uri = Uri.parse('$_baseUrl/cv_upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', cvFile.path));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(response.body);

    debugPrint('POST /cv_upload status=${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return (body['details'] ?? body['data'] ?? body) as Map<String, dynamic>;
    }

    throw Exception(
      body['details'] ??
          body['message'] ??
          body['detail'] ??
          'CV upload failed',
    );
  }

  /// Apply confirmed CV suggestions to the freelancer's profile.
  Future<Map<String, dynamic>> applyProfile({
    required String token,
    required CvSuggestedProfile profile,
    required bool applyBio,
    required bool applySkills,
    required bool applyWorkExperience,
    required bool applyEducation,
  }) async {
    final uri = Uri.parse('$_baseUrl/cv_upload/apply');
    final bodyMap = {
      'apply_bio': applyBio,
      'apply_skills': applySkills,
      'apply_work_experience': applyWorkExperience,
      'apply_education': applyEducation,
      'suggested_bio': profile.suggestedBio,
      'skills': profile.skills,
      'work_experience': profile.workExperience.map((e) => e.toJson()).toList(),
      'education': profile.education.map((e) => e.toJson()).toList(),
    };

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(bodyMap),
    ).timeout(const Duration(seconds: 20));

    debugPrint('POST /cv_upload/apply status=${response.statusCode}');

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return (decoded['details'] ?? decoded['data'] ?? decoded)
          as Map<String, dynamic>;
    }

    throw Exception(
      decoded['details'] ??
          decoded['message'] ??
          decoded['detail'] ??
          'Apply failed',
    );
  }
}
