class FreelancerModel {
  final String freelancerId;
  final String userId;
  final String fullName;
  final String? bio;
  final String? cvFileUrl;
  final String? profilePictureUrl;
  final String jobTitle;
  final double? estimatedRate;
  final String? rateTime;
  final String? rateCurrency;
  final int totalProjects;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FreelancerModel({
    required this.freelancerId,
    required this.userId,
    required this.fullName,
    this.bio,
    this.cvFileUrl,
    this.profilePictureUrl,
    this.jobTitle = '-',
    this.estimatedRate,
    this.rateTime,
    this.rateCurrency,
    this.totalProjects = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory FreelancerModel.fromJson(Map<String, dynamic> json) =>
      FreelancerModel(
        freelancerId: json['freelancer_id'] as String,
        userId: json['user_id'] as String,
        fullName: json['full_name'] as String? ?? '',
        bio: json['bio'] as String?,
        cvFileUrl: json['cv_file_url'] as String?,
        profilePictureUrl: json['profile_picture_url'] as String?,
        jobTitle: '-',
        estimatedRate: (json['estimated_rate'] as num?)?.toDouble(),
        rateTime: json['rate_time'] as String?,
        rateCurrency: json['rate_currency'] as String?,
        totalProjects: (json['total_projects'] as num?)?.toInt() ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
      );

  String get displayName => fullName.isNotEmpty ? fullName : 'Freelancer';

  String get formattedRate {
    if (estimatedRate == null) return 'Rate not set';
    final currency = rateCurrency ?? 'USD';
    final period = rateTime ?? 'hourly';
    return '$currency ${estimatedRate!.toStringAsFixed(0)} / $period';
  }

  FreelancerModel copyWith({
    String? fullName,
    String? bio,
    String? cvFileUrl,
    String? profilePictureUrl,
    String? jobTitle,
    double? estimatedRate,
    String? rateTime,
    String? rateCurrency,
  }) => FreelancerModel(
    freelancerId: freelancerId,
    userId: userId,
    fullName: fullName ?? this.fullName,
    bio: bio ?? this.bio,
    cvFileUrl: cvFileUrl ?? this.cvFileUrl,
    profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    jobTitle: jobTitle ?? this.jobTitle,
    estimatedRate: estimatedRate ?? this.estimatedRate,
    rateTime: rateTime ?? this.rateTime,
    rateCurrency: rateCurrency ?? this.rateCurrency,
    totalProjects: totalProjects,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
