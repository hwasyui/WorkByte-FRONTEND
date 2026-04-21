import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/review_model.dart';

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
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      // Your backend wraps everything in ResponseSchema.success → {data: ...}
      return body['data'] as Map<String, dynamic>? ?? body;
    }
    String message;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      message =
          body['message'] as String? ??
          body['detail'] as String? ??
          'Unknown error';
    } catch (_) {
      message = res.body;
    }
    throw ReviewServiceException(
      '$context failed (${res.statusCode}): $message',
    );
  }

  List<dynamic> _parseList(http.Response res, String context) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['data'] as List<dynamic>? ?? [];
    }
    String message;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      message = body['message'] as String? ?? 'Unknown error';
    } catch (_) {
      message = res.body;
    }
    throw ReviewServiceException(
      '$context failed (${res.statusCode}): $message',
    );
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
    );
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
    );
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
    );
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
    );
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
    );
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
    );
    final list = _parseList(res, 'getRedFlags');
    return list
        .map((e) => RedFlagAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Exception ────────────────────────────────────────────────────────────────

class ReviewServiceException implements Exception {
  final String message;
  const ReviewServiceException(this.message);

  @override
  String toString() => message;
}
