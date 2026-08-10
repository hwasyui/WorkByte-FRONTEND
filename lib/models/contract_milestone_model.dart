/// One entry in a contract's milestone schedule.
///
/// Milestones unlock strictly in order: everything before the current one is
/// `completed`, everything after it is `locked`, and exactly one sits in a
/// working status at a time. The contract's own status mirrors whichever stage
/// that current milestone is in, which is why `active` alone no longer means
/// "nothing has happened yet" — see [ContractMilestoneList.current].
class ContractMilestoneModel {
  final String milestoneId;
  final String contractId;
  final String title;
  final String? description;
  final double amount;
  final int sequenceOrder;
  final String status;
  final String? dueDate;

  final double? commissionRate;
  final double? commissionAmount;
  final double? payoutAmount;

  final String? freelancerConfirmedReceiptAt;
  final String? paymentVerifiedAt;
  final String? paymentVerifiedBy;
  final bool completedByAdminOverride;

  final String? createdAt;
  final String? updatedAt;

  const ContractMilestoneModel({
    required this.milestoneId,
    required this.contractId,
    required this.title,
    this.description,
    required this.amount,
    required this.sequenceOrder,
    required this.status,
    this.dueDate,
    this.commissionRate,
    this.commissionAmount,
    this.payoutAmount,
    this.freelancerConfirmedReceiptAt,
    this.paymentVerifiedAt,
    this.paymentVerifiedBy,
    this.completedByAdminOverride = false,
    this.createdAt,
    this.updatedAt,
  });

  /// The statuses a milestone passes through while it is the unlocked one.
  static const Set<String> workingStatuses = {
    'active',
    'under_review',
    'revision_requested',
    'pending_payment',
    'payment_review',
    'payment_rejected',
  };

  bool get isCompleted => status == 'completed';
  bool get isLocked => status == 'locked';
  bool get isWorking => workingStatuses.contains(status);

  bool get isAtPaymentStage =>
      status == 'pending_payment' ||
      status == 'payment_review' ||
      status == 'payment_rejected';

  factory ContractMilestoneModel.fromJson(Map<String, dynamic> json) {
    return ContractMilestoneModel(
      milestoneId: json['milestone_id']?.toString() ?? '',
      contractId: json['contract_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      sequenceOrder: (json['sequence_order'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'locked',
      dueDate: json['due_date']?.toString(),
      commissionRate: (json['commission_rate'] as num?)?.toDouble(),
      commissionAmount: (json['commission_amount'] as num?)?.toDouble(),
      payoutAmount: (json['payout_amount'] as num?)?.toDouble(),
      freelancerConfirmedReceiptAt:
          json['freelancer_confirmed_receipt_at']?.toString(),
      paymentVerifiedAt: json['payment_verified_at']?.toString(),
      paymentVerifiedBy: json['payment_verified_by']?.toString(),
      completedByAdminOverride:
          json['completed_by_admin_override'] as bool? ?? false,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

extension ContractMilestoneList on List<ContractMilestoneModel> {
  /// The milestone the contract is currently working through, or null once
  /// every milestone is paid. Prefers the one in a working status and falls
  /// back to the first unfinished entry so a milestone in an unexpected status
  /// still surfaces rather than the UI silently showing nothing.
  ContractMilestoneModel? get current {
    for (final m in this) {
      if (m.isWorking) return m;
    }
    for (final m in this) {
      if (!m.isCompleted) return m;
    }
    return null;
  }

  int get completedCount => where((m) => m.isCompleted).length;

  /// 1-based position of the current milestone, for "Milestone 2 of 3".
  /// Falls back to [length] when everything is done.
  int get currentPosition {
    final c = current;
    if (c == null) return length;
    final index = indexOf(c);
    return index < 0 ? length : index + 1;
  }

  /// True once at least one earlier milestone is paid — the signal that a
  /// contract sitting at `active` just had its next milestone unlock rather
  /// than being brand new.
  bool get hasPaidEarlierMilestone => completedCount > 0;

  double get totalAmount => fold(0.0, (sum, m) => sum + m.amount);
}
