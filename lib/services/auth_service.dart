import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  // local
  // static const String _baseUrl = 'http://10.0.2.2:8000';

  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = jsonDecode(response.body);
    debugPrint('POST /auth/login response: $body'); // ← add this

    if (response.statusCode == 200 || response.statusCode == 201) {
      final inner = body['details'] ?? body['data'] ?? body;
      final token = inner['access_token'] as String?;
      if (token != null) return token;
    }

    throw Exception(
      body['details'] ?? body['message'] ?? body['detail'] ?? 'Login failed',
    );
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

  Future<void> verifyEmail({
    required String email,
    required String otp,
  }) async {
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
      debugPrint('Parsed user data: $data');
      return UserModel.fromJson(data as Map<String, dynamic>);
    }

    throw Exception('Session expired');
  }
}
