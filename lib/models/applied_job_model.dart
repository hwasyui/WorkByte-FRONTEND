import 'job_post_model.dart';

class AppliedJobModel {
  final String proposalId;
  final String jobPostId;
  final String? jobRoleId;
  final String freelancerId;
  final String coverLetter;
  final double proposedBudget;
  final String? proposedDuration;
  final String status;
  final bool isAiGenerated;
  final String? submittedAt;
  final JobPostModel job;

  const AppliedJobModel({
    required this.proposalId,
    required this.jobPostId,
    this.jobRoleId,
    required this.freelancerId,
    required this.coverLetter,
    required this.proposedBudget,
    this.proposedDuration,
    required this.status,
    required this.isAiGenerated,
    this.submittedAt,
    required this.job,
  });

  factory AppliedJobModel.fromProposalAndJob({
    required Map<String, dynamic> proposal,
    required JobPostModel job,
  }) {
    return AppliedJobModel(
      proposalId: proposal['proposal_id']?.toString() ?? '',
      jobPostId: proposal['job_post_id']?.toString() ?? '',
      jobRoleId: proposal['job_role_id']?.toString(),
      freelancerId: proposal['freelancer_id']?.toString() ?? '',
      coverLetter: proposal['cover_letter']?.toString() ?? '',
      proposedBudget:
          double.tryParse(proposal['proposed_budget']?.toString() ?? '') ?? 0,
      proposedDuration: proposal['proposed_duration']?.toString(),
      status: proposal['status']?.toString() ?? 'pending',
      isAiGenerated: proposal['is_ai_generated'] == true,
      submittedAt: proposal['submitted_at']?.toString(),
      job: job,
    );
  }
}
