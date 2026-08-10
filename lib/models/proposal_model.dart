class ProposalModel {
  final String proposalId;
  final String jobPostId;
  final String? jobRoleId;
  final String freelancerId;
  final String coverLetter;
  final double proposedBudget;
  final String? proposedDuration;
  final String status;
  final bool isAiGenerated;
  final String? submittedAt;

  final String? freelancerName;
  final String? freelancerAvatarUrl;
  final double? freelancerRating;
  final int? freelancerReviewCount;
  final String? freelancerTitle;

  /// How well this bid fits the role, 0-100. Null until the backend has
  /// embedded both the freelancer and the role, so it is never a "zero fit".
  final int? relevanceScore;
  final String? relevanceMethod;

  /// False means the score above has not been computed yet and must not be
  /// presented as a ranking. Absent in older responses, which only ever
  /// carried ready scores, so it defaults to true.
  final bool relevanceReady;
  final double? vectorSimilarity;

  /// Snapshot of the role this bid was made against, sent alongside the
  /// proposal so a list can be labelled without resolving roles separately.
  final String? roleTitle;
  final double? roleBudget;
  final String? roleBudgetCurrency;
  final int? roleDisplayOrder;

  const ProposalModel({
    required this.proposalId,
    required this.jobPostId,
    this.jobRoleId,
    required this.freelancerId,
    required this.coverLetter,
    required this.proposedBudget,
    this.proposedDuration,
    this.status = 'pending',
    this.isAiGenerated = false,
    this.submittedAt,
    this.freelancerName,
    this.freelancerAvatarUrl,
    this.freelancerRating,
    this.freelancerReviewCount,
    this.freelancerTitle,
    this.relevanceScore,
    this.relevanceMethod,
    this.relevanceReady = true,
    this.vectorSimilarity,
    this.roleTitle,
    this.roleBudget,
    this.roleBudgetCurrency,
    this.roleDisplayOrder,
  });

  /// True only when there is a score that is safe to show as a ranking.
  bool get hasRelevance => relevanceReady && relevanceScore != null;

  factory ProposalModel.fromJson(Map<String, dynamic> json) => ProposalModel(
    proposalId: json['proposal_id'] as String? ?? '',
    jobPostId: json['job_post_id'] as String? ?? '',
    jobRoleId: json['job_role_id'] as String?,
    freelancerId: json['freelancer_id'] as String? ?? '',
    coverLetter: json['cover_letter'] as String? ?? '',
    proposedBudget: (json['proposed_budget'] as num?)?.toDouble() ?? 0,
    proposedDuration: json['proposed_duration'] as String?,
    status: json['status'] as String? ?? 'pending',
    isAiGenerated: json['is_ai_generated'] as bool? ?? false,
    submittedAt: json['submitted_at']?.toString(),
    freelancerName: json['freelancer_name'] as String?,
    freelancerAvatarUrl: json['profile_picture_url'] as String?,
    freelancerRating: (json['freelancer_rating'] as num?)?.toDouble(),
    freelancerReviewCount: (json['freelancer_review_count'] as num?)?.toInt(),
    freelancerTitle: json['freelancer_title'] as String?,
    relevanceScore: (json['relevance_score'] as num?)?.toInt(),
    relevanceMethod: json['relevance_method'] as String?,
    relevanceReady: json['relevance_ready'] as bool? ?? true,
    vectorSimilarity: (json['vector_similarity'] as num?)?.toDouble(),
    roleTitle: json['role_title'] as String?,
    roleBudget: (json['role_budget'] as num?)?.toDouble(),
    roleBudgetCurrency: json['role_budget_currency'] as String?,
    roleDisplayOrder: (json['role_display_order'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'job_post_id': jobPostId,
    if (jobRoleId != null) 'job_role_id': jobRoleId,
    'freelancer_id': freelancerId,
    'cover_letter': coverLetter,
    'proposed_budget': proposedBudget,
    if (proposedDuration != null) 'proposed_duration': proposedDuration,
    'status': status,
    'is_ai_generated': isAiGenerated,
  };

  ProposalModel copyWith({
    String? freelancerName,
    String? freelancerAvatarUrl,
    String? status,
  }) => ProposalModel(
    proposalId: proposalId,
    jobPostId: jobPostId,
    jobRoleId: jobRoleId,
    freelancerId: freelancerId,
    coverLetter: coverLetter,
    proposedBudget: proposedBudget,
    proposedDuration: proposedDuration,
    status: status ?? this.status,
    isAiGenerated: isAiGenerated,
    submittedAt: submittedAt,
    freelancerName: freelancerName ?? this.freelancerName,
    freelancerAvatarUrl: freelancerAvatarUrl ?? this.freelancerAvatarUrl,
    freelancerRating: freelancerRating,
    freelancerReviewCount: freelancerReviewCount,
    freelancerTitle: freelancerTitle,
    relevanceScore: relevanceScore,
    relevanceMethod: relevanceMethod,
    relevanceReady: relevanceReady,
    vectorSimilarity: vectorSimilarity,
    roleTitle: roleTitle,
    roleBudget: roleBudget,
    roleBudgetCurrency: roleBudgetCurrency,
    roleDisplayOrder: roleDisplayOrder,
  );
}
