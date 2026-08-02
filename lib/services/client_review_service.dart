import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/client_review_model.dart';
import '../models/review_model.dart' show RedFlagAlert;
import 'session_guard.dart';

class ClientReviewService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  ClientReviewService();

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _parse(http.Response res, String context) {
    SessionGuard.check(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['details'] as Map<String, dynamic>? ?? body;
    }
    throw _buildException(res, context);
  }

  List<dynamic> _parseList(http.Response res, String context) {
    SessionGuard.check(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['details'] as List<dynamic>? ?? [];
    }
    throw _buildException(res, context);
  }

  ClientReviewServiceException _buildException(http.Response res, String context) {
    String message;
    List<String>? detectedLabels;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      message =
          body['details'] as String? ??
          body['message'] as String? ??
          body['detail'] as String? ??
          'Unknown error';
      final labels = body['detected_labels'];
      if (labels is List) {
        detectedLabels = labels.map((e) => e.toString()).toList();
      }
    } catch (_) {
      message = res.body;
    }
    debugPrint('$context failed (${res.statusCode}): $message');
    return ClientReviewServiceException(message, detectedLabels: detectedLabels);
  }

  Future<ClientReview> getClientReviewForContract({
    required String token,
    required String contractId,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/client-reviews/contract/$contractId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    return ClientReview.fromJson(_parse(res, 'getClientReviewForContract'));
  }

  Future<String> submitClientReview({
    required String token,
    required String clientReviewId,
    required SubmitClientReviewRequest request,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.post(
        Uri.parse('$_baseUrl/client-reviews/$clientReviewId/submit'),
        headers: _headers(t),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 20)),
    );
    final data = _parse(res, 'submitClientReview');
    return data['message'] as String? ?? 'Review submitted successfully.';
  }

  Future<ClientReview> getClientReview({
    required String token,
    required String clientReviewId,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/client-reviews/$clientReviewId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    return ClientReview.fromJson(_parse(res, 'getClientReview'));
  }

  Future<List<ClientReview>> getClientReviews({
    required String token,
    required String clientId,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/client-reviews/client/$clientId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final list = _parseList(res, 'getClientReviews');
    return list
        .map((e) => ClientReview.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ClientTrustScore> getClientTrustScore({
    required String token,
    required String clientId,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/client-reviews/trust-score/$clientId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    return ClientTrustScore.fromJson(_parse(res, 'getClientTrustScore'));
  }

  Future<List<RedFlagAlert>> getClientRedFlags({
    required String token,
    required String clientId,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/client-reviews/red-flags/$clientId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final list = _parseList(res, 'getClientRedFlags');
    return list
        .map((e) => RedFlagAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class ClientReviewServiceException implements Exception {
  final String message;
  final List<String>? detectedLabels;
  const ClientReviewServiceException(this.message, {this.detectedLabels});

  @override
  String toString() => message;
}
