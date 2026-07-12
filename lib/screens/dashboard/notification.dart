import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/proposal_provider.dart';
import '../../models/notification_model.dart';
import '../../widgets/notification_item.dart';
import '../../widgets/load_more_button.dart';
import '../../widgets/proposal_edit_form.dart';
import '../../services/proposal_service.dart';
import '../../services/job_post_service.dart';
import '../../core/utils/harmful_block_dialog.dart';
import '../workspace/workspace_detail.dart';
import '../freelancer_profile/freelancer_profile.dart';
import '../job_client_view/job_detail.dart' as client_job_view;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  /// True while this screen is on-screen. Read by notification_banner.dart
  /// so a foreground push doesn't pop up a "you got blocked" banner on top
  /// of the real notification the user is already looking at.
  static bool isOpen = false;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    NotificationScreen.isOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationProvider>();
      provider.fetchNotifications(refresh: true);
      provider.markAllRead(); // mark all read when screen opens
    });
  }

  @override
  void dispose() {
    NotificationScreen.isOpen = false;
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day} ${_month(dt.month)} ${dt.year}';
  }

  String _month(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_message':
        return Icons.chat_bubble_outline;
      case 'new_proposal':
        return Icons.description_outlined;
      case 'proposal_accepted':
        return Icons.check_circle_outline;
      case 'proposal_rejected':
        return Icons.cancel_outlined;
      case 'contract_started':
        return Icons.handshake_outlined;
      case 'contract_cancelled':
        return Icons.block_outlined;
      case 'contract_completed':
        return Icons.task_alt_outlined;
      case 'work_submitted':
        return Icons.upload_file_outlined;
      case 'revision_requested':
        return Icons.edit_outlined;
      case 'payment_reported':
        return Icons.account_balance_wallet_outlined;
      case 'contract_disputed':
        return Icons.gavel_outlined;
      case 'dispute_resolved':
        return Icons.balance_outlined;
      case 'contract_overdue':
        return Icons.event_busy_outlined;
      case 'contract_autoapprove_reminder':
      case 'contract_autoapprove_final_warning':
        return Icons.timer_outlined;
      case 'contract_auto_approved':
        return Icons.auto_mode_outlined;
      case 'education_blocked':
      case 'work_experience_blocked':
      case 'job_post_blocked':
      case 'proposal_blocked':
      case 'portfolio_blocked':
        return Icons.block_rounded;
      case 'account_deletion_blocked':
        return Icons.report_problem_outlined;
      case 'review_published':
        return Icons.star_outline_rounded;
      case 'review_publish_confirmed':
        return Icons.rate_review_outlined;
      case 'review_suppressed':
        return Icons.visibility_off_outlined;
      case 'review_flagged':
        return Icons.hourglass_top_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  bool _isUrgent(String type) {
    const urgentTypes = {
      'contract_disputed',
      'dispute_resolved',
      'contract_overdue',
      'contract_autoapprove_final_warning',
      'contract_auto_approved',
      'review_suppressed',
    };
    return urgentTypes.contains(type) || _isBlocked(type);
  }

  /// Content-moderation "your X got blocked, edit and resubmit" family - see
  /// education_functions.py / work_experience_functions.py / job_post_
  /// functions.py / proposal_functions.py / portfolio_functions.py's
  /// run_*_scan(). Rendered in red with a block icon, same as the disappearing
  /// banner in notification_banner.dart, so the two treatments are consistent
  /// whether the user sees it live or later in this list.
  bool _isBlocked(String type) {
    const blockedTypes = {
      'education_blocked',
      'work_experience_blocked',
      'job_post_blocked',
      'proposal_blocked',
      'portfolio_blocked',
    };
    return blockedTypes.contains(type);
  }

  Future<void> _openNotification(NotificationModel notif) async {
    context.read<NotificationProvider>().markAsRead(notif.id);

    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    switch (notif.type) {
      case 'education_blocked':
        _openProfileEditEntity(
          'education',
          notif.data['education_id']?.toString(),
        );
        return;
      case 'work_experience_blocked':
        _openProfileEditEntity(
          'work_experience',
          notif.data['work_experience_id']?.toString(),
        );
        return;
      case 'portfolio_blocked':
        _openProfileEditEntity(
          'portfolio',
          notif.data['portfolio_id']?.toString(),
        );
        return;
      case 'job_post_blocked':
        await _openBlockedJobPost(token, notif.data['job_post_id']?.toString());
        return;
      case 'proposal_blocked':
        await _openBlockedProposal(token, notif.data['proposal_id']?.toString());
        return;
    }

    final contractId = notif.data['contract_id']?.toString();
    if (contractId == null || contractId.isEmpty) return;

    final contractProvider = context.read<ContractProvider>();
    await contractProvider.fetchContractById(token, contractId);
    if (!mounted) return;

    final contract = contractProvider.currentContract;
    if (contract == null || contract.contractId != contractId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this contract.')),
      );
      return;
    }

    final isFreelancer = context.read<ProfileProvider>().isFreelancer;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkspaceDetailScreen(
          contract: contract,
          viewerRole: isFreelancer ? 'freelancer' : 'client',
        ),
      ),
    );
  }

  void _openProfileEditEntity(String type, String? id) {
    if (id == null || id.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(initialEditEntityType: type, initialEditEntityId: id),
      ),
    );
  }

  /// Job posts have no dedicated "edit content" screen yet (only status
  /// actions like closing exist) - this opens the job's detail page, which is
  /// at least the right destination, until an edit flow is built.
  Future<void> _openBlockedJobPost(String token, String? jobPostId) async {
    if (jobPostId == null || jobPostId.isEmpty) return;
    try {
      final job = await JobPostService().getJobPost(token, jobPostId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => client_job_view.ClientJobDetailScreen(
            job: job,
            autoOpenEdit: true,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this job post.')),
        );
      }
    }
  }

  Future<void> _openBlockedProposal(String token, String? proposalId) async {
    if (proposalId == null || proposalId.isEmpty) return;
    try {
      final proposal = await ProposalService().getProposalById(
        token,
        proposalId,
      );
      if (!mounted) return;
      final proposalProvider = context.read<ProposalProvider>();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ProposalEditForm(
          initialData: proposal,
          onSave: (data) async {
            final success = await proposalProvider.updateProposal(
              token: token,
              proposalId: proposal.proposalId,
              data: data,
            );
            if (!mounted) return;
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Proposal updated successfully')),
              );
            } else {
              showErrorFeedback(
                context,
                message: proposalProvider.error ?? 'Failed to update proposal',
              );
            }
          },
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this proposal.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF333333),
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const Spacer(),
                  Consumer<NotificationProvider>(
                    builder: (context, provider, _) {
                      if (provider.unreadCount == 0)
                        return const SizedBox.shrink();
                      return TextButton(
                        onPressed: provider.markAllRead,
                        child: Text(
                          'Mark all read',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6E6BF8),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── List ─────────────────────────────────────────────────
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, provider, _) {
                  // Loading initial
                  if (provider.isLoading && provider.notifications.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Error
                  if (provider.error != null &&
                      provider.notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.error!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF7D7D7D),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () =>
                                provider.fetchNotifications(refresh: true),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Empty
                  if (provider.notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            size: 56,
                            color: Color(0xFFCCCCCC),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications yet',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7D7D7D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You\'re all caught up!',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFFAAAAAA),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // List
                  return RefreshIndicator(
                    onRefresh: () => provider.fetchNotifications(refresh: true),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(13, 20, 16, 16),
                      itemCount:
                          provider.notifications.length + 1, // +1 for load more
                      separatorBuilder: (_, __) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        // Load more button at the bottom
                        if (index == provider.notifications.length) {
                          if (!provider.hasMore) return const SizedBox.shrink();
                          return Center(
                            child: LoadMoreButton(
                              onTap: provider.isLoading
                                  ? () {}
                                  : () => provider.fetchNotifications(),
                            ),
                          );
                        }

                        final NotificationModel notif =
                            provider.notifications[index];
                        return GestureDetector(
                          onTap: () => _openNotification(notif),
                          child: NotificationItem(
                            boldPrefix: notif.title,
                            message: notif.body,
                            timestamp: _formatTime(notif.createdAt),
                            isUnread: !notif.isRead,
                            avatarBackgroundColor: _isBlocked(notif.type)
                                ? const Color(0xFFFEE2E2)
                                : null,
                            avatar: Icon(
                              _iconForType(notif.type),
                              size: 22,
                              color: _isUrgent(notif.type)
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFF6E6BF8),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
