import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static void _checkUnauthorized(http.Response response) {
    if (response.statusCode == 401) throw const SessionExpiredException();
  }
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
  static Map<String, dynamic>? _extractPaginationInfo(
    Map<String, dynamic> data,
  ) {
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

  // Job Posts API
  static Future<List<Map<String, dynamic>>> getClientPostedJobs(
    String token,
    String clientId,
  ) async {
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

  static Future<Map<String, dynamic>?> getJobPostById(
    String token,
    String jobPostId,
  ) async {
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

  // Job Posts API
  /// Get all job posts with pagination support
  /// Returns list of job posts
  static Future<List<Map<String, dynamic>>> getAllJobPosts(
    String token, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/job-posts').replace(
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

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
      final uri = Uri.parse('$_baseUrl/job-posts').replace(
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

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
          'pagination':
              _extractPaginationInfo(data) ??
              {
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
      final uri = Uri.parse('$_baseUrl/freelancers/browse/all').replace(
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
          'order_by': 'weighted_review_avg',
          'order_dir': 'desc',
        },
      );

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
      final uri = Uri.parse('$_baseUrl/freelancers/browse/all').replace(
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

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
          'pagination':
              _extractPaginationInfo(data) ??
              {
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
        Uri.parse('$_baseUrl/ai/job-engine/analyse/job/$jobPostId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      _checkUnauthorized(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data['details'] ?? data['data'] ?? {});
      } else {
        print('AI analysis failed (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling AI analysis: $e');
      rethrow;
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
      final uri = Uri.parse('$_baseUrl/clients/browse/all').replace(
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

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
      final uri = Uri.parse('$_baseUrl/clients/browse/all').replace(
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

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
          'pagination':
              _extractPaginationInfo(data) ??
              {
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
