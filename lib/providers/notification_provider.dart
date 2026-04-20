import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  bool _isLoading = false;
  String? _error;
  List<NotificationModel> _notifications = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.getNotifications(token);
      _notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markAsRead(String token, String notificationId) async {
    try {
      await _service.markAsRead(token, notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> createNotification(
    String token,
    String userId,
    String title,
    String message,
    String type, {
    Map<String, dynamic>? data,
  }) async {
    try {
      await _service.createNotification(token, userId, title, message, type, data: data);
      // Refresh notifications after creating
      await fetchNotifications(token);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}