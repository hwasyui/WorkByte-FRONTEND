class JobRoleModel {
  final String jobRoleId;
  final String jobPostId;
  final String roleTitle;
  final double? roleBudget;
  final String budgetCurrency;
  final String budgetType;
  final String? roleDescription;
  final int positionsAvailable;
  final int positionsFilled;
  final bool isRequired;
  final int displayOrder;

  const JobRoleModel({
    required this.jobRoleId,
    required this.jobPostId,
    required this.roleTitle,
    this.roleBudget,
    this.budgetCurrency = 'USD',
    required this.budgetType,
    this.roleDescription,
    this.positionsAvailable = 1,
    this.positionsFilled = 0,
    this.isRequired = true,
    this.displayOrder = 0,
  });

  factory JobRoleModel.fromJson(Map<String, dynamic> json) => JobRoleModel(
    jobRoleId: json['job_role_id'] as String? ?? '',
    jobPostId: json['job_post_id'] as String? ?? '',
    roleTitle: json['role_title'] as String? ?? '',
    roleBudget: (json['role_budget'] as num?)?.toDouble(),
    budgetCurrency: json['budget_currency'] as String? ?? 'USD',
    budgetType: json['budget_type'] as String? ?? 'fixed',
    roleDescription: json['role_description'] as String?,
    positionsAvailable: (json['positions_available'] as num?)?.toInt() ?? 1,
    positionsFilled: (json['positions_filled'] as num?)?.toInt() ?? 0,
    isRequired: json['is_required'] as bool? ?? true,
    displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'job_post_id': jobPostId,
    'role_title': roleTitle,
    if (roleBudget != null) 'role_budget': roleBudget,
    'budget_currency': budgetCurrency,
    'budget_type': budgetType,
    if (roleDescription != null) 'role_description': roleDescription,
    'positions_available': positionsAvailable,
    'is_required': isRequired,
    'display_order': displayOrder,
  };
}
