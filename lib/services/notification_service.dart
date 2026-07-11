import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

// Top-level background handler — must be outside any class
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in main.dart
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _tokenKey = 'auth_token';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'workbyte_channel',
    'WorkByte Notifications',
    description: 'WorkByte push notifications',
    importance: Importance.high,
  );

  // ── Init ──────────────────────────────────────────────────────────────────

  static Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    void Function({required String? type, required String? title, required String? body})?
    onForegroundMessage,
  }) async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set up local notifications for foreground display
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          _navigate(navigatorKey, data);
        }
      },
    );

    // Foreground messages — show local notification, and let the app react
    // live (refresh the unread badge, show a blocked-content banner) since
    // the OS won't show its own heads-up notification while the app is open.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: jsonEncode(message.data),
        );
      }
      onForegroundMessage?.call(
        type: message.data['type'] as String?,
        title: notification?.title,
        body: notification?.body,
      );
    });

    // Background tap — app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigate(navigatorKey, message.data);
    });

    // Terminated tap — app was closed
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _navigate(navigatorKey, initialMessage.data);
    }
  }

  // ── Deep link navigation on tap ───────────────────────────────────────────

  static void _navigate(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> data,
  ) {
    final type = data['type'] as String?;
    final context = navigatorKey.currentContext;
    if (type == null || context == null) return;

    switch (type) {
      case 'new_message':
        navigatorKey.currentState?.pushNamed(
          '/workspace',
          arguments: data['thread_id'],
        );
        break;
      case 'new_proposal':
        navigatorKey.currentState?.pushNamed(
          '/proposals',
          arguments: data['job_post_id'],
        );
        break;
      case 'proposal_accepted':
      case 'proposal_rejected':
        navigatorKey.currentState?.pushNamed(
          '/proposals',
          arguments: data['proposal_id'],
        );
        break;
      case 'contract_started':
      case 'contract_cancelled':
      case 'contract_completed':
      case 'work_submitted':
      case 'revision_requested':
        navigatorKey.currentState?.pushNamed(
          '/contract',
          arguments: data['contract_id'],
        );
        break;
      default:
        navigatorKey.currentState?.pushNamed('/notifications');
    }
  }

  // ── FCM Token ─────────────────────────────────────────────────────────────

  static Future<void> saveTokenToBackend() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final authToken = await _storage.read(key: _tokenKey);
      if (fcmToken == null || authToken == null) return;

      await http.put(
        Uri.parse('$_baseUrl/notifications/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': fcmToken}),
      );

      // Refresh token listener
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        final token = await _storage.read(key: _tokenKey);
        if (token == null) return;
        await http.put(
          Uri.parse('$_baseUrl/notifications/fcm-token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'token': newToken}),
        );
      });
    } catch (e) {
      debugPrint('Failed to save FCM token (non-fatal): $e');
    }
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<List<NotificationModel>> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    final token = await _storage.read(key: _tokenKey);
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications?limit=$limit&offset=$offset'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final list = body['details'] ?? body['data'] ?? [];
      return (list as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['details']?.toString() ?? 'Failed to fetch notifications');
  }

  Future<int> getUnreadCount() async {
    final token = await _storage.read(key: _tokenKey);
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications/unread-count'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final data = body['details'] ?? body['data'] ?? body;
      return data['count'] as int? ?? 0;
    }
    throw Exception('Failed to fetch unread count');
  }

  Future<void> markAsRead(String notificationId) async {
    final token = await _storage.read(key: _tokenKey);
    await http.patch(
      Uri.parse('$_baseUrl/notifications/$notificationId/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<void> markAllRead() async {
    final token = await _storage.read(key: _tokenKey);
    await http.patch(
      Uri.parse('$_baseUrl/notifications/read-all'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
}
