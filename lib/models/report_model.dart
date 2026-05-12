class ReportModel {
  final String reportId;
  final String reporterId;
  final String? reportedUserId;
  final String? jobPostId;
  final String reportedType;
  final List<String> reasons;
  final String? customReason;
  final String status;
  final String? adminNote;
  final DateTime createdAt;

  ReportModel({
    required this.reportId,
    required this.reporterId,
    this.reportedUserId,
    this.jobPostId,
    required this.reportedType,
    required this.reasons,
    this.customReason,
    required this.status,
    this.adminNote,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reportId: json['report_id']?.toString() ?? '',
      reporterId: json['reporter_id']?.toString() ?? '',
      reportedUserId: json['reported_user_id']?.toString(),
      jobPostId: json['job_post_id']?.toString(),
      reportedType: json['reported_type']?.toString() ?? '',
      reasons: List<String>.from(json['reasons'] ?? []),
      customReason: json['custom_reason']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      adminNote: json['admin_note']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
