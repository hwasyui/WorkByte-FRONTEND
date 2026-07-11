// experience_model.dart
class ExperienceModel {
  final String workExperienceId;
  final String freelancerId;
  final String jobTitle;
  final String companyName;
  final String? location;
  final String startDate;
  final String? endDate;
  final bool isCurrent;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// 'scanning' | 'visible' | 'blocked' - see work_experience_functions.py's
  /// run_work_experience_scan(). Defaults to 'visible' when absent so entries
  /// that predate this field don't get mistaken for pending/blocked.
  final String moderationStatus;

  /// Raw label keys (e.g. 'toxic', 'insult') from the backend's `detected_labels`
  /// JSONB column - see harmful_text.md section 17. Empty unless moderationStatus
  /// is 'blocked'. Not human-readable; map via labelDisplayName() before showing.
  final List<String> detectedLabels;

  const ExperienceModel({
    required this.workExperienceId,
    required this.freelancerId,
    required this.jobTitle,
    required this.companyName,
    this.location,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.moderationStatus = 'visible',
    this.detectedLabels = const [],
  });

  factory ExperienceModel.fromJson(Map<String, dynamic> json) =>
      ExperienceModel(
        workExperienceId: json['work_experience_id'] as String,
        freelancerId: json['freelancer_id'] as String,
        jobTitle: json['job_title'] as String? ?? '',
        companyName: json['company_name'] as String? ?? '',
        location: json['location'] as String?,
        startDate: json['start_date'].toString(),
        endDate: json['end_date']?.toString(),
        isCurrent: json['is_current'] as bool? ?? false,
        description: json['description'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
        moderationStatus: json['moderation_status'] as String? ?? 'visible',
        detectedLabels: (json['detected_labels'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
    'work_experience_id': workExperienceId,
    'freelancer_id': freelancerId,
    'job_title': jobTitle,
    'company_name': companyName,
    'location': location,
    'start_date': startDate,
    'end_date': endDate,
    'is_current': isCurrent,
    'description': description,
  };
}
