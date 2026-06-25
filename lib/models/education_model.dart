// education_model.dart
class EducationModel {
  final String educationId;
  final String freelancerId;
  final String institutionName;
  final String degree;
  final String? fieldOfStudy;
  final String startDate;
  final String? endDate;
  final bool isCurrent;
  final String? grade;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EducationModel({
    required this.educationId,
    required this.freelancerId,
    required this.institutionName,
    required this.degree,
    this.fieldOfStudy,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.grade,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory EducationModel.fromJson(Map<String, dynamic> json) => EducationModel(
    educationId: json['education_id'] as String,
    freelancerId: json['freelancer_id'] as String,
    institutionName: json['institution_name'] as String? ?? '',
    degree: json['degree'] as String? ?? '',
    fieldOfStudy: json['field_of_study'] as String?,
    startDate: json['start_date'].toString(),
    endDate: json['end_date']?.toString(),
    isCurrent: json['is_current'] as bool? ?? false,
    grade: json['grade'] as String?,
    description: json['description'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'].toString())
        : null,
  );

  Map<String, dynamic> toJson() => {
    'education_id': educationId,
    'freelancer_id': freelancerId,
    'institution_name': institutionName,
    'degree': degree,
    'field_of_study': fieldOfStudy,
    'start_date': startDate,
    'end_date': endDate,
    'is_current': isCurrent,
    'grade': grade,
    'description': description,
  };
}
