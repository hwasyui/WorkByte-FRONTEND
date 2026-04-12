class ClientModel {
  final String clientId;
  final String userId;
  final String? fullName;
  final String? bio;
  final String? websiteUrl;
  final String? profilePictureUrl;
  final int totalJobsPosted;
  final int totalProjectsCompleted;
  final double? averageRatingGiven;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClientModel({
    required this.clientId,
    required this.userId,
    this.fullName,
    this.bio,
    this.websiteUrl,
    this.profilePictureUrl,
    this.totalJobsPosted = 0,
    this.totalProjectsCompleted = 0,
    this.averageRatingGiven,
    this.createdAt,
    this.updatedAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel(
    clientId: json['client_id'] as String,
    userId: json['user_id'] as String,
    fullName: json['full_name'] as String?,
    bio: json['bio'] as String?,
    websiteUrl: json['website_url'] as String?,
    profilePictureUrl: json['profile_picture_url'] as String?,
    totalJobsPosted: (json['total_jobs_posted'] as num?)?.toInt() ?? 0,
    totalProjectsCompleted:
        (json['total_projects_completed'] as num?)?.toInt() ?? 0,
    averageRatingGiven: (json['average_rating_given'] as num?)?.toDouble(),
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'].toString())
        : null,
  );

  String get displayName => fullName ?? 'Client';

  ClientModel copyWith({
    String? fullName,
    String? bio,
    String? websiteUrl,
    String? profilePictureUrl,
  }) => ClientModel(
    clientId: clientId,
    userId: userId,
    fullName: fullName ?? this.fullName,
    bio: bio ?? this.bio,
    websiteUrl: websiteUrl ?? this.websiteUrl,
    profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    totalJobsPosted: totalJobsPosted,
    totalProjectsCompleted: totalProjectsCompleted,
    averageRatingGiven: averageRatingGiven,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
