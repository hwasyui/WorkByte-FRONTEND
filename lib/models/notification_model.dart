class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['notification_id'] as String,
    userId: json['user_id'] as String,
    title: json['title'] as String,
    message: json['message'] as String,
    type: json['type'] as String,
    data: json['data'] as Map<String, dynamic>?,
    isRead: json['is_read'] as bool? ?? false,
    readAt: json['read_at'] != null
        ? DateTime.tryParse(json['read_at'].toString())
        : null,
    createdAt: DateTime.parse(json['created_at'].toString()),
  );

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isContractApproval => type == 'contract_approval';
  String? get contractId => data?['contract_id'] as String?;
}