import 'package:flutter/material.dart';
import '../models/appeal_model.dart';
import '../services/appeal_service.dart';

class AppealProvider extends ChangeNotifier {
  final AppealService _service = AppealService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isCheckingStatus = false;
  String? _error;
  List<AppealModel> _myAppeals = [];
  AppealModel? _lastSubmitted;
  Map<String, dynamic> _appealStatus = {};

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isCheckingStatus => _isCheckingStatus;
  String? get error => _error;
  List<AppealModel> get myAppeals => _myAppeals;
  AppealModel? get lastSubmitted => _lastSubmitted;
  Map<String, dynamic> get appealStatus => _appealStatus;

  // Convenience filtered getters
  List<AppealModel> get pendingAppeals =>
      _myAppeals.where((a) => a.status == 'pending').toList();
  List<AppealModel> get resolvedAppeals =>
      _myAppeals.where((a) => a.status != 'pending').toList();
  List<AppealModel> get accountAppeals =>
      _myAppeals.where((a) => a.targetType == 'user').toList();

  /// Get appeal status for a specific target
  /// Returns remaining appeals attempts, current state, etc.
  Future<void> fetchAppealStatus({
    required String token,
    required String targetType,
    required String targetId,
  }) async {
    _isCheckingStatus = true;
    _error = null;
    notifyListeners();

    try {
      _appealStatus = await _service.getAppealStatus(
        token: token,
        targetType: targetType,
        targetId: targetId,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _appealStatus = {};
    }

    _isCheckingStatus = false;
    notifyListeners();
  }

  Future<void> fetchMyAppeals(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myAppeals = await _service.getMyAppeals(token);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Submits appeal and optimistically prepends it to [myAppeals].
  /// Returns true on success, false on failure (read [error] for the message).
  Future<bool> submitAppeal({
    required String token,
    required String targetType,
    required String targetId,
    required String message,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      _lastSubmitted = await _service.submitAppeal(
        token: token,
        targetType: targetType,
        targetId: targetId,
        message: message,
      );

      // Optimistic insert — no need for a separate fetchMyAppeals call
      _myAppeals = [_lastSubmitted!, ..._myAppeals];

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset transient state when the appeal dialog is dismissed.
  void reset() {
    _error = null;
    _lastSubmitted = null;
    notifyListeners();
  }
}
