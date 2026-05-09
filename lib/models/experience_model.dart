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
