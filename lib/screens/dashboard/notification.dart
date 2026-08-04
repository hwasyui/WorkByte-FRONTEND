import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/utils/notification_display.dart';
import '../../core/utils/notification_router.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import '../../widgets/notification_item.dart';
import '../../widgets/load_more_button.dart';

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
      provider.markAllRead();
    });
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return _ago(diff.inMinutes, 'minute');
    if (diff.inHours < 24) return _ago(diff.inHours, 'hour');
    if (diff.inDays < 7) return _ago(diff.inDays, 'day');
    return '${dt.day} ${_month(dt.month)} ${dt.year}';
  }

  String _ago(int value, String unit) =>
      '$value $unit${value == 1 ? '' : 's'} ago';

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

  Future<void> _openNotification(NotificationModel notif) async {
    context.read<NotificationProvider>().markAsRead(notif.id);
    await openNotificationTarget(
      context,
      type: notif.type,
      data: notif.data,
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

            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.notifications.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

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

                  return RefreshIndicator(
                    onRefresh: () => provider.fetchNotifications(refresh: true),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(13, 20, 16, 16),
                      itemCount:
                          provider.notifications.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
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
                        final presentation = notificationPresentation(
                          notif.type,
                          apiTitle: notif.title,
                        );
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openNotification(notif),
                          child: NotificationItem(
                            title: presentation.title,
                            message: notificationBody(
                              type: notif.type,
                              apiTitle: notif.title,
                              apiBody: notif.body,
                            ),
                            timestamp: _formatTime(notif.createdAt),
                            isUnread: !notif.isRead,
                            avatar: Icon(
                              presentation.icon,
                              size: 22,
                              color: presentation.color,
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
