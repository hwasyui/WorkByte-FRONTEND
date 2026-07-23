import 'package:flutter/material.dart';
import '../models/guideline_ack_model.dart';
import '../services/guideline_service.dart';

class GuidelineProvider extends ChangeNotifier {
  final GuidelineService _service = GuidelineService();

  GuidelineAckStatus? _status;
  bool _isLoading = false;
  String? _error;

  GuidelineAckStatus? get status => _status;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Sections (among 'general' + [activeRole]) that this user hasn't
  /// acknowledged yet. Returns empty list until [fetchStatus] has resolved.
  List<String> pendingSections(String activeRole) {
    final s = _status;
    if (s == null) return [];

    final pending = <String>[];
    if (!s.general) pending.add('general');
    if (activeRole == 'client' && !s.client) pending.add('client');
    if (activeRole == 'freelancer' && !s.freelancer) pending.add('freelancer');
    return pending;
  }

  Future<void> fetchStatus({
    required String token,
    required String userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _status = await _service.getAckStatus(token: token, userId: userId);
    } catch (e) {
      // Fail silent — a network hiccup shouldn't block the user from using
      // the app, it just means the prompt won't show this time.
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('GuidelineProvider.fetchStatus failed: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> acknowledge({
    required String token,
    required String userId,
    required List<String> sections,
  }) async {
    for (final section in sections) {
      try {
        _status = await _service.ackSection(
          token: token,
          userId: userId,
          section: section,
        );
      } catch (e) {
        _error = e.toString().replaceFirst('Exception: ', '');
        debugPrint('GuidelineProvider.acknowledge($section) failed: $_error');
      }
    }
    notifyListeners();
  }
}
