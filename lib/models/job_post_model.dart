class JobPostModel {
  final String jobPostId;
  final String clientId;
  final String? clientName;
  final String jobTitle;
  final String jobDescription;
  final String projectType;
  final String projectScope;
  final String? estimatedDuration;
  final int? workingDays;
  final String? deadline;
  final String? experienceLevel;
  final String status;
  final bool isAiGenerated;
  final int viewCount;
  final int proposalCount;
  final int roleCount;
  final String? createdAt;
  final String? updatedAt;
  final String? postedAt;
  final String? closedAt;

  const JobPostModel({
    required this.jobPostId,
    required this.clientId,
    this.clientName,
    required this.jobTitle,
    required this.jobDescription,
    required this.projectType,
    required this.projectScope,
    this.estimatedDuration,
    this.workingDays,
    this.deadline,
    this.experienceLevel,
    this.status = 'draft',
    this.isAiGenerated = false,
    this.viewCount = 0,
    this.proposalCount = 0,
    this.roleCount = 0,
    this.createdAt,
    this.updatedAt,
    this.postedAt,
    this.closedAt,
  });

  factory JobPostModel.fromJson(Map<String, dynamic> json) => JobPostModel(
    jobPostId: json['job_post_id'] as String? ?? '',
    clientId: json['client_id'] as String? ?? '',
    clientName: json['client_name'] as String?,
    jobTitle: json['job_title'] as String? ?? '',
    jobDescription: json['job_description'] as String? ?? '',
    projectType: json['project_type'] as String? ?? '',
    projectScope: json['project_scope'] as String? ?? '',
    estimatedDuration: json['estimated_duration'] as String?,
    workingDays: (json['working_days'] as num?)?.toInt(),
    deadline: json['deadline'] as String?,
    experienceLevel: json['experience_level'] as String?,
    status: json['status'] as String? ?? 'draft',
    isAiGenerated: json['is_ai_generated'] as bool? ?? false,
    viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
    proposalCount: (json['proposal_count'] as num?)?.toInt() ?? 0,
    roleCount: (json['role_count'] as num?)?.toInt() ?? 0,
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
    postedAt: json['posted_at'] as String?,
    closedAt: json['closed_at'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'job_post_id': jobPostId,
    'client_id': clientId,
    'client_name': clientName,
    'job_title': jobTitle,
    'job_description': jobDescription,
    'project_type': projectType,
    'project_scope': projectScope,
    if (estimatedDuration != null) 'estimated_duration': estimatedDuration,
    if (workingDays != null) 'working_days': workingDays,
    if (deadline != null) 'deadline': deadline,
    if (experienceLevel != null) 'experience_level': experienceLevel,
    'status': status,
    'is_ai_generated': isAiGenerated,
    'view_count': viewCount,
    'proposal_count': proposalCount,
    'role_count': roleCount,
  };

  Map<String, dynamic> toMap() => {
    'job_post_id': jobPostId,
    'client_id': clientId,
    'client_name': clientName,
    'job_title': jobTitle,
    'job_description': jobDescription,
    'project_type': projectType,
    'project_scope': projectScope,
    'estimated_duration': estimatedDuration,
    'experience_level': experienceLevel,
    'working_days': workingDays,
    'deadline': deadline,
    'status': status,
    'is_ai_generated': isAiGenerated,
    'view_count': viewCount,
    'proposal_count': proposalCount,
    'role_count': roleCount,
    'created_at': createdAt,
    'posted_at': postedAt,
    'closed_at': closedAt,
  };
}
