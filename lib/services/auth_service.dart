import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  static const String _refreshTokenKey = 'refresh_token';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '655326820214-se1d5coqfoe8304tduftv3n2roqt4fb1.apps.googleusercontent.com',
  );

  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      await signOutGoogle();
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) throw Exception('Google login cancelled');

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      if (idToken == null) throw Exception('Failed to get Google ID token');

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/oauth/google/mobile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      debugPrint('Google mobile login status: ${response.statusCode}');
      debugPrint('Google mobile login body: ${response.body}');

      Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw Exception('Server error (${response.statusCode}): ${response.body.substring(0, response.body.length.clamp(0, 200))}');
      }

      if (response.statusCode == 200) {
        final details = body['details'] as Map<String, dynamic>;
        final refreshToken = details['refresh_token'] as String?;
        if (refreshToken != null) await saveRefreshToken(refreshToken);
        return {
          'token': details['access_token'] as String,
          'is_new_user': details['is_new_user'] as bool,
        };
      }

      throw Exception(
        body['details'] ?? body['message'] ?? body['detail'] ?? 'Google login failed',
      );
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') throw Exception('Google login cancelled');
      throw Exception('Google login failed: ${e.message}');
    }
  }

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
      if (token != null) {
        final refreshToken = inner['refresh_token'] as String?;
        if (refreshToken != null) await saveRefreshToken(refreshToken);
        return token;
      }
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

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getSavedRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<String?> refreshAccessToken() async {
    final refreshToken = await getSavedRefreshToken();
    if (refreshToken == null) return null;

    final res = await http.post(
      Uri.parse('$_baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final details = body['details'] as Map<String, dynamic>;
      final newAccess = details['access_token'] as String;
      final newRefresh = details['refresh_token'] as String;
      await saveToken(newAccess);
      await saveRefreshToken(newRefresh);
      return newAccess;
    }

    await clearSavedToken();
    await clearRefreshToken();
    return null;
  }

  Future<void> logout(String refreshToken) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );
    } catch (_) {}
  }

  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } on PlatformException catch (e) {
      debugPrint('Google sign-out skipped: ${e.message}');
    }
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

  Future<void> forgotPassword({required String email}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data['status'] == 'success' || data['data'] != null) return;
    }
    throw Exception(
      data['details'] ?? data['message'] ?? data['detail'] ?? 'Failed to send reset code',
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp, 'new_password': newPassword}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data['status'] == 'success' || data['data'] != null) return;
    }
    throw Exception(
      data['details'] ?? data['message'] ?? data['detail'] ?? 'Password reset failed',
    );
  }

  Future<void> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data['status'] == 'success' || data['data'] != null) return;
    }
    throw Exception(
      data['details'] ?? data['message'] ?? data['detail'] ?? 'Failed to change password',
    );
  }

  Future<void> setPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/set-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'new_password': newPassword}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data['status'] == 'success' || data['data'] != null) return;
    }
    throw Exception(
      data['details'] ?? data['message'] ?? data['detail'] ?? 'Failed to set password',
    );
  }

  Future<UserModel> getMe(String token) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/auth/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

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
