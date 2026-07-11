import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_keys.dart';
import '../../providers/notification_provider.dart';
import '../../screens/dashboard/notification.dart';

/// notif_types that represent a piece of the user's own content getting
/// auto-blocked by harmful-text moderation. Every one of these fires from an
/// async background scan (see education_functions.py / work_experience_
/// functions.py / job_post_functions.py / proposal_functions.py / portfolio_
/// functions.py's run_*_scan()), not a synchronous request failure - the
/// user finds out after the fact via this notification, not an error dialog
/// at submit time.
const _blockedNotifTypes = {
  'education_blocked',
  'work_experience_blocked',
  'job_post_blocked',
  'proposal_blocked',
  'portfolio_blocked',
};

/// Friendly, actionable one-liner per blocked content type, shown in the
/// banner instead of the raw notification body.
String _blockedActionLabel(String type) {
  switch (type) {
    case 'education_blocked':
      return 'Your education entry got blocked. Please revise or delete it and add a new one.';
    case 'work_experience_blocked':
      return 'Your work experience entry got blocked. Please revise or delete it and add a new one.';
    case 'job_post_blocked':
      return 'Your job post got blocked. Please revise it or close it and post a new one.';
    case 'proposal_blocked':
      return 'Your proposal got blocked. Please revise it and resubmit.';
    case 'portfolio_blocked':
      return 'Your portfolio item got blocked. Please revise or delete it and add a new one.';
    default:
      return 'Some of your content got blocked. Please revise it and try again.';
  }
}

/// Call this whenever a push notification is received while the app is
/// already running (see NotificationService's foreground message listener).
///
/// Always refreshes the live unread-count badge. If the notification is a
/// content-block AND the user isn't already looking at the Notifications
/// screen, also shows a disappearing red banner explaining what happened -
/// otherwise a blocked entry silently sits there looking identical to a
/// normal one until the user happens to open Notifications.
void handleForegroundNotification({
  required String? type,
  required String? title,
  required String? body,
}) {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  context.read<NotificationProvider>().fetchUnreadCount();

  if (type == null || !_blockedNotifTypes.contains(type)) return;
  if (NotificationScreen.isOpen) return; // already looking at the real list

  scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xFFDC2626),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.block_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _blockedActionLabel(type),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        label: 'VIEW',
        textColor: Colors.white,
        onPressed: () => navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationScreen()),
        ),
      ),
    ),
  );
}
