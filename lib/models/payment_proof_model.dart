class PaymentProofModel {
  final String proofId;
  final String contractId;

  /// The milestone this proof pays for. `GET /contracts/{id}/payment-proof`
  /// returns the whole contract's history, so proofs must be filtered by this
  /// before deciding whether the *current* milestone has been paid.
  final String? milestoneId;

  final String payee;
  final double amount;
  final String? referenceNumber;
  final String fileUrl;
  final String uploadedBy;
  final String status;
  final String? rejectionReason;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PaymentProofModel({
    required this.proofId,
    required this.contractId,
    this.milestoneId,
    required this.payee,
    required this.amount,
    this.referenceNumber,
    required this.fileUrl,
    required this.uploadedBy,
    required this.status,
    this.rejectionReason,
    this.verifiedBy,
    this.verifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isVerified => status == 'verified';
  bool get isRejected => status == 'rejected';
  bool get isPending => status == 'pending_review';
  bool get isForAdmin => payee == 'admin';
  bool get isForFreelancer => payee == 'freelancer';

  factory PaymentProofModel.fromJson(Map<String, dynamic> json) {
    return PaymentProofModel(
      proofId: json['proof_id']?.toString() ?? '',
      contractId: json['contract_id']?.toString() ?? '',
      milestoneId: json['milestone_id']?.toString(),
      payee: json['payee']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      referenceNumber: json['reference_number']?.toString(),
      fileUrl: json['file_url']?.toString() ?? '',
      uploadedBy: json['uploaded_by']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending_review',
      rejectionReason: json['rejection_reason']?.toString(),
      verifiedBy: json['verified_by']?.toString(),
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
