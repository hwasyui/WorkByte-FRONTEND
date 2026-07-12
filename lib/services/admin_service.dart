import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AdminService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const String _tokenKey = 'admin_token';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getSavedToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<bool> verifyAdminToken(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: _headers(token),
      );
      if (res.statusCode != 200) return false;
      final body = jsonDecode(res.body);
      final data = body['details'] ?? body['data'] ?? body;
      return data['is_admin'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<String> login(String email, String password) async {
    final loginRes = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    final loginBody = jsonDecode(loginRes.body);
    if (loginRes.statusCode != 200 && loginRes.statusCode != 201) {
      throw Exception(
        loginBody['details'] ??
            loginBody['message'] ??
            loginBody['detail'] ??
            'Login failed',
      );
    }

    final inner = loginBody['details'] ?? loginBody['data'] ?? loginBody;
    final token = inner['access_token'] as String?;
    if (token == null) throw Exception('Login failed');

    // Double-check is_admin flag from the backend as a second layer of security
    final meRes = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: _headers(token),
    );
    if (meRes.statusCode != 200) throw Exception('Failed to verify account');

    final meBody = jsonDecode(meRes.body);
    final meData = meBody['details'] ?? meBody['data'] ?? meBody;
    final isAdmin = meData['is_admin'] as bool? ?? false;
    if (!isAdmin)
      throw Exception(
        'Access denied. This account does not have admin privileges.',
      );

    return token;
  }

  static Future<Map<String, dynamic>> getFreelancers(
    String token, {
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final uri = Uri.parse('$_baseUrl/freelancers/browse/all').replace(
      queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final response = await http.get(uri, headers: _headers(token));
    if (response.statusCode == 200) {
      return _extract(jsonDecode(response.body) as Map<String, dynamic>);
    }
    return {'items': [], 'pagination': {}};
  }

  static Future<Map<String, dynamic>> getClients(
    String token, {
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final uri = Uri.parse('$_baseUrl/clients/browse/all').replace(
      queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final response = await http.get(uri, headers: _headers(token));
    if (response.statusCode == 200) {
      return _extract(jsonDecode(response.body) as Map<String, dynamic>);
    }
    return {'items': [], 'pagination': {}};
  }

  static Future<Map<String, dynamic>> getJobPosts(
    String token, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/job-posts').replace(
      queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      },
    );
    final response = await http.get(uri, headers: _headers(token));
    if (response.statusCode == 200) {
      return _extract(jsonDecode(response.body) as Map<String, dynamic>);
    }
    return {'items': [], 'pagination': {}};
  }

  static Future<Map<String, dynamic>> getAdminJobs(
    String token, {
    String? status,
    String? closureReason,
    String? projectType,
    String? projectScope,
    String? experienceLevel,
    String? projectCategory,
    bool? isAiGenerated,
    String? clientId,
    String? search,
    String sortBy = 'created_at',
    String sortDir = 'desc',
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, String>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (closureReason != null && closureReason.isNotEmpty)
        'closure_reason': closureReason,
      if (projectType != null && projectType.isNotEmpty)
        'project_type': projectType,
      if (projectScope != null && projectScope.isNotEmpty)
        'project_scope': projectScope,
      if (experienceLevel != null && experienceLevel.isNotEmpty)
        'experience_level': experienceLevel,
      if (projectCategory != null && projectCategory.isNotEmpty)
        'project_category': projectCategory,
      if (isAiGenerated != null) 'is_ai_generated': isAiGenerated.toString(),
      if (clientId != null && clientId.isNotEmpty) 'client_id': clientId,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      'sort_by': sortBy,
      'sort_dir': sortDir,
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    final uri = Uri.parse(
      '$_baseUrl/admin/jobs',
    ).replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers(token));
    if (response.statusCode == 200) {
      return _extract(jsonDecode(response.body) as Map<String, dynamic>);
    }
    return {'items': [], 'pagination': {}};
  }

  static Future<Map<String, dynamic>> getAdminUsers(
    String token, {
    String? role,
    bool? isBanned,
    bool? emailVerified,
    String? banReason,
    String? search,
    String sortBy = 'created_at',
    String sortDir = 'desc',
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, String>{
      if (role != null && role.isNotEmpty) 'role': role,
      if (isBanned != null) 'is_banned': isBanned.toString(),
      if (emailVerified != null) 'email_verified': emailVerified.toString(),
      if (banReason != null && banReason.isNotEmpty) 'ban_reason': banReason,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      'sort_by': sortBy,
      'sort_dir': sortDir,
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    final uri = Uri.parse(
      '$_baseUrl/admin/users',
    ).replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers(token));
    if (response.statusCode == 200) {
      return _extract(jsonDecode(response.body) as Map<String, dynamic>);
    }
    return {'items': [], 'pagination': {}};
  }

  static Future<Map<String, dynamic>> getDashboardStats(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/admin/dashboard'),
        headers: _headers(token),
      );
      if (res.statusCode != 200) return {};
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final details = body['details'] ?? body['data'] ?? body;
      return details is Map ? Map<String, dynamic>.from(details) : {};
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> getReports(
    String token, {
    String status = 'all',
    String reportedType = 'all',
    int page = 1,
    int pageSize = 50,
  }) async {
    final uri = Uri.parse('$_baseUrl/admin/reports').replace(
      queryParameters: {
        'status': status,
        'reported_type': reportedType,
        'page': page.toString(),
        'page_size': pageSize.toString(),
      },
    );
    final response = await http.get(uri, headers: _headers(token));
    if (response.statusCode == 200) {
      return _extract(jsonDecode(response.body) as Map<String, dynamic>);
    }
    return {'items': [], 'pagination': {}};
  }

  static Future<bool> actionReport(
    String token, {
    required String reportId,
    required String action,
    String? adminNote,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/admin/reports/$reportId/$action'),
        headers: _headers(token),
        body: jsonEncode({'admin_note': adminNote}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getScamFlags(
    String token, {
    String status = 'pending',
    String sortBy = 'scam_score',
    String sortDir = 'desc',
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/admin/scam-flags').replace(
        queryParameters: {
          'status': status,
          'sort_by': sortBy,
          'sort_dir': sortDir,
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      final res = await http.get(uri, headers: _headers(token));
      if (res.statusCode == 200) {
        return _extract(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return {'items': [], 'pagination': {}};
  }

  static Future<bool> actionScamFlag(
    String token, {
    required String flagId,
    required String action,
    String? adminNote,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/admin/scam-flags/$flagId/$action'),
        headers: _headers(token),
        body: jsonEncode({'admin_note': adminNote}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Browse the harmful-text audit trail (read-only history, not an action queue).
  /// [reviewed] filters by whether an admin has looked at a row yet: null = no
  /// filter, false = only unreviewed, true = only reviewed. [minScore]/[maxScore]
  /// filter on total_score (sum of the 5 label scores, 0-5) - a "high severity"
  /// quick filter is just minScore on its own. [userId] narrows to one flagged
  /// user - the drill-down from [getModerationItemsByUser]'s grouped view.
  static Future<Map<String, dynamic>> getModerationItems(
    String token, {
    bool? reviewed,
    String contentType = 'all',
    double? minScore,
    double? maxScore,
    String? userId,
    String sortBy = 'created_at',
    String sortDir = 'desc',
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/admin/moderation').replace(
        queryParameters: {
          if (reviewed != null) 'reviewed': reviewed.toString(),
          'content_type': contentType,
          if (minScore != null) 'min_score': minScore.toString(),
          if (maxScore != null) 'max_score': maxScore.toString(),
          if (userId != null) 'user_id': userId,
          'sort_by': sortBy,
          'sort_dir': sortDir,
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      final res = await http.get(uri, headers: _headers(token));
      if (res.statusCode == 200) {
        return _extract(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return {'items': [], 'pagination': {}};
  }

  /// Same audit trail as [getModerationItems], grouped by user (one row per
  /// flagged user_id/email with flagged_count/unreviewed_count/max_score/
  /// last_flagged_at) so repeat offenders are easy to spot.
  static Future<Map<String, dynamic>> getModerationItemsByUser(
    String token, {
    String contentType = 'all',
    String sortBy = 'flagged_count',
    String sortDir = 'desc',
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/admin/moderation/by-user').replace(
        queryParameters: {
          'content_type': contentType,
          'sort_by': sortBy,
          'sort_dir': sortDir,
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      final res = await http.get(uri, headers: _headers(token));
      if (res.statusCode == 200) {
        return _extract(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return {'items': [], 'pagination': {}};
  }

  /// Mark an audit-trail entry as reviewed (bookkeeping only, no action on the
  /// underlying content). Optional [adminNote] is stored alongside the row.
  static Future<bool> reviewModerationItem(
    String token, {
    required String moderationId,
    String? adminNote,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/admin/moderation/$moderationId/review'),
        headers: _headers(token),
        body: jsonEncode({'admin_note': adminNote}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Mark every currently-unreviewed row matching [contentType]/[minScore] as
  /// reviewed in one call - the "mark all reviewed" button for whatever
  /// filtered view is on screen. Bookkeeping only, same as the single-item
  /// endpoint. Returns the number of rows marked, or null on failure.
  static Future<int?> bulkReviewModerationItems(
    String token, {
    String contentType = 'all',
    double? minScore,
    String? adminNote,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/admin/moderation/review-all').replace(
        queryParameters: {
          'content_type': contentType,
          if (minScore != null) 'min_score': minScore.toString(),
        },
      );
      final res = await http.post(
        uri,
        headers: _headers(token),
        body: jsonEncode({'admin_note': adminNote}),
      );
      if (res.statusCode == 200) {
        // Not _extract() - that helper only pulls out items/pagination and
        // would silently drop reviewed_count, since {"reviewed_count": N} has
        // none of the keys it looks for.
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final details = decoded['details'] ?? decoded['data'] ?? decoded;
        if (details is Map) {
          return (details['reviewed_count'] as num?)?.toInt() ?? 0;
        }
        return 0;
      }
    } catch (_) {}
    return null;
  }

  /// Run the harmful-text model directly against arbitrary text (admin
  /// scratch-pad, e.g. to test whether a phrase would be flagged). Doesn't
  /// write anything anywhere - POST /harmful-text/detect is a pure utility
  /// call over the model, not tied to any content row. Returns
  /// `{"is_harmful": bool, "labels": [...], "scores": {...}}` or
  /// `{"error": "..."}` on failure.
  static Future<Map<String, dynamic>?> detectHarmfulText(
    String token,
    String text,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/harmful-text/detect'),
        headers: _headers(token),
        body: jsonEncode({'text': text}),
      );
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final details = decoded['details'] ?? decoded['data'] ?? decoded;
        return details is Map ? Map<String, dynamic>.from(details) : null;
      }
      return {'error': decoded['detail']?.toString() ?? decoded['details']?.toString() ?? 'Scan failed'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<bool> closeJob(
    String token,
    String jobPostId, {
    String? reason,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/admin/jobs/$jobPostId/close'),
        headers: _headers(token),
        body: jsonEncode({'reason': reason}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getFreelancerFullProfile(
    String token,
    String freelancerId,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/freelancers/$freelancerId/profile');
      final response = await http.get(uri, headers: _headers(token));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final details = body['details'] ?? body['data'] ?? body;
        if (details is Map) return Map<String, dynamic>.from(details);
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> closeAccount(
    String token,
    String userId, {
    String? reason,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/admin/accounts/$userId/close'),
        headers: _headers(token),
        body: jsonEncode({'reason': reason}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getAppeals(
    String token, {
    String status = 'all',
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/admin/appeals').replace(
        queryParameters: {
          'status': status,
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      final res = await http.get(uri, headers: _headers(token));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final details = body['details'] ?? body['data'] ?? body;
        if (details is List) {
          return {
            'items': List<Map<String, dynamic>>.from(details),
            'pagination': <String, dynamic>{},
          };
        }
        if (details is Map) {
          final rawItems = details['items'] ?? details['appeals'] ?? [];
          final rawPag = details['pagination'];
          return {
            'items': rawItems is List
                ? List<Map<String, dynamic>>.from(rawItems)
                : <Map<String, dynamic>>[],
            'pagination': rawPag is Map
                ? Map<String, dynamic>.from(rawPag)
                : <String, dynamic>{},
          };
        }
      }
    } catch (_) {}
    return {'items': [], 'pagination': {}};
  }

  static Future<bool> resolveAppeal(
    String token, {
    required String appealId,
    required String action, // 'approve' | 'reject'
    String? adminNote,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/admin/appeals/$appealId/$action'),
        headers: _headers(token),
        body: jsonEncode({'admin_note': adminNote}),
      );
      debugPrint('resolveAppeal status: ${res.statusCode}');
      debugPrint('resolveAppeal body: ${res.body}');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('resolveAppeal error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getDisputedContracts(
    String token, {
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/admin/contracts/disputed').replace(
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      final res = await http.get(uri, headers: _headers(token));
      if (res.statusCode == 200) {
        return _extract(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return {'items': [], 'pagination': {}};
  }

  static Future<Map<String, dynamic>?> arbitrateDispute(
    String token, {
    required String contractId,
    required String outcome, // 'approve' | 'cancel' | 'revise'
    String? note,
    String? newDeadline, // ISO date string, required if outcome == 'revise'
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/admin/contracts/$contractId/arbitrate'),
        headers: _headers(token),
        body: jsonEncode({
          'outcome': outcome,
          if (note != null && note.isNotEmpty) 'note': note,
          if (newDeadline != null) 'new_deadline': newDeadline,
        }),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final details = body['details'] ?? body['data'] ?? body;
        if (details is Map) return Map<String, dynamic>.from(details);
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> getClientAutoapproveHistory(
    String token,
    String clientId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/admin/clients/$clientId/autoapprove-history'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final details = body['details'] ?? body['data'] ?? body;
        if (details is Map) return Map<String, dynamic>.from(details);
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> getJobDetail(
    String token,
    String jobPostId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/job-posts/$jobPostId'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final details = body['details'] ?? body['data'] ?? body;
        if (details is Map) return Map<String, dynamic>.from(details);
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, dynamic>>> getJobRoles(
    String token,
    String jobPostId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/job-roles/job-post/$jobPostId'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final details = body['details'] ?? body['data'] ?? body;
        if (details is List) return List<Map<String, dynamic>>.from(details);
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> submitJobReport(
    String token, {
    required String jobPostId,
    required List<String> reasons,
    String? customReason,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/reports'),
        headers: _headers(token),
        body: jsonEncode({
          'reported_type': 'job_post',
          'job_post_id': jobPostId,
          'reasons': reasons,
          if (customReason != null && customReason.isNotEmpty)
            'custom_reason': customReason,
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic> _extract(Map<String, dynamic> data) {
    final details = data['details'] ?? data['data'] ?? data;
    List<Map<String, dynamic>> items = [];
    Map<String, dynamic> pagination = {};

    if (details is Map) {
      final rawItems = details['items'] ?? details['jobs'] ?? details['users'];
      if (rawItems is List) {
        items = List<Map<String, dynamic>>.from(rawItems);
      }
      final rawPag = details['pagination'];
      if (rawPag is Map) {
        pagination = Map<String, dynamic>.from(rawPag);
      } else {
        pagination = {
          if (details['total'] != null) 'total': details['total'],
          if (details['page'] != null) 'page': details['page'],
          if (details['page_size'] != null) 'page_size': details['page_size'],
          if (details['total_pages'] != null)
            'total_pages': details['total_pages'],
        };
      }
    } else if (details is List) {
      items = List<Map<String, dynamic>>.from(details);
    }

    return {'items': items, 'pagination': pagination};
  }

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
