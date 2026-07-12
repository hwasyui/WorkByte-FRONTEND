import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ClientService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  /// GET /clients/:clientId/reliability - "Responsive" | "Unresponsive",
  /// derived server-side from how often the client's contracts had to be
  /// auto-approved due to inactivity. Lets a freelancer gauge a client
  /// before taking on their job.
  Future<String?> getClientReliability(String token, String clientId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/clients/$clientId/reliability'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['details'] ?? body['data'] ?? body;
        if (data is Map) return data['label'] as String?;
      }
    } catch (e) {
      debugPrint('getClientReliability error: $e');
    }
    return null;
  }
}
