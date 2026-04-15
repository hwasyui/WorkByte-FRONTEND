import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/job_post_model.dart';
import '../models/job_role_model.dart';

class JobPostService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ─── Job Posts ────────────────────────────────────────────────────────────
  Future<List<JobPostModel>> getAllJobPosts(String token) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/job-posts'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /job-posts: $body');
    if (res.statusCode == 200) {
      final list = body['details'] ?? body['data'] ?? [];
      return (list as List)
          .map((e) => JobPostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to load job posts');
  }

  Future<JobPostModel> getJobPost(String token, String jobPostId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/job-posts/$jobPostId'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return JobPostModel.fromJson(body['details'] ?? body['data'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to load job post');
  }

  Future<List<JobPostModel>> getJobPostsByClient(
    String token,
    String clientId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/job-posts/client/$clientId'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      final list = body['details'] ?? body['data'] ?? [];
      return (list as List)
          .map((e) => JobPostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to load client job posts');
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
    final body = jsonDecode(res.body);
    debugPrint('POST /job-posts response: $body');
    if (res.statusCode == 200 || res.statusCode == 201) {
      return JobPostModel.fromJson(body['details'] ?? body['data'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to create job post');
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
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return JobPostModel.fromJson(body['details'] ?? body['data'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to update job post');
  }

  Future<void> deleteJobPost(String token, String jobPostId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/job-posts/$jobPostId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['details'] ?? 'Failed to delete job post');
    }
  }

  // ─── Job Roles ────────────────────────────────────────────────────────────
  Future<List<JobRoleModel>> getJobRoles(String token, String jobPostId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/job-roles/job-post/$jobPostId'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      final list = body['details'] ?? body['data'] ?? [];
      return (list as List)
          .map((e) => JobRoleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to load job roles');
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
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return JobRoleModel.fromJson(body['details'] ?? body['data'] ?? body);
    }
    throw Exception(body['details'] ?? 'Failed to create job role');
  }

  Future<void> deleteJobRole(String token, String jobRoleId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/job-roles/$jobRoleId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['details'] ?? 'Failed to delete job role');
    }
  }
}
