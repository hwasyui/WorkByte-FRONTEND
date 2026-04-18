class SkillModel {
  final String skillId;
  final String skillName;
  final String? skillCategory;
  final String? description;

  const SkillModel({
    required this.skillId,
    required this.skillName,
    this.skillCategory,
    this.description,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      skillId: json['skill_id'] as String,
      skillName: json['skill_name'] as String,
      skillCategory: json['skill_category'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'skill_id': skillId,
    'skill_name': skillName,
    'skill_category': skillCategory,
    'description': description,
  };
}
