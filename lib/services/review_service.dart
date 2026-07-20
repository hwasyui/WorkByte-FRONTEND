import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/review_model.dart';
import 'session_guard.dart';

/// Centralises all HTTP calls for the review system.
/// Throws [ReviewServiceException] on any non-2xx response so the
/// provider can catch and surface a human-readable message.
class ReviewService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  ReviewService();

  // ── Shared headers ──────────────────────────────────────────────────────

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── Response parser ─────────────────────────────────────────────────────

  Map<String, dynamic> _parse(http.Response res, String context) {
    SessionGuard.check(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      // Your backend wraps everything in ResponseSchema.success → {data: ...}
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

  // Technical context (endpoint + status code) is logged for debugging but kept
  // out of `message`, since that string is shown to users as-is (see review_form.dart) -
  // "submitReview failed (400): ..." reads as a crash log, not a message a client
  // wrote a bad review would understand.
  ReviewServiceException _buildException(http.Response res, String context) {
    String message;
    List<String>? detectedLabels;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      message =
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

  // ── GET /reviews/contract/{contract_id} ─────────────────────────────────
  // Returns ReviewDetailResponse — the pending review shell with AI question
  // and suggested skill tags. Called when loading the review form.

  Future<Review> getReviewForContract({
    required String token,
    required String contractId,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/reviews/contract/$contractId'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 20));
    return Review.fromJson(_parse(res, 'getReviewForContract'));
  }

  // ── POST /reviews/{review_id}/submit ────────────────────────────────────
  // Submits the completed client review. Returns a success message string.

  Future<String> submitReview({
    required String token,
    required String reviewId,
    required SubmitReviewRequest request,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/reviews/$reviewId/submit'),
      headers: _headers(token),
      body: jsonEncode(request.toJson()),
    ).timeout(const Duration(seconds: 20));
    final data = _parse(res, 'submitReview');
    return data['message'] as String? ?? 'Review submitted successfully.';
  }

  // ── GET /reviews/{review_id} ─────────────────────────────────────────────
  // Full review detail including ratings, written content, skill tags, AI analysis.

  Future<Review> getReview({
    required String token,
    required String reviewId,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/reviews/$reviewId'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 20));
    return Review.fromJson(_parse(res, 'getReview'));
  }

  // ── GET /reviews/freelancer/{freelancer_id} ──────────────────────────────
  // All published reviews for a freelancer's public profile.

  Future<List<Review>> getFreelancerReviews({
    required String token,
    required String freelancerId,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/reviews/freelancer/$freelancerId'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 20));
    final list = _parseList(res, 'getFreelancerReviews');
    return list.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── GET /reviews/trust-score/{freelancer_id} ─────────────────────────────
  // Live AI-computed trust score with component breakdown and rank.

  Future<TrustScore> getTrustScore({
    required String token,
    required String freelancerId,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/reviews/trust-score/$freelancerId'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 20));
    return TrustScore.fromJson(_parse(res, 'getTrustScore'));
  }

  // ── GET /reviews/red-flags/{freelancer_id} ───────────────────────────────
  // Unresolved red flag alerts — intended for admin dashboards.

  Future<List<RedFlagAlert>> getRedFlags({
    required String token,
    required String freelancerId,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/reviews/red-flags/$freelancerId'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 20));
    final list = _parseList(res, 'getRedFlags');
    return list
        .map((e) => RedFlagAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Exception ────────────────────────────────────────────────────────────────

class ReviewServiceException implements Exception {
  final String message;
  final List<String>? detectedLabels;
  const ReviewServiceException(this.message, {this.detectedLabels});

  @override
  String toString() => message;
}
