import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

// ── Load states ───────────────────────────────────────────────────────────────

enum ReviewLoadState { idle, loading, loaded, error }

// ── Provider ──────────────────────────────────────────────────────────────────

class ReviewProvider extends ChangeNotifier {
  final ReviewService _service = ReviewService();

  // ── Review form (pending review for a contract) ──────────────────────────

  ReviewLoadState _formState = ReviewLoadState.idle;
  ReviewLoadState get formState => _formState;

  Review? _pendingReview;
  Review? get pendingReview => _pendingReview;

  // ── Submission state ─────────────────────────────────────────────────────

  bool _submitting = false;
  bool get submitting => _submitting;

  // ── Freelancer reviews list ──────────────────────────────────────────────

  ReviewLoadState _reviewsState = ReviewLoadState.idle;
  ReviewLoadState get reviewsState => _reviewsState;

  List<Review> _reviews = [];
  List<Review> get reviews => List.unmodifiable(_reviews);

  // ── Trust score ──────────────────────────────────────────────────────────

  ReviewLoadState _trustState = ReviewLoadState.idle;
  ReviewLoadState get trustState => _trustState;

  TrustScore? _trustScore;
  TrustScore? get trustScore => _trustScore;

  // ── Red flags ────────────────────────────────────────────────────────────

  ReviewLoadState _flagsState = ReviewLoadState.idle;
  ReviewLoadState get flagsState => _flagsState;

  List<RedFlagAlert> _redFlags = [];
  List<RedFlagAlert> get redFlags => List.unmodifiable(_redFlags);

  // ── Error ────────────────────────────────────────────────────────────────

  String? _error;
  String? get error => _error;

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Called when the review form screen initialises.
  /// Fetches the pending review shell (AI question + suggested skill tags)
  /// created by the post-completion pipeline.
  Future<void> loadReviewForm({
    required String token,
    required String contractId,
  }) async {
    _formState = ReviewLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      _pendingReview = await _service.getReviewForContract(
        token: token,
        contractId: contractId,
      );
      _formState = ReviewLoadState.loaded;
    } on ReviewServiceException catch (e) {
      _error = e.message;
      _formState = ReviewLoadState.error;
    } catch (e) {
      _error = 'Unexpected error loading review form.';
      _formState = ReviewLoadState.error;
    }
    notifyListeners();
  }

  /// Called when the client taps "Submit Review".
  /// Maps the screen's rating map + text fields into a [SubmitReviewRequest]
  /// and posts it to the backend. Returns true on success.
  Future<bool> submitReview({
    required String token,
    required String reviewId,
    required Map<String, double> ratingsMap, // {'communication': 4.5, ...}
    required String clientAnswer,
    required String overallComment,
    required List<String> extraSkillTags,
  }) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final request = SubmitReviewRequest(
        ratings: ratingsMap.entries
            .map((e) => ReviewRatingInput(category: e.key, score: e.value))
            .toList(),
        clientAnswer: clientAnswer,
        overallComment: overallComment,
        extraSkillTags: extraSkillTags,
      );

      await _service.submitReview(
        token: token,
        reviewId: reviewId,
        request: request,
      );

      _submitting = false;
      notifyListeners();
      return true;
    } on ReviewServiceException catch (e) {
      _error = e.message;
      _submitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Unexpected error submitting review.';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Loads all published reviews for a freelancer profile page.
  Future<void> loadFreelancerReviews({
    required String token,
    required String freelancerId,
  }) async {
    _reviewsState = ReviewLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      _reviews = await _service.getFreelancerReviews(
        token: token,
        freelancerId: freelancerId,
      );
      _reviewsState = ReviewLoadState.loaded;
    } on ReviewServiceException catch (e) {
      _error = e.message;
      _reviewsState = ReviewLoadState.error;
    } catch (e) {
      _error = 'Unexpected error loading reviews.';
      _reviewsState = ReviewLoadState.error;
    }
    notifyListeners();
  }

  /// Loads the AI-computed trust score for a freelancer.
  Future<void> loadTrustScore({
    required String token,
    required String freelancerId,
  }) async {
    _trustState = ReviewLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      _trustScore = await _service.getTrustScore(
        token: token,
        freelancerId: freelancerId,
      );
      _trustState = ReviewLoadState.loaded;
    } on ReviewServiceException catch (e) {
      _error = e.message;
      _trustState = ReviewLoadState.error;
    } catch (e) {
      _error = 'Unexpected error loading trust score.';
      _trustState = ReviewLoadState.error;
    }
    notifyListeners();
  }

  /// Loads unresolved red flag alerts (admin use).
  Future<void> loadRedFlags({
    required String token,
    required String freelancerId,
  }) async {
    _flagsState = ReviewLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      _redFlags = await _service.getRedFlags(
        token: token,
        freelancerId: freelancerId,
      );
      _flagsState = ReviewLoadState.loaded;
    } on ReviewServiceException catch (e) {
      _error = e.message;
      _flagsState = ReviewLoadState.error;
    } catch (e) {
      _error = 'Unexpected error loading red flags.';
      _flagsState = ReviewLoadState.error;
    }
    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void resetForm() {
    _pendingReview = null;
    _formState = ReviewLoadState.idle;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
