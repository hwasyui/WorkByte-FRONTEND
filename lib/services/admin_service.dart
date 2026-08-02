import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/admin_review_moderation_model.dart';
import '../models/admin_red_flag_detail_model.dart';
import 'admin_session_guard.dart';

/// Result of an admin action that requires a reason. Carries the failure
/// message (including a field-level 422 validation message) so the UI can
/// surface it inline rather than as a generic snackbar.
class AdminActionOutcome {
  final bool success;
  final int? statusCode;
  final String? errorMessage;

  /// For red-flag resolve: false means the note was NOT persisted because the
  /// DB migration is pending. Null when the response didn't report it.
  final bool? resolutionRecorded;

  const AdminActionOutcome({
    required this.success,
    this.statusCode,
    this.errorMessage,
    this.resolutionRecorded,
  });

  /// True on 404 — the item was already actioned by another admin.
  bool get alreadyActioned => statusCode == 404;
}

class AdminService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const String _tokenKey = 'admin_token';
  static const String _refreshTokenKey = 'admin_refresh_token';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getSavedToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> getSavedRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> clearRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  static Future<String?> refreshAccessToken() async {
    final refreshToken = await getSavedRefreshToken();
    if (refreshToken == null) return null;

    final res = await http.post(
      Uri.parse('$_baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    ).timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final details = body['details'] as Map<String, dynamic>;
      final newAccess = details['access_token'] as String;
      final newRefresh = details['refresh_token'] as String;
      await saveToken(newAccess);
      await saveRefreshToken(newRefresh);
      return newAccess;
    }

    await clearToken();
    await clearRefreshToken();
    return null;
  }

  static Future<bool> verifyAdminToken(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 20));
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
    ).timeout(const Duration(seconds: 20));
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
    final refreshToken = inner['refresh_token'] as String?;

    final meRes = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 20));
    if (meRes.statusCode != 200) throw Exception('Failed to verify account');

    final meBody = jsonDecode(meRes.body);
    final meData = meBody['details'] ?? meBody['data'] ?? meBody;
    final isAdmin = meData['is_admin'] as bool? ?? false;
    if (!isAdmin)
      throw Exception(
        'Access denied. This account does not have admin privileges.',
      );

    if (refreshToken != null) await saveRefreshToken(refreshToken);
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
    final response = await AdminSessionGuard.guard(
      token,
      (t) => http.get(uri, headers: _headers(t)).timeout(const Duration(seconds: 20)),
    );
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
    final response = await AdminSessionGuard.guard(
      token,
      (t) => http.get(uri, headers: _headers(t)).timeout(const Duration(seconds: 20)),
    );
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
    final response = await AdminSessionGuard.guard(
      token,
      (t) => http.get(uri, headers: _headers(t)).timeout(const Duration(seconds: 20)),
    );
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
    final response = await AdminSessionGuard.guard(
      token,
      (t) => http.get(uri, headers: _headers(t)).timeout(const Duration(seconds: 20)),
    );
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
    final response = await AdminSessionGuard.guard(
      token,
      (t) => http.get(uri, headers: _headers(t)).timeout(const Duration(seconds: 20)),
    );
    if (response.statusCode == 200) {
      return _extract(jsonDecode(response.body) as Map<String, dynamic>);
    }
    return {'items': [], 'pagination': {}};
  }

  static Future<Map<String, dynamic>> getDashboardStats(String token) async {
    try {
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.get(
          Uri.parse('$_baseUrl/admin/dashboard'),
          headers: _headers(t),
        ).timeout(const Duration(seconds: 20)),
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
    final response = await AdminSessionGuard.guard(
      token,
      (t) => http.get(uri, headers: _headers(t)).timeout(const Duration(seconds: 20)),
    );
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
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.post(
          Uri.parse('$_baseUrl/admin/reports/$reportId/$action'),
          headers: _headers(t),
          body: jsonEncode({'admin_note': adminNote}),
        ).timeout(const Duration(seconds: 20)),
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
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.get(uri, headers: _headers(t)).timeout(const Duration(seconds: 20)),
      );
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
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.post(
          Uri.parse('$_baseUrl/admin/scam-flags/$flagId/$action'),
          headers: _headers(t),
          body: jsonEncode({'admin_note': adminNote}),
        ).timeout(const Duration(seconds: 20)),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getReviewRedFlags(
    String token, {
    bool? isResolved,
    String sortBy = 'triggered_at',
    String sortDir = 'desc',
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/admin/reviews/red-flags').replace(
        queryParameters: {
          if (isResolved != null) 'is_resolved': isResolved.toString(),
          'sort_by': sortBy,
          'sort_dir': sortDir,
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.get(uri, headers: _headers(t)).timeout(const Duration(seconds: 20)),
      );
      if (res.statusCode == 200) {
        return _extract(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return {'items': [], 'pagination': {}};
  }

  static Future<AdminActionOutcome> resolveReviewRedFlag(
    String token,
    String alertId, {
    required String reason,
  }) {
    return _postWithReason(
      token,
      '/admin/reviews/red-flags/$alertId/resolve',
      reason,
      readResolutionRecorded: true,
    );
  }

  static Future<Map<String, dynamic>> getFlaggedReviews(
    String token, {
    String status = 'all',
    String sortBy = 'created_at',
    String sortDir = 'desc',
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/admin/reviews/flagged').replace(
        queryParameters: {
          'status': status,
          'sort_by': sortBy,
          'sort_dir': sortDir,
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.get(uri, headers: _headers(t)).timeout(const Duration(seconds: 20)),
      );
      if (res.statusCode == 200) {
        return _extract(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return {'items': [], 'pagination': {}};
  }

  static Future<AdminActionOutcome> overridePublishReview(
    String token,
    String reviewId, {
    required String reason,
  }) {
    return _postWithReason(
      token,
      '/admin/reviews/$reviewId/override-publish',
      reason,
    );
  }

  static Future<AdminActionOutcome> upholdReview(
    String token,
    String reviewId, {
    required String reason,
  }) {
    return _postWithReason(token, '/admin/reviews/$reviewId/uphold', reason);
  }

  static Future<ReviewModerationDetail?> getReviewModerationDetail(
    String token,
    String reviewId,
  ) {
    return _getModerationDetail(
      token,
      '/admin/reviews/$reviewId/moderation',
      isClientReview: false,
    );
  }

  static Future<Map<String, dynamic>> getFlaggedClientReviews(
    String token, {
    String status = 'all',
    String sortBy = 'created_at',
    String sortDir = 'desc',
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/admin/client-reviews/flagged').replace(
        queryParameters: {
          'status': status,
          'sort_by': sortBy,
          'sort_dir': sortDir,
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.get(uri, headers: _headers(t)).timeout(const Duration(seconds: 20)),
      );
      if (res.statusCode == 200) {
        return _extract(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return {'items': [], 'pagination': {}};
  }

  static Future<AdminActionOutcome> overridePublishClientReview(
    String token,
    String clientReviewId, {
    required String reason,
  }) {
    return _postWithReason(
      token,
      '/admin/client-reviews/$clientReviewId/override-publish',
      reason,
    );
  }

  static Future<AdminActionOutcome> upholdClientReview(
    String token,
    String clientReviewId, {
    required String reason,
  }) {
    return _postWithReason(
      token,
      '/admin/client-reviews/$clientReviewId/uphold',
      reason,
    );
  }

  static Future<ReviewModerationDetail?> getClientReviewModerationDetail(
    String token,
    String reviewId,
  ) {
    return _getModerationDetail(
      token,
      '/admin/client-reviews/$reviewId/moderation',
      isClientReview: true,
    );
  }

  static Future<RedFlagDetail?> getRedFlagDetail(
    String token,
    String alertId,
  ) async {
    try {
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http
            .get(
              Uri.parse('$_baseUrl/admin/reviews/red-flags/$alertId'),
              headers: _headers(t),
            )
            .timeout(const Duration(seconds: 20)),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data =
            (body['details'] ?? body['data'] ?? body) as Map<String, dynamic>;
        return RedFlagDetail.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Shared POST-with-reason for override-publish, uphold, and resolve. Returns
  /// a structured outcome so callers can show 422 field errors inline and
  /// special-case 404 ("already actioned by another admin").
  static Future<AdminActionOutcome> _postWithReason(
    String token,
    String path,
    String reason, {
    bool readResolutionRecorded = false,
  }) async {
    try {
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http
            .post(
              Uri.parse('$_baseUrl$path'),
              headers: _headers(t),
              body: jsonEncode({'reason': reason}),
            )
            .timeout(const Duration(seconds: 20)),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        bool? resolutionRecorded;
        if (readResolutionRecorded) {
          try {
            final body = jsonDecode(res.body) as Map<String, dynamic>;
            final data = (body['details'] ?? body['data'] ?? body);
            if (data is Map && data['resolution_recorded'] != null) {
              resolutionRecorded = data['resolution_recorded'] == true;
            }
          } catch (_) {}
        }
        return AdminActionOutcome(
          success: true,
          statusCode: res.statusCode,
          resolutionRecorded: resolutionRecorded,
        );
      }
      return AdminActionOutcome(
        success: false,
        statusCode: res.statusCode,
        errorMessage: res.statusCode == 404
            ? 'This item was already actioned by another admin.'
            : _errorMessage(res.body),
      );
    } catch (_) {
      return const AdminActionOutcome(
        success: false,
        errorMessage: 'Network error — please try again.',
      );
    }
  }

  static Future<ReviewModerationDetail?> _getModerationDetail(
    String token,
    String path, {
    required bool isClientReview,
  }) async {
    try {
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http
            .get(Uri.parse('$_baseUrl$path'), headers: _headers(t))
            .timeout(const Duration(seconds: 20)),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data =
            (body['details'] ?? body['data'] ?? body) as Map<String, dynamic>;
        return ReviewModerationDetail.fromJson(
          data,
          isClientReview: isClientReview,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Extracts a human-readable message from an error body. Handles the app's
  /// `details`/`message`/`detail` string convention and raw FastAPI/Pydantic
  /// 422 bodies where `detail` is a list of `{msg, loc}` entries.
  static String _errorMessage(String rawBody) {
    try {
      final body = jsonDecode(rawBody);
      if (body is Map<String, dynamic>) {
        final detail = body['detail'];
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            return first['msg'].toString();
          }
        }
        final msg = body['details'] ?? body['message'] ?? body['detail'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } catch (_) {}
    return 'Action failed — please try again.';
  }

  static Future<Map<String, dynamic>> getModerationItems(
    String token, {
    String status = 'pending',
    // Highest single label, not the sum of all five — same number the card
    // badge and the auto-close sweep use.
    String sortBy = 'max_score',
    String sortDir = 'desc',
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/admin/moderation').replace(
        queryParameters: {
          'status': status,
          'sort_by': sortBy,
          'sort_dir': sortDir,
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.get(uri, headers: _headers(t)).timeout(const Duration(seconds: 20)),
      );
      if (res.statusCode == 200) {
        return _extract(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return {'items': [], 'pagination': {}};
  }

  static Future<bool> actionModerationItem(
    String token, {
    required String moderationId,
    required String action,
    String? adminNote,
  }) async {
    try {
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.post(
          Uri.parse('$_baseUrl/admin/moderation/$moderationId/$action'),
          headers: _headers(t),
          body: jsonEncode({'admin_note': adminNote}),
        ).timeout(const Duration(seconds: 20)),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> closeJob(
    String token,
    String jobPostId, {
    String? reason,
  }) async {
    try {
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.post(
          Uri.parse('$_baseUrl/admin/jobs/$jobPostId/close'),
          headers: _headers(t),
          body: jsonEncode({'reason': reason}),
        ).timeout(const Duration(seconds: 20)),
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
      final response = await AdminSessionGuard.guard(
        token,
        (t) => http.get(uri, headers: _headers(t)).timeout(const Duration(seconds: 20)),
      );
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
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.post(
          Uri.parse('$_baseUrl/admin/accounts/$userId/close'),
          headers: _headers(t),
          body: jsonEncode({'reason': reason}),
        ).timeout(const Duration(seconds: 20)),
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
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.get(uri, headers: _headers(t)).timeout(const Duration(seconds: 20)),
      );
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
    required String action,
    String? adminNote,
  }) async {
    try {
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.post(
          Uri.parse('$_baseUrl/admin/appeals/$appealId/$action'),
          headers: _headers(t),
          body: jsonEncode({'admin_note': adminNote}),
        ).timeout(const Duration(seconds: 20)),
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
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.get(uri, headers: _headers(t)),
      );
      if (res.statusCode == 200) {
        return _extract(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return {'items': [], 'pagination': {}};
  }

  static Future<Map<String, dynamic>?> arbitrateDispute(
    String token, {
    required String contractId,
    required String outcome,
    String? note,
    String? newDeadline,
  }) async {
    try {
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.put(
          Uri.parse('$_baseUrl/admin/contracts/$contractId/arbitrate'),
          headers: _headers(t),
          body: jsonEncode({
            'outcome': outcome,
            if (note != null && note.isNotEmpty) 'note': note,
            if (newDeadline != null) 'new_deadline': newDeadline,
          }),
        ),
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
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.get(
          Uri.parse('$_baseUrl/admin/clients/$clientId/autoapprove-history'),
          headers: _headers(t),
        ),
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
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.get(
          Uri.parse('$_baseUrl/job-posts/$jobPostId'),
          headers: _headers(t),
        ).timeout(const Duration(seconds: 20)),
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
      final res = await AdminSessionGuard.guard(
        token,
        (t) => http.get(
          Uri.parse('$_baseUrl/job-roles/job-post/$jobPostId'),
          headers: _headers(t),
        ).timeout(const Duration(seconds: 20)),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final details = body['details'] ?? body['data'] ?? body;
        if (details is List) return List<Map<String, dynamic>>.from(details);
      }
    } catch (_) {}
    return [];
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
