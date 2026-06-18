import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/dm_model.dart';

class DMFailureException implements Exception {
  final String message;

  const DMFailureException(this.message);

  @override
  String toString() => message;
}

class DMService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  dynamic _unwrap(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      return body['details'] ?? body['data'] ?? body['message'] ?? body;
    } catch (_) {
      return res.body;
    }
  }

  Future<DMThreadStartResult> startThread({
    required String token,
    required String participantId,
    String? jobPostId,
    String? messageText,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/dm/threads'),
      headers: _headers(token),
      body: jsonEncode({
        'participant_id': participantId, // ✅ Fixed: snake_case
        if (jobPostId != null) 'job_post_id': jobPostId, // ✅ Fixed: snake_case
        if (messageText != null && messageText.trim().isNotEmpty)
          'message_text': messageText.trim(), // ✅ Fixed: snake_case
      }),
    );

    debugPrint('POST /dm/threads -> ${res.statusCode}');
    debugPrint('POST /dm/threads body: ${res.body}');
    final body = _unwrap(res);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return DMThreadStartResult.fromJson(
        Map<String, dynamic>.from(body as Map),
      );
    }

    throw Exception(body is String ? body : 'Failed to start thread');
  }

  Future<DMThreadListResult> getThreads(String token, {String? status}) async {
    final uri = Uri.parse(
      '$_baseUrl/dm/threads',
    ).replace(queryParameters: status != null ? {'status': status} : null);

    final res = await http.get(uri, headers: _headers(token));
    debugPrint('GET /dm/threads -> ${res.statusCode}');
    final body = _unwrap(res);

    if (res.statusCode == 200) {
      return DMThreadListResult.fromJson(
        Map<String, dynamic>.from(body as Map),
      );
    }

    throw Exception(body is String ? body : 'Failed to load threads');
  }

  Future<List<DMThreadModel>> getRequests(String token) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/dm/threads/requests'),
      headers: _headers(token),
    );

    debugPrint('GET /dm/threads/requests -> ${res.statusCode}');
    final body = _unwrap(res);

    if (res.statusCode == 200) {
      final map = Map<String, dynamic>.from(body as Map);
      final list = map['requests'] as List? ?? const [];
      return list
          .map(
            (e) => DMThreadModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    }

    throw Exception(body is String ? body : 'Failed to load requests');
  }

  Future<DMThreadModel> getThread(String token, String threadId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/dm/threads/$threadId'),
      headers: _headers(token),
    );

    debugPrint('GET /dm/threads/$threadId -> ${res.statusCode}');
    final body = _unwrap(res);

    if (res.statusCode == 200) {
      return DMThreadModel.fromJson(Map<String, dynamic>.from(body as Map));
    }

    throw Exception(body is String ? body : 'Failed to load thread');
  }

  Future<DMThreadModel> acceptThread(String token, String threadId) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/dm/threads/$threadId/accept'),
      headers: _headers(token),
    );

    debugPrint('PUT /dm/threads/$threadId/accept -> ${res.statusCode}');
    final body = _unwrap(res);

    if (res.statusCode == 200) {
      return DMThreadModel.fromJson(Map<String, dynamic>.from(body as Map));
    }

    throw Exception(body is String ? body : 'Failed to accept thread');
  }

  Future<DMThreadModel> declineThread(String token, String threadId) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/dm/threads/$threadId/decline'),
      headers: _headers(token),
    );

    debugPrint('PUT /dm/threads/$threadId/decline -> ${res.statusCode}');
    final body = _unwrap(res);

    if (res.statusCode == 200) {
      return DMThreadModel.fromJson(Map<String, dynamic>.from(body as Map));
    }

    throw Exception(body is String ? body : 'Failed to decline thread');
  }

  Future<DMMessagePage> getMessages(
    String token,
    String threadId, {
    int limit = 50,
    String? before,
  }) async {
    final uri = Uri.parse('$_baseUrl/dm/threads/$threadId/messages').replace(
      queryParameters: {
        'limit': '$limit',
        if (before != null && before.isNotEmpty) 'before': before,
      },
    );

    final res = await http.get(uri, headers: _headers(token));
    debugPrint('GET /dm/threads/$threadId/messages -> ${res.statusCode}');
    final body = _unwrap(res);

    if (res.statusCode == 200) {
      return DMMessagePage.fromJson(Map<String, dynamic>.from(body as Map));
    }

    throw Exception(body is String ? body : 'Failed to load messages');
  }

  Future<DMMessageModel> sendMessage({
    required String token,
    required String threadId,
    required String messageText,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/dm/threads/$threadId/messages'),
      headers: _headers(token),
      body: jsonEncode({
        'message_text': messageText.trim(), // ✅ Fixed: snake_case
      }),
    );

    debugPrint('POST /dm/threads/$threadId/messages -> ${res.statusCode}');
    debugPrint('POST /dm/threads/$threadId/messages body: ${res.body}');
    final body = _unwrap(res);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return DMMessageModel.fromJson(Map<String, dynamic>.from(body as Map));
    }

    throw DMFailureException(body is String ? body : 'Failed to send message');
  }

  Future<DMMessageModel> sendFileMessage({
    required String token,
    required String threadId,
    required String filePath,
    required String fileName,
    String? messageText,
    bool isVoiceNote = false,
  }) async {
    final uri = Uri.parse('$_baseUrl/dm/threads/$threadId/messages/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath('file', filePath, filename: fileName),
    );
    if (messageText != null && messageText.trim().isNotEmpty) {
      request.fields['message_text'] = messageText.trim();
    }
    if (isVoiceNote) {
      request.fields['is_voice_note'] = 'true';
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    debugPrint(
      'POST /dm/threads/$threadId/messages/upload -> ${res.statusCode}',
    );
    final body = _unwrap(res);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return DMMessageModel.fromJson(Map<String, dynamic>.from(body as Map));
    }

    throw DMFailureException(body is String ? body : 'Failed to send file');
  }

  Future<void> markThreadAsRead({
    required String token,
    required String threadId,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/dm/threads/$threadId/read'),
      headers: _headers(token),
    );

    debugPrint('PUT /dm/threads/$threadId/read -> ${res.statusCode}');
    final body = _unwrap(res);

    if (res.statusCode != 200) {
      throw Exception(body is String ? body : 'Failed to mark thread as read');
    }
  }
}
