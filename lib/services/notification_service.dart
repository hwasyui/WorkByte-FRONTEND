import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<Map<String, dynamic>>> getNotifications(
    String token, {
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/notifications?limit=$limit&offset=$offset'),
      headers: _headers(token),
    );

    final body = jsonDecode(res.body);
    debugPrint('GET /notifications → ${res.statusCode}');

    if (res.statusCode == 200) {
      final data = body['details'] ?? body['data'] ?? body;
      return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
    }

    throw Exception(body['details'] ?? 'Failed to get notifications');
  }

  Future<void> markAsRead(String token, String notificationId) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/notifications/$notificationId/read'),
      headers: _headers(token),
    );

    final body = jsonDecode(res.body);
    debugPrint('PUT /notifications/$notificationId/read → ${res.statusCode}');

    if (res.statusCode != 200) {
      throw Exception(body['details'] ?? 'Failed to mark notification as read');
    }
  }

  Future<Map<String, dynamic>> createNotification(
    String token,
    String userId,
    String title,
    String message,
    String type, {
    Map<String, dynamic>? data,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/notifications'),
      headers: _headers(token),
      body: jsonEncode({
        'user_id': userId,
        'title': title,
        'message': message,
        'notification_type': type,
        'data': data,
      }),
    );

    final body = jsonDecode(res.body);
    debugPrint('POST /notifications → ${res.statusCode}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      return body['details'] ?? body['data'] ?? body;
    }

    throw Exception(body['details'] ?? 'Failed to create notification');
  }
}