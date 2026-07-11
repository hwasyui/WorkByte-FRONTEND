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

  // Enriched fields — populated separately via profile fetch
  final String? freelancerName;
  final String? freelancerAvatarUrl;

  /// 'scanning' | 'visible' | 'blocked' - see proposal_functions.py's
  /// run_proposal_scan(). Defaults to 'visible' when absent so entries that
  /// predate this field (or come from a stripped-down response) don't get
  /// mistaken for pending/blocked.
  final String moderationStatus;

  /// Raw label keys (e.g. 'toxic', 'insult') from the backend's `detected_labels`
  /// JSONB column - see harmful_text.md section 17. Empty unless
  /// moderationStatus is 'blocked'.
  final List<String> detectedLabels;

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
    this.moderationStatus = 'visible',
    this.detectedLabels = const [],
  });

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
    moderationStatus: json['moderation_status'] as String? ?? 'visible',
    detectedLabels: (json['detected_labels'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
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
    moderationStatus: moderationStatus,
    detectedLabels: detectedLabels,
    freelancerName: freelancerName ?? this.freelancerName,
    freelancerAvatarUrl: freelancerAvatarUrl ?? this.freelancerAvatarUrl,
  );
}
