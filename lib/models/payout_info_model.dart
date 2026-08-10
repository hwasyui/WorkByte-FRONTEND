class PayoutInfoModel {
  final String freelancerId;
  final String? bankName;
  final String? accountNumber;
  final String? accountHolderName;
  final DateTime? updatedAt;

  const PayoutInfoModel({
    required this.freelancerId,
    this.bankName,
    this.accountNumber,
    this.accountHolderName,
    this.updatedAt,
  });

  bool get isComplete =>
      (bankName ?? '').trim().isNotEmpty &&
      (accountNumber ?? '').trim().isNotEmpty &&
      (accountHolderName ?? '').trim().isNotEmpty;

  factory PayoutInfoModel.fromJson(Map<String, dynamic> json) {
    return PayoutInfoModel(
      freelancerId: json['freelancer_id']?.toString() ?? '',
      bankName: json['bank_name']?.toString(),
      accountNumber: json['account_number']?.toString(),
      accountHolderName: json['account_holder_name']?.toString(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
