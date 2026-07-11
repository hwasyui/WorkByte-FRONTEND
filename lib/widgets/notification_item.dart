import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationItem extends StatelessWidget {
  final Widget avatar;
  final String message;

  /// The [boldPrefix] is the name/word rendered in bold at the start of [message].
  final String boldPrefix;
  final String timestamp;
  final bool isUnread;

  /// Optional override for the avatar circle's background (e.g. a red tint
  /// for a blocked-content notification). Defaults to [AppColors.secondary].
  final Color? avatarBackgroundColor;

  const NotificationItem({
    super.key,
    required this.avatar,
    required this.boldPrefix,
    required this.message,
    required this.timestamp,
    this.isUnread = true,
    this.avatarBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unread dot
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

        // Avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: avatarBackgroundColor ?? AppColors.secondary,
          child: ClipOval(child: avatar),
        ),
        const SizedBox(width: 14),

        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message with bold prefix
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(text: '$boldPrefix '),
                    TextSpan(
                      text: message,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF333333),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Timestamp
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
