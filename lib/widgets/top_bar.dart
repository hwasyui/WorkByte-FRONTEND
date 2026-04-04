import 'package:flutter/material.dart';
import '../../screens/dashboard/notification.dart';

/// Reusable top bar row used across screens.
/// Shows a back button on the left, and a notification bell + user avatar on the right.
/// Tapping the bell navigates to [NotificationScreen].
class ScreenTopBar extends StatelessWidget {
  final Widget userAvatar;
  final bool hasNotification;
  final VoidCallback? onNotificationTap;

  const ScreenTopBar({
    super.key,
    required this.userAvatar,
    this.hasNotification = true,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Back button
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF333333),
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),

        const Spacer(),

        // Notification bell with optional red dot
        GestureDetector(
          onTap:
              onNotificationTap ??
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                size: 22,
                color: Color(0xFF333333),
              ),
              if (hasNotification)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 7.2,
                    height: 7.2,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEC1B1B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // User avatar
        CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFFE0E0E0),
          child: ClipOval(child: userAvatar),
        ),
      ],
    );
  }
}
