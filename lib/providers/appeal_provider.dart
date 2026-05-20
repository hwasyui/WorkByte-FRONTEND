import 'package:flutter/material.dart';
import '../models/appeal_model.dart';
import '../services/appeal_service.dart';

class AppealProvider extends ChangeNotifier {
  final AppealService _service = AppealService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  List<AppealModel> _myAppeals = [];
  AppealModel? _lastSubmitted;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  List<AppealModel> get myAppeals => _myAppeals;
  AppealModel? get lastSubmitted => _lastSubmitted;

  // Convenience filtered getters
  List<AppealModel> get pendingAppeals =>
      _myAppeals.where((a) => a.status == 'pending').toList();
  List<AppealModel> get resolvedAppeals =>
      _myAppeals.where((a) => a.status != 'pending').toList();
  List<AppealModel> get accountAppeals =>
      _myAppeals.where((a) => a.targetType == 'user').toList();

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
