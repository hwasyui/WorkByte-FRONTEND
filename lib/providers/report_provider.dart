import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  List<String> _reasons = [];
  ReportModel? _lastSubmitted;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  List<String> get reasons => _reasons;
  ReportModel? get lastSubmitted => _lastSubmitted;

  /// Fetches predefined reasons. Skips the network call if already loaded.
  Future<void> fetchReasons(String token) async {
    if (_reasons.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reasons = await _service.getReportReasons(token);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Returns true on success, false on failure (read [error] for the message).
  Future<bool> submitReport({
    required String token,
    required String reportedType,
    String? reportedUserId,
    String? jobPostId,
    required List<String> selectedReasons,
    String? customReason,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      _lastSubmitted = await _service.createReport(
        token: token,
        reportedType: reportedType,
        reportedUserId: reportedUserId,
        jobPostId: jobPostId,
        reasons: selectedReasons,
        customReason: customReason,
      );

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

  /// Reset transient state when the report sheet is dismissed.
  void reset() {
    _error = null;
    _lastSubmitted = null;
    notifyListeners();
  }
}
