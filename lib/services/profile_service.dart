import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/client_model.dart';
import '../models/freelancer_model.dart';
import '../models/education_model.dart';
import '../models/experience_model.dart';
import '../models/freelancer_skill_model.dart';

class ProfileService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, String> _multipartHeaders(String token) => {
    'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decodeBody(http.Response res) {
    final decoded = jsonDecode(res.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  // ─── Fetch profiles ───────────────────────────────────────────────────────

  Future<ClientModel?> fetchClientProfile(String token, String userId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/clients/$userId'),
      headers: _headers(token),
    );
    final body = _decodeBody(res);
    debugPrint('GET /clients/$userId: $body');

    if (res.statusCode == 200) {
      final data = body['details'] ?? body['data'] ?? body;
      return ClientModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception(
      body['message'] ?? body['detail'] ?? 'Failed to load client profile',
    );
  }

  Future<FreelancerModel?> fetchFreelancerProfile(
    String token,
    String userId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/freelancers/$userId'),
      headers: _headers(token),
    );
    final body = _decodeBody(res);
    debugPrint('GET /freelancers/$userId: $body');

    if (res.statusCode == 200) {
      final data = body['details'] ?? body['data'] ?? body;
      return FreelancerModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception(
      body['message'] ?? body['detail'] ?? 'Failed to load freelancer profile',
    );
  }

  Future<ClientModel?> fetchClientById(String token, String clientId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/clients/$clientId'),
        headers: _headers(token),
      );
      final body = _decodeBody(res);
      if (res.statusCode == 200) {
        final data = body['details'] ?? body['data'] ?? body;
        return ClientModel.fromJson(data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('fetchClientById error: $e');
    }
    return null;
  }

  Future<FreelancerModel?> fetchFreelancerById(
    String token,
    String freelancerId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/freelancers/$freelancerId'),
        headers: _headers(token),
      );
      final body = _decodeBody(res);
      if (res.statusCode == 200) {
        final data = body['details'] ?? body['data'] ?? body;
        return FreelancerModel.fromJson(data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('fetchFreelancerById error: $e');
    }
    return null;
  }

  // ─── Update profiles ──────────────────────────────────────────────────────

  Future<ClientModel> updateClientProfile(
    String token,
    String identifier,
    Map<String, dynamic> fields,
  ) async {
    final uri = Uri.parse('$_baseUrl/clients/$identifier');
    final request = http.MultipartRequest('PUT', uri)
      ..headers.addAll(_multipartHeaders(token));

    fields.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = _decodeBody(res);

    if (res.statusCode == 200) {
      final data = body['details'] ?? body['data'] ?? body;
      return ClientModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception(
      body['message'] ?? body['detail'] ?? 'Failed to update client profile',
    );
  }

  Future<FreelancerModel> updateFreelancerProfile(
    String token,
    String identifier,
    Map<String, dynamic> fields,
  ) async {
    final uri = Uri.parse('$_baseUrl/freelancers/$identifier');
    final request = http.MultipartRequest('PUT', uri)
      ..headers.addAll(_multipartHeaders(token));

    fields.forEach((key, value) {
      request.fields[key] = value?.toString() ?? '';
    });

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = _decodeBody(res);

    if (res.statusCode == 200) {
      final data = body['details'] ?? body['data'] ?? body;
      return FreelancerModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception(
      body['message'] ??
          body['detail'] ??
          'Failed to update freelancer profile',
    );
  }

  // ─── Profile picture ──────────────────────────────────────────────────────

  Future<ClientModel> uploadClientProfilePicture(
    String token,
    String clientId,
    File imageFile,
  ) async {
    final uri = Uri.parse('$_baseUrl/clients/$clientId/profile-picture');
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeType = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_multipartHeaders(token))
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = _decodeBody(res);

    if (res.statusCode == 200) {
      final data = body['details'] ?? body['data'] ?? body;
      return ClientModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception(
      body['details'] ?? body['message'] ?? 'Failed to upload profile picture',
    );
  }

  Future<FreelancerModel> uploadFreelancerProfilePicture(
    String token,
    String freelancerId,
    File imageFile,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/freelancers/$freelancerId/profile-picture',
    );
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeType = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_multipartHeaders(token))
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = _decodeBody(res);

    if (res.statusCode == 200) {
      final data = body['details'] ?? body['data'] ?? body;
      return FreelancerModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception(
      body['details'] ?? body['message'] ?? 'Failed to upload profile picture',
    );
  }

  Future<ClientModel> deleteClientProfilePicture(
    String token,
    String clientId,
  ) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/clients/$clientId/profile-picture'),
      headers: _headers(token),
    );
    final body = _decodeBody(res);
    if (res.statusCode == 200) {
      final data = body['details'] ?? body['data'] ?? body;
      final clientData = data is Map && data['client'] != null
          ? data['client']
          : data;
      return ClientModel.fromJson(clientData as Map<String, dynamic>);
    }
    throw Exception(
      body['details'] ?? body['message'] ?? 'Failed to delete profile picture',
    );
  }

