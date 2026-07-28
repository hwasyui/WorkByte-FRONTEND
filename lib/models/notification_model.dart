import '../core/utils/moderation_display.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        // Notification bodies are written by the backend and rendered verbatim.
        // Stripping any classifier category here rather than at each render site
        // means no screen can surface one by accident, even if the backend copy
        // regresses. See core/utils/moderation_display.dart.
        body: redactModerationLabels(json['body'] as String),
        data: (json['data'] is Map)
            ? Map<String, dynamic>.from(json['data'] as Map)
            : {},
        isRead: json['is_read'] as bool? ?? false,
        createdAt:
            DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      );

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id,
    type: type,
    title: title,
    body: body,
    data: data,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
}
