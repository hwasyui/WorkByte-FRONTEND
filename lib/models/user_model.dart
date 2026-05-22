class UserModel {
  final String userId;
  final String email;
  final String type;
  final bool isAdmin;
  final String? clientId;
  final String? freelancerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool passwordLoginEnabled;
  final bool isReportBanned;
  final String? banMessage;
  final DateTime? reportBannedAt;

  const UserModel({
    required this.userId,
    required this.email,
    required this.type,
    this.isAdmin = false,
    this.clientId,
    this.freelancerId,
    this.createdAt,
    this.updatedAt,
    this.passwordLoginEnabled = true,
    this.isReportBanned = false, // 👈 NEW
    this.banMessage, // 👈 NEW
    this.reportBannedAt, // 👈 NEW
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userId: json['user_id'] as String,
    email: json['email'] as String,
    type: _extractUserType(json),
    isAdmin: json['is_admin'] as bool? ?? false,
    clientId: json['client_id'] as String?,
    freelancerId: json['freelancer_id'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'].toString())
        : null,
    passwordLoginEnabled: json['password_login_enabled'] as bool? ?? true,
    isReportBanned: json['is_report_banned'] as bool? ?? false, // 👈 NEW
    banMessage: json['ban_message'] as String?, // 👈 NEW
    reportBannedAt:
        json['report_banned_at'] !=
            null // 👈 NEW
        ? DateTime.tryParse(json['report_banned_at'].toString())
        : null,
  );

  static String _extractUserType(Map<String, dynamic> json) {
    final String? rawType = (json['type'] ?? json['user_type'])
        ?.toString()
        .toLowerCase();

    if (rawType == 'client' || rawType == 'freelancer') return rawType!;
    if (json['freelancer_id'] != null) return 'freelancer';
    if (json['client_id'] != null) return 'client';
    return 'none';
  }

  bool get hasRole => clientId != null || freelancerId != null;
  bool get isClient => type == 'client';
  bool get isFreelancer => type == 'freelancer';
}
