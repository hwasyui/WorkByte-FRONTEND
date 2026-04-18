import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/skill_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SkillService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<SkillModel>> getAllSkills(String token, {int? limit}) async {
    final uri = Uri.parse(
      '$_baseUrl/skills',
    ).replace(queryParameters: limit != null ? {'limit': '$limit'} : null);
    final res = await http.get(uri, headers: _headers(token));
    final body = jsonDecode(res.body);

    if (res.statusCode == 200) {
      final raw = body['details']; // ← was: body['data']
      if (raw == null) return [];
      final data = raw as List<dynamic>;
      return data
          .map((e) => SkillModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to fetch skills');
  }

  Future<List<SkillModel>> searchSkills(String token, String term) async {
    final uri = Uri.parse(
      '$_baseUrl/skills/search/${Uri.encodeComponent(term)}',
    );
    final res = await http.get(uri, headers: _headers(token));
    final body = jsonDecode(res.body);

    if (res.statusCode == 200) {
      final raw =
          body['details']?['results']; // ← was: body['data']?['results']
      if (raw == null) return [];
      final results = raw as List<dynamic>;
      return results
          .map((e) => SkillModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to search skills');
  }

  Future<List<SkillModel>> getSkillsByCategory(
    String token,
    String category,
  ) async {
    final uri = Uri.parse('$_baseUrl/skills/category/$category');
    final res = await http.get(uri, headers: _headers(token));
    final body = jsonDecode(res.body);

    if (res.statusCode == 200) {
      final raw = body['details']; // ← was: body['data']
      if (raw == null) return [];
      final data = raw as List<dynamic>;
      return data
          .map((e) => SkillModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details'] ?? 'Failed to fetch skills by category');
  }
}
