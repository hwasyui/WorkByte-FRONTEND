import 'package:flutter/material.dart';
import '../core/constants/text_styles.dart';
import '../screens/dashboard/notification.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final Widget userAvatar;
  final bool hasNotification;
  final VoidCallback? onNotificationTap;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.userAvatar,
    this.hasNotification = true,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFE0E0E0),
          child: ClipOval(child: userAvatar),
        ),
        const SizedBox(width: 10),
        // Greeting
        Text(
          '$userName!',
          style: AppText.h3.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF333333),
          ),
        ),
        const Spacer(),
        // Notification bell
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
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEC1B1B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