  Future<FreelancerModel> deleteFreelancerProfilePicture(
    String token,
    String freelancerId,
  ) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/freelancers/$freelancerId/profile-picture'),
      headers: _headers(token),
    );
    final body = _decodeBody(res);
    if (res.statusCode == 200) {
      final data = body['details'] ?? body['data'] ?? body;
      final freelancerData = data is Map && data['freelancer'] != null
          ? data['freelancer']
          : data;
      return FreelancerModel.fromJson(freelancerData as Map<String, dynamic>);
    }
    throw Exception(
      body['details'] ?? body['message'] ?? 'Failed to delete profile picture',
    );
  }

  // ─── Education ────────────────────────────────────────────────────────────

  Future<List<EducationModel>> getEducations(
    String token,
    String freelancerId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/educations/freelancer/$freelancerId'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final body = _decodeBody(res);
        final data = body['details'] ?? body['data'] ?? [];
        return (data as List)
            .map((e) => EducationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('getEducations error: $e');
    }
    return [];
  }

  Future<bool> createEducation(String token, Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/educations'),
        headers: _headers(token),
        body: jsonEncode(data),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('createEducation error: $e');
      return false;
    }
  }

  Future<bool> deleteEducation(String token, String educationId) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/educations/$educationId'),
        headers: _headers(token),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('deleteEducation error: $e');
      return false;
    }
  }

  // ─── Work experience ──────────────────────────────────────────────────────

  Future<List<ExperienceModel>> getWorkExperiences(
    String token,
    String freelancerId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/work-experiences/freelancer/$freelancerId'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final body = _decodeBody(res);
        final data = body['details'] ?? body['data'] ?? [];
        return (data as List)
            .map((e) => ExperienceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('getWorkExperiences error: $e');
    }
    return [];
  }

  Future<bool> createWorkExperience(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/work-experiences'),
        headers: _headers(token),
        body: jsonEncode(data),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('createWorkExperience error: $e');
      return false;
    }
  }

  Future<bool> deleteWorkExperience(
    String token,
    String workExperienceId,
  ) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/work-experiences/$workExperienceId'),
        headers: _headers(token),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('deleteWorkExperience error: $e');
      return false;
    }
  }

  // ─── Skills ───────────────────────────────────────────────────────────────

  Future<List<FreelancerSkillModel>> getFreelancerSkills(
    String token,
    String freelancerId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/freelancers/$freelancerId/skills'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final body = _decodeBody(res);
        final data = body['details'] ?? body['data'] ?? [];
        return (data as List)
            .map(
              (e) => FreelancerSkillModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('getFreelancerSkills error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getAllSkills(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/skills'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final body = _decodeBody(res);
        final data = body['details'] ?? body['data'] ?? [];
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('getAllSkills error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> searchSkills(
    String token,
    String searchTerm,
  ) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/skills/search',
      ).replace(queryParameters: {'q': searchTerm});
      final res = await http.get(uri, headers: _headers(token));
      if (res.statusCode == 200) {
        final body = _decodeBody(res);
        final details = body['details'] ?? body['data'] ?? {};
        if (details is Map) {
          return List<Map<String, dynamic>>.from(details['results'] ?? []);
        }
        return List<Map<String, dynamic>>.from(details);
      }
    } catch (e) {
      debugPrint('searchSkills error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> createSkill(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/skills'),
        headers: _headers(token),
        body: jsonEncode(data),
      );
      if (res.statusCode == 201) {
        final body = _decodeBody(res);
        return Map<String, dynamic>.from(body['details'] ?? {});
      }
    } catch (e) {
      debugPrint('createSkill error: $e');
    }
    return null;
  }

  Future<bool> addFreelancerSkill(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/freelancer-skills'),
        headers: _headers(token),
        body: jsonEncode(data),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('addFreelancerSkill error: $e');
      return false;
    }
  }

  Future<bool> deleteFreelancerSkill(
    String token,
    String freelancerSkillId,
  ) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/freelancer-skills/$freelancerSkillId'),
        headers: _headers(token),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('deleteFreelancerSkill error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> uploadCV({
    required String token,
    required File file,
  }) async {
    final uri = Uri.parse('$_baseUrl/cv_upload');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: file.path.split('/').last,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(
      body['message'] ??
          body['detail'] ??
          body['error'] ??
          'Failed to upload CV',
    );
  }
}
