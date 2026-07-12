import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/portfolio_model.dart';

class PortfolioService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decodeBody(http.Response res) {
    final decoded = jsonDecode(res.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  List<PortfolioModel> _parseList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(PortfolioModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<PortfolioModel>> getPortfolios(String token) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/portfolios'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 20));
    final body = _decodeBody(res);
    debugPrint('GET /portfolios: ${res.statusCode}');

    if (res.statusCode == 200) {
      final raw = body['details'] ?? body['data'] ?? body;
      return _parseList(raw);
    }
    throw Exception(body['message'] ?? 'Failed to fetch portfolios');
  }

  Future<List<PortfolioModel>> getPortfoliosByFreelancer(
    String token,
    String freelancerId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/portfolios/freelancer/$freelancerId'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 20));
    final body = _decodeBody(res);
    debugPrint('GET /portfolios/freelancer/$freelancerId: ${res.statusCode}');

    if (res.statusCode == 200) {
      final raw = body['details'] ?? body['data'] ?? body;
      return _parseList(raw);
    }
    throw Exception(body['message'] ?? 'Failed to fetch portfolios');
  }

  Future<PortfolioModel> createPortfolio(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/portfolios'),
      headers: _headers(token),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 20));
    final body = _decodeBody(res);
    debugPrint('POST /portfolios: ${res.statusCode}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final raw = body['details'] ?? body['data'] ?? body;
      return PortfolioModel.fromJson(raw as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to create portfolio');
  }

  Future<void> deletePortfolio(String token, String portfolioId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/portfolios/$portfolioId'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 20));
    debugPrint('DELETE /portfolios/$portfolioId: ${res.statusCode}');

    if (res.statusCode != 200 && res.statusCode != 204) {
      final body = _decodeBody(res);
      throw Exception(body['message'] ?? 'Failed to delete portfolio');
    }
  }
}
