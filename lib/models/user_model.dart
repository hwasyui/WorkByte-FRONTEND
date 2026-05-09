class UserModel {
  final String userId;
  final String email;
  final String type;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.userId,
    required this.email,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userId: json['user_id'] as String,
    email: json['email'] as String,
    type: _extractUserType(json),
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'].toString())
        : null,
  );

  static String _extractUserType(Map<String, dynamic> json) {
    final String? rawType = (json['type'] ?? json['user_type'])
        ?.toString()
        .toLowerCase();

    if (rawType == 'client' || rawType == 'freelancer') {
      return rawType!;
    }

    if (json['freelancer_id'] != null) {
      return 'freelancer';
    }

    if (json['client_id'] != null) {
      return 'client';
    }

    return 'client';
  }

  bool get isClient => type == 'client';
  bool get isFreelancer => type == 'freelancer';
}
