class AppealModel {
  final String appealId;
  final String userId;
  final String targetType;
  final String targetId;
  final String message;
  final String status;
  final String? adminNote;
  final String? jobTitle;
  final int appealAttempt;
  final DateTime createdAt;
  final DateTime? actionedAt;

  AppealModel({
    required this.appealId,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.message,
    required this.status,
    this.adminNote,
    this.jobTitle,
    this.appealAttempt = 1,
    required this.createdAt,
    this.actionedAt,
  });

  factory AppealModel.fromJson(Map<String, dynamic> json) {
    return AppealModel(
      appealId: json['appeal_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      targetType: json['target_type']?.toString() ?? '',
      targetId: json['target_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      adminNote: json['admin_note']?.toString(),
      jobTitle: json['job_title']?.toString(),
      appealAttempt: (json['appeal_attempt'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      actionedAt: json['actioned_at'] != null
          ? DateTime.tryParse(json['actioned_at'].toString())
          : null,
    );
  }
}
