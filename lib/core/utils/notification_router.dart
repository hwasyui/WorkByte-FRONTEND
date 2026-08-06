library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/job_post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/dm_provider.dart';
import '../../providers/job_post_provider.dart';
import '../../providers/profile_provider.dart';
import '../../screens/dm/dm_chat_screen.dart';
import '../../screens/job_client_view/job_detail.dart';
import '../../screens/job_freelancer_view/job_detail.dart';
import '../../screens/job_freelancer_view/job_list.dart';
import '../../screens/reviews/client_reviews_screen.dart';
import '../../screens/reviews/freelancer_reviews_screen.dart';
import '../../screens/workspace/workspace_detail.dart';
import '../../widgets/app_toast.dart';
import '../constants/colors.dart';
import 'moderation_display.dart';

/// Opens the screen a notification points at.
///
/// Every type the backend emits is handled here so taps behave the same in the
/// in-app list and when a push notification is opened. Types that carry no
/// usable target simply do nothing.
Future<void> openNotificationTarget(
  BuildContext context, {
  required String type,
  required Map<String, dynamic> data,
}) async {
  final token = context.read<AuthProvider>().token;
  if (token == null) return;

  final contractId = _id(data, 'contract_id');
  final jobPostId = _id(data, 'job_post_id');
  final jobRoleId = _id(data, 'job_role_id');
  final threadId = _id(data, 'thread_id');

  switch (type) {
    case 'new_message':
    case 'thread_accepted':
      if (threadId != null) await _openThread(context, token, threadId);
      return;

    case 'review_published':
    case 'review_publish_confirmed':
      // Land on the public reviews & trust score page the review appears on.
      if (contractId != null) {
        await _openPublicReviews(
          context,
          token,
          contractId: contractId,
          isClientReview: data.containsKey('client_review_id'),
        );
      }
      return;

    case 'review_flagged':
    case 'review_suppressed':
      // Not public yet, so send the reviewer back to the contract instead.
      if (contractId != null) await _openContract(context, token, contractId);
      return;

    case 'proposal_accepted':
      // The freelancer whose proposal was accepted wants their applications,
      // not the public job post. Clients get the job post as before.
      if (context.read<ProfileProvider>().isFreelancer) {
        await _push(context, const JobListScreen(initialTabIndex: 1));
        return;
      }
      if (jobPostId != null) await _openJobPost(context, token, jobPostId);
      return;

    case 'new_proposal':
    case 'proposal_rejected':
    case kNotifJobClosedHarmfulText:
    case 'job_closed_scam':
    case 'job_closed_admin':
    case 'job_closed_reports':
      if (jobPostId != null) await _openJobPost(context, token, jobPostId);
      return;

    case 'role_filled':
    case 'role_reopened':
      if (jobRoleId != null) await _openJobRole(context, token, jobRoleId);
      return;

    case 'contract_started':
    case 'contract_cancelled':
    case 'contract_completed':
    case 'contract_disputed':
    case 'dispute_resolved':
    case 'contract_overdue':
    case 'contract_auto_approved':
    case 'contract_autoapprove_reminder':
    case 'contract_autoapprove_final_warning':
    case 'work_submitted':
    case 'revision_requested':
    case 'job_closed_admin_contract':
      if (contractId != null) await _openContract(context, token, contractId);
      return;

    default:
      // Unknown or newly added type: fall back to whatever id it carries.
      if (contractId != null) {
        await _openContract(context, token, contractId);
      } else if (jobPostId != null) {
        await _openJobPost(context, token, jobPostId);
      } else if (jobRoleId != null) {
        await _openJobRole(context, token, jobRoleId);
      } else if (threadId != null) {
        await _openThread(context, token, threadId);
      }
      return;
  }
}

String? _id(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null) return null;
  final text = value.toString().trim();
  return (text.isEmpty || text == 'null') ? null : text;
}

void _showBusy(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        const Center(child: CircularProgressIndicator(color: AppColors.primary)),
  );
}

void _hideBusy(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}

Future<void> _push(BuildContext context, Widget screen) {
  return Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

Future<void> _openContract(
  BuildContext context,
  String token,
  String contractId,
) async {
  final contracts = context.read<ContractProvider>();
  _showBusy(context);
  await contracts.fetchContractById(token, contractId);
  if (!context.mounted) return;
  _hideBusy(context);

  final contract = contracts.currentContract;
  if (contract == null || contract.contractId != contractId) {
    AppToast.error('Could not open this contract.');
    return;
  }

  final isFreelancer = context.read<ProfileProvider>().isFreelancer;
  await _push(
    context,
    WorkspaceDetailScreen(
      contract: contract,
      viewerRole: isFreelancer ? 'freelancer' : 'client',
    ),
  );
}

Future<void> _openThread(
  BuildContext context,
  String token,
  String threadId,
) async {
  final dm = context.read<DMProvider>();
  _showBusy(context);
  try {
    final thread = await dm.fetchThread(token, threadId);
    if (!context.mounted) return;
    _hideBusy(context);
    await _push(context, DMChatScreen(thread: thread));
  } catch (_) {
    if (!context.mounted) return;
    _hideBusy(context);
    AppToast.error('Could not open this conversation.');
  }
}

Future<void> _openJobRole(
  BuildContext context,
  String token,
  String jobRoleId,
) async {
  final jobs = context.read<JobPostProvider>();
  _showBusy(context);
  final role = await jobs.fetchJobRoleById(token, jobRoleId);
  if (!context.mounted) return;
  _hideBusy(context);

  if (role == null || role.jobPostId.isEmpty) {
    AppToast.error('Could not open this job post.');
    return;
  }
  await _openJobPost(context, token, role.jobPostId);
}

Future<void> _openJobPost(
  BuildContext context,
  String token,
  String jobPostId,
) async {
  final jobs = context.read<JobPostProvider>();
  _showBusy(context);
  final JobPostModel? job = await jobs.fetchJobPostById(token, jobPostId);
  if (!context.mounted) return;
  _hideBusy(context);

  if (job == null) {
    AppToast.error('Could not open this job post.');
    return;
  }

  // The same notification types reach both sides of the marketplace, so the
  // viewer's own role decides which job screen to show.
  final isFreelancer = context.read<ProfileProvider>().isFreelancer;
  await _push(
    context,
    isFreelancer
        ? JobDetailScreen(job: job)
        : ClientJobDetailScreen(job: job),
  );
}

Future<void> _openPublicReviews(
  BuildContext context,
  String token, {
  required String contractId,
  required bool isClientReview,
}) async {
  final contracts = context.read<ContractProvider>();
  _showBusy(context);
  await contracts.fetchContractById(token, contractId);
  if (!context.mounted) return;

  final contract = contracts.currentContract;
  if (contract == null || contract.contractId != contractId) {
    _hideBusy(context);
    AppToast.error('Could not open these reviews.');
    return;
  }

  final profile = context.read<ProfileProvider>();
  if (isClientReview) {
    final client = await profile.fetchClientById(
      token: token,
      clientId: contract.clientId,
    );
    if (!context.mounted) return;
    _hideBusy(context);
    await _push(
      context,
      ClientReviewsScreen(
        clientId: contract.clientId,
        clientName: client?.displayName ?? 'Client',
      ),
    );
    return;
  }

  final freelancer = await profile.fetchFreelancerById(
    token: token,
    freelancerId: contract.freelancerId,
  );
  if (!context.mounted) return;
  _hideBusy(context);
  await _push(
    context,
    FreelancerReviewsScreen(
      freelancerId: contract.freelancerId,
      freelancerName: freelancer?.displayName ?? 'Freelancer',
    ),
  );
}
