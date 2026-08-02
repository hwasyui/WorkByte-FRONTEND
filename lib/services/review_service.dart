import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/review_model.dart';
import 'session_guard.dart';

class ReviewService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  ReviewService();

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

  ReviewServiceException _buildException(http.Response res, String context) {
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
    return ReviewServiceException(message, detectedLabels: detectedLabels);
  }

  Future<Review> getReviewForContract({
    required String token,
    required String contractId,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/reviews/contract/$contractId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    return Review.fromJson(_parse(res, 'getReviewForContract'));
  }

  Future<String> submitReview({
    required String token,
    required String reviewId,
    required SubmitReviewRequest request,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.post(
        Uri.parse('$_baseUrl/reviews/$reviewId/submit'),
        headers: _headers(t),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 20)),
    );
    final data = _parse(res, 'submitReview');
    return data['message'] as String? ?? 'Review submitted successfully.';
  }

  Future<Review> getReview({
    required String token,
    required String reviewId,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/reviews/$reviewId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    return Review.fromJson(_parse(res, 'getReview'));
  }

  Future<List<Review>> getFreelancerReviews({
    required String token,
    required String freelancerId,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/reviews/freelancer/$freelancerId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final list = _parseList(res, 'getFreelancerReviews');
    return list.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TrustScore> getTrustScore({
    required String token,
    required String freelancerId,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/reviews/trust-score/$freelancerId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    return TrustScore.fromJson(_parse(res, 'getTrustScore'));
  }

  Future<List<RedFlagAlert>> getRedFlags({
    required String token,
    required String freelancerId,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/reviews/red-flags/$freelancerId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final list = _parseList(res, 'getRedFlags');
    return list
        .map((e) => RedFlagAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class ReviewServiceException implements Exception {
  final String message;
  final List<String>? detectedLabels;
  const ReviewServiceException(this.message, {this.detectedLabels});

  @override
  String toString() => message;
}
