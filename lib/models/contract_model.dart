class ContractModel {
  final String contractId;
  final String jobPostId;
  final String? jobRoleId;
  final String? proposalId;
  final String freelancerId;
  final String clientId;
  final String contractTitle;
  final String roleTitle;
  final double agreedBudget;
  final String budgetCurrency;
  final String status;
  final String? startDate;
  final String? endDate;
  final String? agreedDuration;
  final String? actualCompletionDate;
  final double? totalHoursWorked;
  final double? totalPaid;
  final String? contractPdfUrl;
  final String? contractPdfGeneratedAt;
  final String? createdAt;
  final String? updatedAt;

  /// user_id of whoever cancelled, or of the admin who cancelled as the outcome
  /// of an arbitration. Empty when the contract was never cancelled.
  final String? cancelledBy;
  final String? cancellationReason;

  final String? freelancerName;
  final String? clientName;

  final double? commissionRate;
  final double? commissionAmount;
  final double? payoutAmount;
  final String? freelancerConfirmedReceiptAt;
  final String? paymentVerifiedAt;
  final String? paymentVerifiedBy;
  final bool completedByAdminOverride;

  const ContractModel({
    required this.contractId,
    required this.jobPostId,
    this.jobRoleId,
    this.proposalId,
    required this.freelancerId,
    required this.clientId,
    required this.contractTitle,
    required this.roleTitle,
    required this.agreedBudget,
    required this.budgetCurrency,
    this.status = 'pending',
    this.startDate,
    this.endDate,
    this.agreedDuration,
    this.actualCompletionDate,
    this.totalHoursWorked,
    this.totalPaid,
    this.contractPdfUrl,
    this.contractPdfGeneratedAt,
    this.createdAt,
    this.updatedAt,
    this.cancelledBy,
    this.cancellationReason,
    this.freelancerName,
    this.clientName,
    this.commissionRate,
    this.commissionAmount,
    this.payoutAmount,
    this.freelancerConfirmedReceiptAt,
    this.paymentVerifiedAt,
    this.paymentVerifiedBy,
    this.completedByAdminOverride = false,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) => ContractModel(
    contractId: json['contract_id'] as String? ?? '',
    jobPostId: json['job_post_id'] as String? ?? '',
    jobRoleId: json['job_role_id'] as String?,
    proposalId: json['proposal_id'] as String?,
    freelancerId: json['freelancer_id'] as String? ?? '',
    clientId: json['client_id'] as String? ?? '',
    contractTitle: json['contract_title'] as String? ?? '',
    roleTitle: json['role_title'] as String? ?? '',
    agreedBudget: (json['agreed_budget'] as num?)?.toDouble() ?? 0.0,
    budgetCurrency: json['budget_currency'] as String? ?? 'USD',
    status: json['status'] as String? ?? 'pending',
    startDate: json['start_date']?.toString(),
    endDate: json['end_date']?.toString(),
    agreedDuration: json['agreed_duration'] as String?,
    actualCompletionDate: json['actual_completion_date']?.toString(),
    totalHoursWorked: (json['total_hours_worked'] as num?)?.toDouble(),
    totalPaid: (json['total_paid'] as num?)?.toDouble(),
    contractPdfUrl: json['contract_pdf_url'] as String?,
    contractPdfGeneratedAt: json['contract_pdf_generated_at']?.toString(),
    createdAt: json['created_at']?.toString(),
    updatedAt: json['updated_at']?.toString(),
    cancelledBy: json['cancelled_by']?.toString(),
    cancellationReason: json['cancellation_reason'] as String?,
    commissionRate: (json['commission_rate'] as num?)?.toDouble(),
    commissionAmount: (json['commission_amount'] as num?)?.toDouble(),
    payoutAmount: (json['payout_amount'] as num?)?.toDouble(),
    freelancerConfirmedReceiptAt:
        json['freelancer_confirmed_receipt_at']?.toString(),
    paymentVerifiedAt: json['payment_verified_at']?.toString(),
    paymentVerifiedBy: json['payment_verified_by']?.toString(),
    completedByAdminOverride:
        json['completed_by_admin_override'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'job_post_id': jobPostId,
    if (jobRoleId != null) 'job_role_id': jobRoleId,
    if (proposalId != null) 'proposal_id': proposalId,
    'freelancer_id': freelancerId,
    'client_id': clientId,
    'contract_title': contractTitle,
    'role_title': roleTitle,
    'agreed_budget': agreedBudget,
    'budget_currency': budgetCurrency,
    'status': status,
    if (startDate != null) 'start_date': startDate,
    if (endDate != null) 'end_date': endDate,
    if (agreedDuration != null) 'agreed_duration': agreedDuration,
  };

  ContractModel copyWith({
    String? status,
    String? contractPdfUrl,
    String? contractPdfGeneratedAt,
    String? endDate,
    String? agreedDuration,
    String? freelancerName,
    String? clientName,
    String? cancelledBy,
    String? cancellationReason,
  }) => ContractModel(
    contractId: contractId,
    jobPostId: jobPostId,
    jobRoleId: jobRoleId,
    proposalId: proposalId,
    freelancerId: freelancerId,
    clientId: clientId,
    contractTitle: contractTitle,
    roleTitle: roleTitle,
    agreedBudget: agreedBudget,
    budgetCurrency: budgetCurrency,
    status: status ?? this.status,
    startDate: startDate,
    endDate: endDate ?? this.endDate,
    agreedDuration: agreedDuration ?? this.agreedDuration,
    actualCompletionDate: actualCompletionDate,
    totalHoursWorked: totalHoursWorked,
    totalPaid: totalPaid,
    contractPdfUrl: contractPdfUrl ?? this.contractPdfUrl,
    contractPdfGeneratedAt: contractPdfGeneratedAt ?? this.contractPdfGeneratedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
    cancelledBy: cancelledBy ?? this.cancelledBy,
    cancellationReason: cancellationReason ?? this.cancellationReason,
    freelancerName: freelancerName ?? this.freelancerName,
    clientName: clientName ?? this.clientName,
    commissionRate: commissionRate,
    commissionAmount: commissionAmount,
    payoutAmount: payoutAmount,
    freelancerConfirmedReceiptAt: freelancerConfirmedReceiptAt,
    paymentVerifiedAt: paymentVerifiedAt,
    paymentVerifiedBy: paymentVerifiedBy,
    completedByAdminOverride: completedByAdminOverride,
  );
}
