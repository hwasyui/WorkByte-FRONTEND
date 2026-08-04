import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationItem extends StatelessWidget {
  final Widget avatar;
  final String message;

  final String title;
  final String timestamp;
  final bool isUnread;

  const NotificationItem({
    super.key,
    required this.avatar,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isUnread = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            width: 7.2,
            height: 7.2,
            decoration: BoxDecoration(
              color: isUnread ? const Color(0xFF5EC9A2) : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 5),

        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.secondary,
          child: ClipOval(child: avatar),
        ),
        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.4,
                ),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF333333),
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                timestamp,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
