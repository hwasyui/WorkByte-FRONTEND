import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/notification_item.dart';
import '../../widgets/load_more_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final authProvider = context.read<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final token = authProvider.token;
    if (token != null) {
      await notificationProvider.fetchNotifications(token);
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('dd MMM yyyy HH:mm').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            if (notificationProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (notificationProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${notificationProvider.error}'),
                    ElevatedButton(
                      onPressed: _fetchNotifications,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final notifications = notificationProvider.notifications;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── App bar ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      // Back button
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF333333),
                          size: 22,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),

                      // Title
                      Text(
                        'Notifications',
                        style: GoogleFonts.figtree(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF333333),
                          height: 19 / 16,
                        ),
                      ),

                      const Spacer(),

                      // "Latest" label + filter icon
                      Text(
                        'Latest',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7D7D7D),
                          height: 18 / 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          // TODO: open filter bottom sheet
                        },
                        child: const Icon(
                          Icons.filter_list,
                          size: 20,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),

                // ── Notifications list ─────────────────────────────────────
                Expanded(
                  child: notifications.isEmpty
                      ? const Center(child: Text('No notifications yet'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(13, 20, 16, 16),
                          itemCount: notifications.length + 1, // +1 for load more
                          itemBuilder: (context, index) {
                            if (index == notifications.length) {
                              return Center(child: LoadMoreButton(onTap: () {}));
                            }

                            final notification = notifications[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: NotificationItem(
                                boldPrefix: _getBoldPrefix(notification),
                                message: notification.message,
                                timestamp: _formatTimestamp(notification.createdAt),
                                isUnread: !notification.isRead,
                                avatar: _getAvatar(notification),
                                onTap: () => _onNotificationTap(notification),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _getBoldPrefix(NotificationModel notification) {
    switch (notification.type) {
      case 'contract_approval':
        return 'Contract';
      default:
        return 'Notification';
    }
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    final authProvider = context.read<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final token = authProvider.token;

    if (token != null && !notification.isRead) {
      await notificationProvider.markAsRead(token, notification.id);
    }

    // Handle navigation based on notification type
    if (notification.isContractApproval && notification.contractId != null) {
      // TODO: Navigate to contract detail screen
      // Navigator.push(context, MaterialPageRoute(builder: (_) => ContractDetailScreen(contractId: notification.contractId!)));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contract ID: ${notification.contractId}')),
      );
    }
  }

  Widget _getAvatar(NotificationModel notification) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFE8E8E8),
      child: Text(
        notification.userId.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
      ),
    );
  }
}
