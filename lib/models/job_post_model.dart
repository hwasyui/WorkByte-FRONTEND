class JobPostModel {
  final String jobPostId;
  final String clientId;
  final String? clientName;
  final String? profilePictureUrl;
  final String jobTitle;
  final String jobDescription;
  final String projectCategory;
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
  final int availablePositions;
  final String? createdAt;
  final String? updatedAt;
  final String? postedAt;
  final String? closedAt;
  final String? closureReason;
  final String? closureNote;

  const JobPostModel({
    required this.jobPostId,
    required this.clientId,
    this.clientName,
    this.profilePictureUrl,
    required this.jobTitle,
    required this.jobDescription,
    required this.projectCategory,
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
    this.availablePositions = 0,
    this.createdAt,
    this.updatedAt,
    this.postedAt,
    this.closedAt,
    this.closureReason,
    this.closureNote,
  });

  factory JobPostModel.fromJson(Map<String, dynamic> json) => JobPostModel(
    jobPostId: json['job_post_id'] as String? ?? '',
    clientId: json['client_id'] as String? ?? '',
    clientName: json['client_name'] as String?,
    profilePictureUrl: json['profile_picture_url'] as String?,
    jobTitle: json['job_title'] as String? ?? '',
    jobDescription: json['job_description'] as String? ?? '',
    projectCategory: json['project_category'] ?? 'general',
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
    availablePositions: (json['available_positions'] as num?)?.toInt() ?? 0,
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
    postedAt: json['posted_at'] as String?,
    closedAt: json['closed_at'] as String?,
    closureReason: json['closure_reason'] as String?, // 👈 NEW
    closureNote: json['closure_note'] as String?, // 👈 NEW
  );

  Map<String, dynamic> toJson() => {
    'job_post_id': jobPostId,
    'client_id': clientId,
    'client_name': clientName,
    'job_title': jobTitle,
    'job_description': jobDescription,
    'project_category': projectCategory,
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
    if (closureReason != null) 'closure_reason': closureReason,
    if (closureNote != null) 'closure_note': closureNote,
  };

  Map<String, dynamic> toMap() => {
    'job_post_id': jobPostId,
    'client_id': clientId,
    'client_name': clientName,
    'profile_picture_url': profilePictureUrl,
    'job_title': jobTitle,
    'job_description': jobDescription,
    'project_category': projectCategory,
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
    'available_positions': availablePositions,
    'created_at': createdAt,
    'posted_at': postedAt,
    'closed_at': closedAt,
    'closure_reason': closureReason,
    'closure_note': closureNote,
  };
}
