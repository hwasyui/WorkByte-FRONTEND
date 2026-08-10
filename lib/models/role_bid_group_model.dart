import 'proposal_model.dart';

/// One role's slice of a job post's bids, as returned by
/// `GET /proposals/job-post/{id}/by-role`.
///
/// A group is the only scope where `relevance_score` is comparable between
/// proposals — the embedding and skills that produce it live on the role, not
/// the post — so the backend sorts each group independently and the client
/// renders them as separate sections rather than one merged list.
class RoleBidGroup {
  final String jobRoleId;
  final String roleTitle;
  final double? roleBudget;
  final String? budgetCurrency;
  final int positionsOpen;
  final int proposalCount;

  /// How many of [proposals] actually carry a usable relevance score.
  final int rankedCount;

  /// Already sorted by the backend. Empty for roles that have no bids yet —
  /// those roles are still returned so the client can show them as open.
  final List<ProposalModel> proposals;

  const RoleBidGroup({
    required this.jobRoleId,
    required this.roleTitle,
    this.roleBudget,
    this.budgetCurrency,
    this.positionsOpen = 0,
    this.proposalCount = 0,
    this.rankedCount = 0,
    this.proposals = const [],
  });

  factory RoleBidGroup.fromJson(Map<String, dynamic> json) => RoleBidGroup(
    jobRoleId: json['job_role_id'] as String? ?? '',
    roleTitle: json['role_title'] as String? ?? '',
    roleBudget: (json['role_budget'] as num?)?.toDouble(),
    budgetCurrency: json['budget_currency'] as String?,
    positionsOpen: (json['positions_open'] as num?)?.toInt() ?? 0,
    proposalCount: (json['proposal_count'] as num?)?.toInt() ?? 0,
    rankedCount: (json['ranked_count'] as num?)?.toInt() ?? 0,
    proposals: ((json['proposals'] as List?) ?? const [])
        .map((e) => ProposalModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  RoleBidGroup copyWith({List<ProposalModel>? proposals}) => RoleBidGroup(
    jobRoleId: jobRoleId,
    roleTitle: roleTitle,
    roleBudget: roleBudget,
    budgetCurrency: budgetCurrency,
    positionsOpen: positionsOpen,
    proposalCount: proposalCount,
    rankedCount: rankedCount,
    proposals: proposals ?? this.proposals,
  );
}
