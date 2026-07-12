import 'package:flutter/foundation.dart';
import '../models/client_review_model.dart';
import '../models/review_model.dart' show RedFlagAlert;
import '../services/client_review_service.dart';

enum ClientReviewLoadState { idle, loading, loaded, error }

/// Freelancer-reviews-client provider - mirrors ReviewProvider's structure
/// for the symmetric counterpart.
class ClientReviewProvider extends ChangeNotifier {
  final ClientReviewService _service = ClientReviewService();

  // ── Review form (pending review for a contract) ──────────────────────────

  ClientReviewLoadState _formState = ClientReviewLoadState.idle;
  ClientReviewLoadState get formState => _formState;

  ClientReview? _pendingReview;
  ClientReview? get pendingReview => _pendingReview;

  bool _submitting = false;
  bool get submitting => _submitting;

  // ── Client reviews list ───────────────────────────────────────────────────

  ClientReviewLoadState _reviewsState = ClientReviewLoadState.idle;
  ClientReviewLoadState get reviewsState => _reviewsState;

  List<ClientReview> _reviews = [];
  List<ClientReview> get reviews => List.unmodifiable(_reviews);

  // ── Trust score ────────────────────────────────────────────────────────────

  ClientReviewLoadState _trustState = ClientReviewLoadState.idle;
  ClientReviewLoadState get trustState => _trustState;

  ClientTrustScore? _trustScore;
  ClientTrustScore? get trustScore => _trustScore;

  // ── Red flags ────────────────────────────────────────────────────────────

  ClientReviewLoadState _flagsState = ClientReviewLoadState.idle;
  ClientReviewLoadState get flagsState => _flagsState;

  List<RedFlagAlert> _redFlags = [];
  List<RedFlagAlert> get redFlags => List.unmodifiable(_redFlags);

  String? _error;
  String? get error => _error;

  // Raw moderation labels (e.g. "toxic", "obscene") from the harmful-content
  // gate on submitReview - null unless the last submit attempt was rejected
  // for that specific reason, so the UI can special-case that error state.
  List<String>? _flaggedLabels;
  List<String>? get flaggedLabels => _flaggedLabels;

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> loadReviewForm({
    required String token,
    required String contractId,
  }) async {
    _formState = ClientReviewLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      _pendingReview = await _service.getClientReviewForContract(
        token: token,
        contractId: contractId,
      );
      _formState = ClientReviewLoadState.loaded;
    } on ClientReviewServiceException catch (e) {
      _error = e.message;
      _formState = ClientReviewLoadState.error;
    } catch (e) {
      _error = 'Unexpected error loading review form.';
      _formState = ClientReviewLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> submitReview({
    required String token,
    required String clientReviewId,
    required Map<String, double> ratingsMap,
    required String freelancerAnswer,
    required String overallComment,
  }) async {
    _submitting = true;
    _error = null;
    _flaggedLabels = null;
    notifyListeners();

    try {
      final request = SubmitClientReviewRequest(
        ratings: ratingsMap.entries
            .map(
              (e) => ClientReviewRatingInput(category: e.key, score: e.value),
            )
            .toList(),
        freelancerAnswer: freelancerAnswer,
        overallComment: overallComment,
      );

      await _service.submitClientReview(
        token: token,
        clientReviewId: clientReviewId,
        request: request,
      );

      _submitting = false;
      notifyListeners();
      return true;
    } on ClientReviewServiceException catch (e) {
      _error = e.message;
      _flaggedLabels = e.detectedLabels;
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

  Future<void> loadClientReviews({
    required String token,
    required String clientId,
  }) async {
    _reviewsState = ClientReviewLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      _reviews = await _service.getClientReviews(
        token: token,
        clientId: clientId,
      );
      _reviewsState = ClientReviewLoadState.loaded;
    } on ClientReviewServiceException catch (e) {
      _error = e.message;
      _reviewsState = ClientReviewLoadState.error;
    } catch (e) {
      _error = 'Unexpected error loading reviews.';
      _reviewsState = ClientReviewLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadTrustScore({
    required String token,
    required String clientId,
  }) async {
    _trustState = ClientReviewLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      _trustScore = await _service.getClientTrustScore(
        token: token,
        clientId: clientId,
      );
      _trustState = ClientReviewLoadState.loaded;
    } on ClientReviewServiceException catch (e) {
      _error = e.message;
      _trustState = ClientReviewLoadState.error;
    } catch (e) {
      _error = 'Unexpected error loading trust score.';
      _trustState = ClientReviewLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadRedFlags({
    required String token,
    required String clientId,
  }) async {
    _flagsState = ClientReviewLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      _redFlags = await _service.getClientRedFlags(
        token: token,
        clientId: clientId,
      );
      _flagsState = ClientReviewLoadState.loaded;
    } on ClientReviewServiceException catch (e) {
      _error = e.message;
      _flagsState = ClientReviewLoadState.error;
    } catch (e) {
      _error = 'Unexpected error loading red flags.';
      _flagsState = ClientReviewLoadState.error;
    }
    notifyListeners();
  }

  void resetForm() {
    _pendingReview = null;
    _formState = ClientReviewLoadState.idle;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
