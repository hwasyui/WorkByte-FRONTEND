class JobPostModel {
  final String jobPostId;
  final String clientId;
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
  final String? createdAt;
  final String? postedAt;
  final String? closedAt;

  const JobPostModel({
    required this.jobPostId,
    required this.clientId,
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
    this.createdAt,
    this.postedAt,
    this.closedAt,
  });

  factory JobPostModel.fromJson(Map<String, dynamic> json) => JobPostModel(
    jobPostId: json['job_post_id'] as String? ?? '',
    clientId: json['client_id'] as String? ?? '',
    jobTitle: json['job_title'] as String? ?? '',
    jobDescription: json['job_description'] as String? ?? '',
    projectType: json['project_type'] as String? ?? 'individual',
    projectScope: json['project_scope'] as String? ?? 'small',
    estimatedDuration: json['estimated_duration'] as String?,
    workingDays: (json['working_days'] as num?)?.toInt(),
    deadline: json['deadline']?.toString(),
    experienceLevel: json['experience_level'] as String?,
    status: json['status'] as String? ?? 'draft',
    isAiGenerated: json['is_ai_generated'] as bool? ?? false,
    viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
    proposalCount: (json['proposal_count'] as num?)?.toInt() ?? 0,
    createdAt: json['created_at']?.toString(),
    postedAt: json['posted_at']?.toString(),
    closedAt: json['closed_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
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
  };

  // Add this right after toJson()
  Map<String, dynamic> toMap() => {
    'job_post_id': jobPostId,
    'client_id': clientId,
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
    'created_at': createdAt,
    'posted_at': postedAt,
    'closed_at': closedAt,
  };
}
