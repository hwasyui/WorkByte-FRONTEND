import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/job_post_model.dart';
import '../models/job_role_model.dart';
import '../models/job_role_skill_model.dart';
import '../models/job_file_model.dart';

/// Thrown when GET /job-posts/{id} returns 202 - the post exists but is still
/// being scanned for harmful content (moderation_status: 'scanning'). This is
/// distinct from a real failure (404/500): the post will very likely become
/// available within seconds, so callers should show a "still reviewing"
/// message rather than a generic error. See DOCS/test-frontend.md section 3.
class JobPostScanningException implements Exception {
  final String message;
  JobPostScanningException([this.message = 'This job post is still being reviewed. Check back shortly.']);
  @override
  String toString() => message;
}

class JobPostService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  dynamic _extractBody(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body['details'] ?? body['data'] ?? body;
    }
    return body;
  }

  String _extractError(dynamic body, String fallback) {
    if (body is Map<String, dynamic>) {
      final details = body['details'];
      if (details is String && details.isNotEmpty) return details;
      final message = body['message'];
      if (message is String && message.isNotEmpty) return message;
      final error = body['error'];
      if (error is String && error.isNotEmpty) return error;
    }
    return fallback;
  }

  Future<dynamic> _decodeResponse(http.Response res) async {
    if (res.body.isEmpty) return {};
    return jsonDecode(res.body);
  }

  // ─── Job Posts ────────────────────────────────────────────────────────────
  Future<List<JobPostModel>> getAllJobPosts(
    String token, {
    int page = 1,
    int pageSize = 20,
    String? category,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/job-posts').replace(
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
          if (category != null) 'category': category,
        },
      ),
      headers: _headers(token),
    );
    final body = await _decodeResponse(res);
    debugPrint('GET /job-posts: $body');
    if (res.statusCode == 200) {
      final details = body['details'];
      final list = (details is Map && details['items'] != null)
          ? details['items']
          : (details is List ? details : (body['data'] ?? []));
      return (list as List)
          .map((e) => JobPostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_extractError(body, 'Failed to load job posts'));
  }

  Future<Map<String, dynamic>> getAllJobPostsWithPagination(
    String token, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/job-posts').replace(
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      ),
      headers: _headers(token),
    );
    final body = await _decodeResponse(res);
    if (res.statusCode == 200) {
      final details = body['details'];
      final list = (details is Map && details['items'] != null)
          ? details['items']
          : (details is List ? details : (body['data'] ?? []));
      final items = (list as List)
          .map((e) => JobPostModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = (details is Map && details['pagination'] != null)
          ? details['pagination']
          : {'page': page, 'page_size': pageSize, 'total': 0, 'total_pages': 0};
      return {'items': items, 'pagination': pagination};
    }
    throw Exception(_extractError(body, 'Failed to load job posts'));
  }

  Future<JobPostModel> getJobPost(String token, String jobPostId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/job-posts/$jobPostId'),
      headers: _headers(token),
    );
    final body = await _decodeResponse(res);
    if (res.statusCode == 200) {
      return JobPostModel.fromJson(_extractBody(body));
    }
    if (res.statusCode == 202) {
      final message = (body is Map<String, dynamic>)
          ? body['message'] as String?
          : null;
      throw JobPostScanningException(
        message ?? 'This job post is still being reviewed. Check back shortly.',
      );
    }
    throw Exception(_extractError(body, 'Failed to load job post'));
  }

  Future<List<JobPostModel>> getJobPostsByClient(
    String token,
    String clientId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/job-posts/client/$clientId'),
      headers: _headers(token),
    );
    final body = await _decodeResponse(res);
    if (res.statusCode == 200) {
      final list = _extractBody(body) ?? [];
      return (list as List)
          .map((e) => JobPostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_extractError(body, 'Failed to load client job posts'));
  }

  Future<Map<String, int>> getCategoryCounts(String token) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/job-posts/category-counts'),
      headers: _headers(token),
    );
    final body = await _decodeResponse(res);
    if (res.statusCode == 200) {
      final list = _extractBody(body) ?? [];
      return {
        for (final item in list as List)
          (item['category'] as String): (item['count'] as num).toInt(),
      };
    }
    throw Exception(_extractError(body, 'Failed to fetch category counts'));
  }

  Future<JobPostModel> createJobPost(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/job-posts'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final body = await _decodeResponse(res);
    debugPrint('POST /job-posts request: $data');
    debugPrint('POST /job-posts response: $body');
    if (res.statusCode == 200 || res.statusCode == 201) {
      return JobPostModel.fromJson(_extractBody(body));
    }
    throw Exception(_extractError(body, 'Failed to create job post'));
  }

  Future<JobPostModel> updateJobPost(
    String token,
    String jobPostId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/job-posts/$jobPostId'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final body = await _decodeResponse(res);
    debugPrint('PUT /job-posts/$jobPostId request: $data');
    debugPrint('PUT /job-posts/$jobPostId response: $body');
    if (res.statusCode == 200) {
      return JobPostModel.fromJson(_extractBody(body));
    }
    throw Exception(_extractError(body, 'Failed to update job post'));
  }

  Future<void> deleteJobPost(String token, String jobPostId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/job-posts/$jobPostId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      final body = await _decodeResponse(res);
      throw Exception(_extractError(body, 'Failed to delete job post'));
    }
  }

  // ─── Job Roles ────────────────────────────────────────────────────────────
  Future<List<JobRoleModel>> getJobRoles(String token, String jobPostId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/job-roles/job-post/$jobPostId'),
      headers: _headers(token),
    );
    final body = await _decodeResponse(res);
    debugPrint('GET /job-roles/job-post/$jobPostId: $body');
    if (res.statusCode == 200) {
      final list = _extractBody(body) ?? [];
      return (list as List)
          .map((e) => JobRoleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_extractError(body, 'Failed to load job roles'));
  }

  Future<JobRoleModel> createJobRole(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/job-roles'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final body = await _decodeResponse(res);
    debugPrint('POST /job-roles request: $data');
    debugPrint('POST /job-roles response: $body');
    if (res.statusCode == 200 || res.statusCode == 201) {
      return JobRoleModel.fromJson(_extractBody(body));
    }
    throw Exception(_extractError(body, 'Failed to create job role'));
  }

  Future<JobRoleModel> updateJobRole(
    String token,
    String jobRoleId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/job-roles/$jobRoleId'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final body = await _decodeResponse(res);
    debugPrint('PUT /job-roles/$jobRoleId request: $data');
    debugPrint('PUT /job-roles/$jobRoleId response: $body');
    if (res.statusCode == 200) {
      return JobRoleModel.fromJson(_extractBody(body));
    }
    throw Exception(_extractError(body, 'Failed to update job role'));
  }

  Future<void> deleteJobRole(String token, String jobRoleId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/job-roles/$jobRoleId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      final body = await _decodeResponse(res);
      throw Exception(_extractError(body, 'Failed to delete job role'));
    }
  }

  // ─── Job Role Skills ──────────────────────────────────────────────────────
  Future<List<JobRoleSkillModel>> getJobRoleSkills(
    String token,
    String jobRoleId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/job-role-skills/job-role/$jobRoleId'),
      headers: _headers(token),
    );
    final body = await _decodeResponse(res);
    debugPrint('GET /job-role-skills/job-role/$jobRoleId: $body');
    if (res.statusCode == 200) {
      final list = _extractBody(body) ?? [];
      return (list as List)
          .map((e) => JobRoleSkillModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_extractError(body, 'Failed to load job role skills'));
  }

  Future<JobRoleSkillModel> createJobRoleSkill(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/job-role-skills'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final body = await _decodeResponse(res);
    debugPrint('POST /job-role-skills request: $data');
    debugPrint('POST /job-role-skills response: $body');
    if (res.statusCode == 200 || res.statusCode == 201) {
      return JobRoleSkillModel.fromJson(_extractBody(body));
    }
    throw Exception(_extractError(body, 'Failed to create job role skill'));
  }

  Future<JobRoleSkillModel> updateJobRoleSkill(
    String token,
    String jobRoleSkillId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/job-role-skills/$jobRoleSkillId'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final body = await _decodeResponse(res);
    debugPrint('PUT /job-role-skills/$jobRoleSkillId request: $data');
    debugPrint('PUT /job-role-skills/$jobRoleSkillId response: $body');
    if (res.statusCode == 200) {
      return JobRoleSkillModel.fromJson(_extractBody(body));
    }
    throw Exception(_extractError(body, 'Failed to update job role skill'));
  }

  Future<void> deleteJobRoleSkill(String token, String jobRoleSkillId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/job-role-skills/$jobRoleSkillId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      final body = await _decodeResponse(res);
      throw Exception(_extractError(body, 'Failed to delete job role skill'));
    }
  }

  // ─── Job Files ────────────────────────────────────────────────────────────
  Future<List<JobFileModel>> getJobFiles(String token, String jobPostId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/job-files/job-post/$jobPostId'),
      headers: _headers(token),
    );

    final body = await _decodeResponse(res);
    debugPrint('GET /job-files/job-post/$jobPostId: $body');

    if (res.statusCode == 200) {
      final list = _extractBody(body) ?? [];
      return (list as List)
          .map((e) => JobFileModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(_extractError(body, 'Failed to load job files'));
  }

  Future<List<JobFileModel>> uploadJobFiles({
    required String token,
    required String jobPostId,
    required List<File> files,
  }) async {
    final uri = Uri.parse('$_baseUrl/job-files');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['job_post_id'] = jobPostId;

    for (final file in files) {
      request.files.add(await http.MultipartFile.fromPath('files', file.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final body = response.body.isEmpty ? {} : jsonDecode(response.body);

    debugPrint('POST /job-files response: $body');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final list = _extractBody(body) ?? [];
      return (list as List)
          .map((e) => JobFileModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(_extractError(body, 'Failed to upload job files'));
  }

  Future<void> deleteJobFile(String token, String jobFileId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/job-files/$jobFileId'),
      headers: _headers(token),
    );

    if (res.statusCode != 200) {
      final body = await _decodeResponse(res);
      throw Exception(_extractError(body, 'Failed to delete job file'));
    }
  }

  // ─── Relevant & Popular feeds ──────────────────────────────────────────────
  Future<List<JobPostModel>> getRelevantJobs(
    String token, {
    int limit = 10,
    String? category,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (category != null) params['category'] = category;

    final res = await http.get(
      Uri.parse(
        '$_baseUrl/job-posts/relevant',
      ).replace(queryParameters: params),
      headers: _headers(token),
    );
    final body = await _decodeResponse(res);
    if (res.statusCode == 200) {
      final list = body['data'] ?? body['details'] ?? [];
      return (list as List)
          .map((e) => JobPostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_extractError(body, 'Failed to load relevant jobs'));
  }

  Future<List<JobPostModel>> getPopularJobs(
    String token, {
    int page = 1,
    int pageSize = 10,
    String? category,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (category != null) params['category'] = category;

    final res = await http.get(
      Uri.parse('$_baseUrl/job-posts/popular').replace(queryParameters: params),
      headers: _headers(token),
    );
    final body = await _decodeResponse(res);
    if (res.statusCode == 200) {
      final details = body['details'];
      final list = (details is Map && details['items'] != null)
          ? details['items']
          : (details is List ? details : (body['data'] ?? []));
      return (list as List)
          .map((e) => JobPostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_extractError(body, 'Failed to load popular jobs'));
  }
}
