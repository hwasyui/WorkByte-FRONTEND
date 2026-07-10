import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/notification_model.dart';
import '../../widgets/notification_item.dart';
import '../../widgets/load_more_button.dart';
import '../workspace/workspace_detail.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationProvider>();
      provider.fetchNotifications(refresh: true);
      provider.markAllRead(); // mark all read when screen opens
    });
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
    };
    return urgentTypes.contains(type);
  }

  Future<void> _openNotification(NotificationModel notif) async {
    context.read<NotificationProvider>().markAsRead(notif.id);

    final contractId = notif.data['contract_id']?.toString();
    if (contractId == null || contractId.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

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
