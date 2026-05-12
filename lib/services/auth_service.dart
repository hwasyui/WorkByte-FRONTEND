import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class AuthService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _tokenKey = 'auth_token';

  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = jsonDecode(response.body);
    debugPrint('POST /auth/login response: $body');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final inner = body['details'] ?? body['data'] ?? body;
      final token = inner['access_token'] as String?;
      if (token != null) return token;
    }

    throw Exception(
      body['details'] ?? body['message'] ?? body['detail'] ?? 'Login failed',
    );
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getSavedToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearSavedToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> register({
    required String email,
    required String password,
    required String userType,
    String? fullName,
    String? companyName,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'user_type': userType,
        'full_name': fullName ?? email.split('@')[0],
        if (companyName != null) 'company_name': companyName,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data['status'] == 'success' || data['data'] != null) return true;
    }

    throw Exception(
      data['details'] ??
          data['message'] ??
          data['detail'] ??
          'Registration failed',
    );
  }

  Future<void> verifyEmail({required String email, required String otp}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data['status'] == 'success' || data['data'] != null) return;
    }

    throw Exception(
      data['details'] ??
          data['message'] ??
          data['detail'] ??
          'Verification failed',
    );
  }

  Future<void> resendVerification({required String email}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data['status'] == 'success' || data['data'] != null) return;
    }

    throw Exception(
      data['details'] ??
          data['message'] ??
          data['detail'] ??
          'Failed to resend code',
    );
  }

  Future<Map<String, dynamic>> addRole({
    required String token,
    required String role,
    required String fullName,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/add-role'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'role': role, 'full_name': fullName}),
    );

    final body = jsonDecode(response.body);
    debugPrint('POST /auth/add-role response: $body');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body['details'] ?? body['data'] ?? body;
    }

    throw Exception(
      body['details'] ??
          body['message'] ??
          body['detail'] ??
          'Failed to add role',
    );
  }

  Future<UserModel> getMe(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final data = body['details'] ?? body['data'] ?? body;
      return UserModel.fromJson(data as Map<String, dynamic>);
    }

    if (response.statusCode == 401) {
      throw const SessionExpiredException();
    }

    throw Exception('Failed to fetch user');
  }
}

class SessionExpiredException implements Exception {
  const SessionExpiredException();

  @override
  String toString() => 'Session expired. Please log in again.';
}
