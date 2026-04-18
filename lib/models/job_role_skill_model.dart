class JobRoleSkillModel {
  final String jobRoleSkillId;
  final String jobRoleId;
  final String skillId;
  final bool isRequired;
  final String? importanceLevel;
  final String? createdAt;

  const JobRoleSkillModel({
    required this.jobRoleSkillId,
    required this.jobRoleId,
    required this.skillId,
    this.isRequired = true,
    this.importanceLevel,
    this.createdAt,
  });

  factory JobRoleSkillModel.fromJson(Map<String, dynamic> json) =>
      JobRoleSkillModel(
        jobRoleSkillId: json['job_role_skill_id'] as String? ?? '',
        jobRoleId: json['job_role_id'] as String? ?? '',
        skillId: json['skill_id'] as String? ?? '',
        isRequired: json['is_required'] as bool? ?? true,
        importanceLevel: json['importance_level'] as String?,
        createdAt: json['created_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
    'job_role_id': jobRoleId,
    'skill_id': skillId,
    'is_required': isRequired,
    if (importanceLevel != null) 'importance_level': importanceLevel,
  };
}
