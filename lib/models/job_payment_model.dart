// ── lib/models/job_payment_model.dart ───────────────────────────────────────

class JobPaymentModel {
  final String jobPaymentId;
  final String jobPostId;
  final String paymentType; // "full" | "milestone"
  final String paymentOption;
  final String? status;
  final String? createdAt;

  const JobPaymentModel({
    required this.jobPaymentId,
    required this.jobPostId,
    required this.paymentType,
    required this.paymentOption,
    this.status,
    this.createdAt,
  });

  factory JobPaymentModel.fromJson(Map<String, dynamic> json) =>
      JobPaymentModel(
        jobPaymentId: json['job_payment_id'] as String? ?? '',
        jobPostId: json['job_post_id'] as String? ?? '',
        paymentType: json['payment_type'] as String? ?? 'full',
        paymentOption: json['payment_option'] as String? ?? '',
        status: json['status'] as String?,
        createdAt: json['created_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
    'job_post_id': jobPostId,
    'payment_type': paymentType,
    'payment_option': paymentOption,
  };
}

class JobMilestoneModel {
  final String milestoneId;
  final String jobPaymentId;
  final String workProgress;
  final String paymentPercentage;
  final int milestoneOrder;
  final String? status;

  const JobMilestoneModel({
    this.milestoneId = '',
    this.jobPaymentId = '',
    required this.workProgress,
    required this.paymentPercentage,
    required this.milestoneOrder,
    this.status,
  });

  factory JobMilestoneModel.fromJson(Map<String, dynamic> json) =>
      JobMilestoneModel(
        milestoneId: json['milestone_id'] as String? ?? '',
        jobPaymentId: json['job_payment_id'] as String? ?? '',
        workProgress: json['work_progress'] as String? ?? '',
        paymentPercentage: json['payment_percentage'] as String? ?? '',
        milestoneOrder: (json['milestone_order'] as num?)?.toInt() ?? 0,
        status: json['status'] as String?,
      );

  Map<String, dynamic> toJson(String jobPaymentId) => {
    'job_payment_id': jobPaymentId,
    'work_progress': workProgress,
    'payment_percentage': paymentPercentage,
    'milestone_order': milestoneOrder,
  };
}

// ── In-memory draft (no backend yet) ─────────────────────────────────────────
class JobPaymentDraft {
  final bool isFullPayment;
  final String paymentOption;
  final List<JobMilestoneModel> milestones;

  const JobPaymentDraft({
    required this.isFullPayment,
    required this.paymentOption,
    this.milestones = const [],
  });
}
