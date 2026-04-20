class AIJobMatchModel {
  final String jobPostId;
  final String jobTitle;
  final String jobDescription;
  final String projectType;
  final String projectScope;
  final String? experienceLevel;
  final String? estimatedDuration;
  final String? deadline;
  final int proposalCount;
  final double similarityScore;
  final double matchProbability;
  final double skillOverlapPct;

  AIJobMatchModel({
    required this.jobPostId,
    required this.jobTitle,
    required this.jobDescription,
    required this.projectType,
    required this.projectScope,
    this.experienceLevel,
    this.estimatedDuration,
    this.deadline,
    required this.proposalCount,
    required this.similarityScore,
    required this.matchProbability,
    required this.skillOverlapPct,
  });

  factory AIJobMatchModel.fromJson(Map<String, dynamic> json) {
    return AIJobMatchModel(
      jobPostId: json['job_post_id']?.toString() ?? '',
      jobTitle: json['job_title']?.toString() ?? '',
      jobDescription: json['job_description']?.toString() ?? '',
      projectType: json['project_type']?.toString() ?? '',
      projectScope: json['project_scope']?.toString() ?? '',
      experienceLevel: json['experience_level']?.toString(),
      estimatedDuration: json['estimated_duration']?.toString(),
      deadline: json['deadline']?.toString(),
      proposalCount: (json['proposal_count'] as num?)?.toInt() ?? 0,
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0.0,
      matchProbability: (json['match_probability'] as num?)?.toDouble() ?? 0.0,
      skillOverlapPct: (json['skill_overlap_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }

  int get matchScoreInt => matchProbability.round();
}
