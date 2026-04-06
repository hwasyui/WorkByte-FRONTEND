class User {
  final String userId;
  final String email;
  final String type; // 'freelancer' or 'client'
  final String? fullName;
  final String? companyName;

  User({
    required this.userId,
    required this.email,
    required this.type,
    this.fullName,
    this.companyName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? '',
      email: json['email'] ?? '',
      type: json['type'] ?? '',
      fullName: json['full_name'],
      companyName: json['company_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'type': type,
      'full_name': fullName,
      'company_name': companyName,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final String tokenType;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
    );
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String userType;
  final String? fullName;
  final String? companyName;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.userType,
    this.fullName,
    this.companyName,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'user_type': userType,
      'full_name': fullName,
      'company_name': companyName,
    };
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}
