import 'dart:convert';
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
    if (!isAdmin) throw Exception('Access denied. This account does not have admin privileges.');

    return token;
  }

  static Future<Map<String, dynamic>> getFreelancers(
    String token, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/freelancers/browse/all').replace(
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

  static Future<Map<String, dynamic>> getClients(
    String token, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/clients/browse/all').replace(
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

  static Map<String, dynamic> _extract(Map<String, dynamic> data) {
    final details = data['details'];
    List<Map<String, dynamic>> items = [];
    Map<String, dynamic> pagination = {};

    if (details is Map) {
      final rawItems = details['items'];
      if (rawItems is List) {
        items = List<Map<String, dynamic>>.from(rawItems);
      }
      final rawPag = details['pagination'];
      if (rawPag is Map) {
        pagination = Map<String, dynamic>.from(rawPag);
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
