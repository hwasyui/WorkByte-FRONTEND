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
  final List<String> matchReasons;
  final List<String> penaltyReasons;
  final String? clientName;

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
    this.matchReasons = const [],
    this.penaltyReasons = const [],
    this.clientName,
  });

  factory AIJobMatchModel.fromJson(Map<String, dynamic> json) {
    List<String> parseLabels(dynamic raw) {
      if (raw == null) return const [];
      return (raw as List)
          .map((r) => (r as Map<String, dynamic>)['label']?.toString() ?? '')
          .where((l) => l.isNotEmpty)
          .toList();
    }

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
      matchReasons: parseLabels(json['match_reasons']),
      penaltyReasons: parseLabels(json['penalty_reasons']),
      clientName: json['client_name']?.toString() ??
          json['company_name']?.toString() ??
          json['client_display_name']?.toString(),
    );
  }

  int get matchScoreInt => matchProbability.round();
}
