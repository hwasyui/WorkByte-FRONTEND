import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  // local
  // static const String _baseUrl = 'http://10.0.2.2:8000';

  /// Helper method to extract items from response
  /// Supports both new format (details.items) and old format (details/data as list)
  static List<Map<String, dynamic>> _extractItems(Map<String, dynamic> data) {
    try {
      final details = data['details'];
      
      // New pagination format: details.items
      if (details is Map && details['items'] != null) {
        return List<Map<String, dynamic>>.from(details['items'] as List);
      }
      
      // Old format: details as list
      if (details is List) {
        return List<Map<String, dynamic>>.from(details);
      }
      
      // Fallback: data field
      final dataField = data['data'];
      if (dataField is List) {
        return List<Map<String, dynamic>>.from(dataField);
      }
      
      return [];
    } catch (e) {
      print('Error extracting items from response: $e');
      return [];
    }
  }

  /// Helper method to extract pagination info from response
  static Map<String, dynamic>? _extractPaginationInfo(Map<String, dynamic> data) {
    try {
      final details = data['details'];
      if (details is Map && details['pagination'] != null) {
        return Map<String, dynamic>.from(details['pagination']);
      }
      return null;
    } catch (e) {
      print('Error extracting pagination info: $e');
      return null;
    }
  }

  // Education API
  static Future<bool> createEducation(
    String token,
    Map<String, dynamic> educationData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/educations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(educationData),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Failed to create education: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error creating education: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getEducations(
    String token,
    String freelancerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/educations/freelancer/$freelancerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final details = data['details'] ?? data['data'] ?? [];
        return List<Map<String, dynamic>>.from(details);
      } else {
        print('Failed to get educations: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting educations: $e');
      return [];
    }
  }

  static Future<bool> deleteEducation(String token, String educationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/educations/$educationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to delete education: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting education: $e');
      return false;
    }
  }

  // Freelancer Skills API
  static Future<bool> createFreelancerSkill(
    String token,
    Map<String, dynamic> skillData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/freelancer-skills'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(skillData),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Failed to create freelancer skill: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error creating freelancer skill: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getFreelancerSkills(
    String token,
    String freelancerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/freelancers/$freelancerId/skills',
        ), // ✅ dedicated endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final skills = data['details'] ?? data['data'] ?? [];
        return List<Map<String, dynamic>>.from(skills);
      } else {
        print('Failed to get freelancer skills: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting freelancer skills: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getSkills(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/skills'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final details = data['details'] ?? data['data'] ?? [];
        return List<Map<String, dynamic>>.from(details);
      } else {
        print('Failed to get skills: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting skills: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchSkills(
    String token,
    String searchTerm,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/skills/search/$searchTerm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final details = data['details'] ?? data['data'] ?? {};
        if (details is Map) {
          final results = details['results'] ?? [];
          return List<Map<String, dynamic>>.from(results);
        }
        return List<Map<String, dynamic>>.from(details);
      } else {
        print('Failed to search skills: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error searching skills: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createSkill(
    String token,
    Map<String, dynamic> skillData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/skills'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(skillData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data['details'] ?? {});
      } else {
        print('Failed to create skill: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating skill: $e');
      return null;
    }
  }

  static Future<bool> deleteFreelancerSkill(
    String token,
    String freelancerSkillId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/freelancer-skills/$freelancerSkillId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to delete freelancer skill: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting freelancer skill: $e');
      return false;
    }
  }

  static Future<bool> createWorkExperience(
    String token,
    Map<String, dynamic> experienceData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/work-experiences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(experienceData),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Failed to create work experience: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error creating work experience: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getWorkExperiences(
    String token,
    String freelancerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/work-experiences/freelancer/$freelancerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final details = data['details'] ?? data['data'] ?? [];
        return List<Map<String, dynamic>>.from(details);
      } else {
        print('Failed to get work experiences: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting work experiences: $e');
      return [];
    }
  }

  static Future<bool> deleteWorkExperience(
    String token,
    String workExperienceId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/work-experiences/$workExperienceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to delete work experience: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting work experience: $e');
      return false;
    }
  }

  static Future<String?> uploadProfilePicture(
    String token,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        print('File not found: $filePath');
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload/profile-picture'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Extract the URL from the response
        final url =
            data['url'] ?? data['file_url'] ?? data['profile_picture_url'];
        if (url != null) {
          print('Profile picture uploaded successfully: $url');
          return url as String;
        }
      } else {
        print('Failed to upload profile picture: $responseBody');
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
    }
    return null;
  }

  // Job Posts API
  static Future<List<Map<String, dynamic>>> getClientPostedJobs(String token, String clientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/job-posts/client/$clientId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final details = data['details'] ?? data['data'] ?? [];
        return List<Map<String, dynamic>>.from(details);
      } else {
        print('Failed to get client posted jobs: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting client posted jobs: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getJobPostById(String token, String jobPostId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/job-posts/$jobPostId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final details = data['details'] ?? data['data'] ?? {};
        return Map<String, dynamic>.from(details);
      } else {
        print('Failed to get job post: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting job post: $e');
      return null;
    }
  }

  // Client Profile Upload
  static Future<Map<String, dynamic>?> uploadClientProfilePicture(
      String token, String clientId, String imagePath) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        print('File does not exist: $imagePath');
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/clients/$clientId/upload-profile-picture'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile(
          'file',
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: imagePath.split('/').last,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final details = data['details'] ?? data['data'] ?? {};
        return Map<String, dynamic>.from(details);
      } else {
        print('Failed to upload profile picture: $responseBody');
        return null;
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  // Job Posts API
  /// Get all job posts with pagination support
  /// Returns list of job posts
  static Future<List<Map<String, dynamic>>> getAllJobPosts(
    String token, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/job-posts').replace(queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _extractItems(data);
      } else {
        print('Failed to get job posts: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting job posts: $e');
      return [];
    }
  }

  /// Get all job posts with pagination info
  /// Returns map with 'items' and 'pagination' keys
  static Future<Map<String, dynamic>> getAllJobPostsWithPagination(
    String token, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/job-posts').replace(queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'items': _extractItems(data),
          'pagination': _extractPaginationInfo(data) ?? {
            'page': page,
            'page_size': pageSize,
            'total': 0,
            'total_pages': 0,
          },
        };
      } else {
        print('Failed to get job posts: ${response.body}');
        return {'items': [], 'pagination': {}};
      }
    } catch (e) {
      print('Error getting job posts: $e');
      return {'items': [], 'pagination': {}};
    }
  }

  /// Get all freelancers with pagination support
  /// Returns list of freelancers
  static Future<List<Map<String, dynamic>>> getAllFreelancers(
    String token, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/freelancers/browse/all').replace(queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _extractItems(data);
      } else {
        print('Failed to get freelancers: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting freelancers: $e');
      return [];
    }
  }

  /// Get all freelancers with pagination info
  /// Returns map with 'items' and 'pagination' keys
  static Future<Map<String, dynamic>> getAllFreelancersWithPagination(
    String token, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/freelancers/browse/all').replace(queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'items': _extractItems(data),
          'pagination': _extractPaginationInfo(data) ?? {
            'page': page,
            'page_size': pageSize,
            'total': 0,
            'total_pages': 0,
          },
        };
      } else {
        print('Failed to get freelancers: ${response.body}');
        return {'items': [], 'pagination': {}};
      }
    } catch (e) {
      print('Error getting freelancers: $e');
      return {'items': [], 'pagination': {}};
    }
  }

  static Future<Map<String, dynamic>?> analyzeJobMatch(
    String token,
    String jobPostId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ai/job_matching/analyse/job/$jobPostId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data['details'] ?? data['data'] ?? {});
      } else {
        print('AI analysis failed (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling AI analysis: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getAIJobRecommendations(
    String token, {
    int limit = 10,
    String? experienceLevel,
  }) async {
    try {
      final queryParams = <String, String>{'limit': limit.toString()};
      if (experienceLevel != null) queryParams['experience_level'] = experienceLevel;

      final uri = Uri.parse('$_baseUrl/ai/job_matching/match/freelancer-to-jobs')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final details = data['details'] ?? data['data'] ?? {};
        return Map<String, dynamic>.from(details);
      } else {
        print('AI recommendations failed: ${response.body}');
        return {};
      }
    } catch (e) {
      print('Error getting AI recommendations: $e');
      return {};
    }
  }

  /// Get all clients with pagination support
  /// Returns list of clients
  static Future<List<Map<String, dynamic>>> getAllClients(
    String token, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/clients/browse/all').replace(queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _extractItems(data);
      } else {
        print('Failed to get clients: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting clients: $e');
      return [];
    }
  }

  /// Get all clients with pagination info
  /// Returns map with 'items' and 'pagination' keys
  static Future<Map<String, dynamic>> getAllClientsWithPagination(
    String token, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/clients/browse/all').replace(queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'items': _extractItems(data),
          'pagination': _extractPaginationInfo(data) ?? {
            'page': page,
            'page_size': pageSize,
            'total': 0,
            'total_pages': 0,
          },
        };
      } else {
        print('Failed to get clients: ${response.body}');
        return {'items': [], 'pagination': {}};
      }
    } catch (e) {
      print('Error getting clients: $e');
      return {'items': [], 'pagination': {}};
    }
  }
}
