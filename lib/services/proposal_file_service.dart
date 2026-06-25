import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/proposal_file_model.dart';

class ProposalFileService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Fetch all files for a single proposal
  Future<List<ProposalFileModel>> getFilesByProposalId(
    String token,
    String proposalId,
  ) async {
    final uri = Uri.parse('$_baseUrl/proposal-files/proposal/$proposalId');
    final res = await http.get(uri, headers: _headers(token));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final data = body['details'] as List<dynamic>? ?? [];
      return data
          .map((e) => ProposalFileModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Create a proposal file record
  Future<ProposalFileModel?> createProposalFile({
    required String token,
    required String proposalId,
    required String fileUrl,
    required String fileType,
    required String fileName,
    int? fileSize,
  }) async {
    final uri = Uri.parse('$_baseUrl/proposal-files');
    final res = await http.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        'proposal_id': proposalId,
        'file_url': fileUrl,
        'file_type': fileType,
        'file_name': fileName,
        'file_size': fileSize,
      }),
    );

    if (res.statusCode == 201) {
      final body = jsonDecode(res.body);
      return ProposalFileModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    return null;
  }

  /// Delete a proposal file
  Future<bool> deleteProposalFile(String token, String proposalFileId) async {
    final uri = Uri.parse('$_baseUrl/proposal-files/$proposalFileId');
    final res = await http.delete(uri, headers: _headers(token));
    return res.statusCode == 200;
  }
}
