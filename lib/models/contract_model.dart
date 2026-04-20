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
  final String paymentStructure;
  final String status;
  final String? startDate;
  final String? endDate;
  final String? agreedDuration;
  final String? actualCompletionDate;
  final int? totalHoursWorked;
  final double? totalPaid;
  final String? contractPdfUrl;
  final String? contractPdfGeneratedAt;
  final String? createdAt;
  final String? updatedAt;

  // Enriched fields
  final String? freelancerName;
  final String? clientName;

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
    required this.paymentStructure,
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
    this.freelancerName,
    this.clientName,
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
    paymentStructure: json['payment_structure'] as String? ?? 'fixed',
    status: json['status'] as String? ?? 'pending',
    startDate: json['start_date']?.toString(),
    endDate: json['end_date']?.toString(),
    agreedDuration: json['agreed_duration'] as String?,
    actualCompletionDate: json['actual_completion_date']?.toString(),
    totalHoursWorked: json['total_hours_worked'] as int?,
    totalPaid: (json['total_paid'] as num?)?.toDouble(),
    contractPdfUrl: json['contract_pdf_url'] as String?,
    contractPdfGeneratedAt: json['contract_pdf_generated_at']?.toString(),
    createdAt: json['created_at']?.toString(),
    updatedAt: json['updated_at']?.toString(),
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
    'payment_structure': paymentStructure,
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
    paymentStructure: paymentStructure,
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
    freelancerName: freelancerName ?? this.freelancerName,
    clientName: clientName ?? this.clientName,
  );
}
