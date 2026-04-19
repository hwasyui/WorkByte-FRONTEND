import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UploadService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  /// Upload a [File] to the specified bucket
  Future<Map<String, dynamic>?> uploadFile(
    String token,
    File file, {
    required String bucket,
  }) async {
    final uri = Uri.parse('$_baseUrl/upload?bucket=$bucket');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body);

    debugPrint('POST /upload?bucket=$bucket → ${res.statusCode}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      return body['details'] as Map<String, dynamic>?;
    }
    throw Exception(body['details'] ?? 'Upload failed');
  }

  /// Upload a [PlatformFile] (from file_picker) — convenience wrapper
  Future<Map<String, dynamic>?> uploadPlatformFile(
    String token,
    PlatformFile file, {
    required String bucket,
  }) async {
    if (file.path == null) throw Exception('File path is null');
    return uploadFile(token, File(file.path!), bucket: bucket);
  }
}
