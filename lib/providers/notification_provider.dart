import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  static const int _pageSize = 20;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;

    if (refresh) {
      _notifications = [];
      _hasMore = true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _service.getNotifications(
        limit: _pageSize,
        offset: _notifications.length,
      );
      _notifications.addAll(results);
      _hasMore = results.length == _pageSize;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await _service.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  // ── Mark read ─────────────────────────────────────────────────────────────

  Future<void> markAsRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);
      _notifications = _notifications.map((n) {
        return n.id == notificationId ? n.copyWith(isRead: true) : n;
      }).toList();
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _service.markAllRead();
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  void clear() {
    _notifications = [];
    _unreadCount = 0;
    _isLoading = false;
    _hasMore = true;
    _error = null;
    notifyListeners();
  }
}
