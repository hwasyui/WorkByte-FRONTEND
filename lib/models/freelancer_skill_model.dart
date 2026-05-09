import 'skill_model.dart';

class FreelancerSkillModel {
  final String freelancerSkillId;
  final String freelancerId;
  final String skillId;
  final String proficiencyLevel;
  final String? skillName;
  final String? skillCategory;
  final String? createdAt;

  const FreelancerSkillModel({
    required this.freelancerSkillId,
    required this.freelancerId,
    required this.skillId,
    required this.proficiencyLevel,
    this.skillName,
    this.skillCategory,
    this.createdAt,
  });

  factory FreelancerSkillModel.fromJson(Map<String, dynamic> json) {
    return FreelancerSkillModel(
      freelancerSkillId: (json['freelancer_skill_id'] ?? '').toString(),
      freelancerId: (json['freelancer_id'] ?? '').toString(),
      skillId: (json['skill_id'] ?? '').toString(),
      proficiencyLevel: (json['proficiency_level'] ?? 'beginner').toString(),
      skillName: json['skill_name']?.toString(),
      skillCategory: json['skill_category']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'freelancer_skill_id': freelancerSkillId,
    'freelancer_id': freelancerId,
    'skill_id': skillId,
    'proficiency_level': proficiencyLevel,
    'skill_name': skillName,
    'skill_category': skillCategory,
    'created_at': createdAt,
  };

  SkillModel? get skill {
    if (skillName == null) return null;
    return SkillModel(
      skillId: skillId,
      skillName: skillName!,
      skillCategory: skillCategory,
      description: null,
    );
  }

  FreelancerSkillModel copyWith({
    String? freelancerSkillId,
    String? freelancerId,
    String? skillId,
    String? proficiencyLevel,
    String? skillName,
    String? skillCategory,
    String? createdAt,
  }) {
    return FreelancerSkillModel(
      freelancerSkillId: freelancerSkillId ?? this.freelancerSkillId,
      freelancerId: freelancerId ?? this.freelancerId,
      skillId: skillId ?? this.skillId,
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
      skillName: skillName ?? this.skillName,
      skillCategory: skillCategory ?? this.skillCategory,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
