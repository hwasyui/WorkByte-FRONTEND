import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// True if [message] is a harmful-text-block rejection from the backend.
/// Every synchronous harmful-text rejection (profile name/title/bio via
/// PUT /freelancers/{id}, new skill names via POST /skills) always contains
/// the phrase "flagged for" - see admin_moderation.py's _reject_for() and
/// skill_routes.py's inline scan.
bool isHarmfulBlockMessage(String message) =>
    message.toLowerCase().contains('flagged for');

/// Shows a clear "Content Blocked" dialog for a harmful-text rejection. The
/// backend message is already a complete, human-readable sentence (e.g.
/// "Your profile couldn't be saved. It was flagged for toxicity, insults."),
/// so it's shown directly rather than re-parsed into a label list.
Future<void> showHarmfulBlockDialog(
  BuildContext context, {
  required String message,
  String title = 'Content Blocked',
}) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.block_rounded, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF374151),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Please revise the content and try again.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'OK',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

/// Shows either the harmful-block dialog (if [message] looks like a
/// harmful-text rejection) or a plain SnackBar with [message] as the reason.
/// Use this instead of a hardcoded generic "Failed" string so the real
/// backend error always reaches the user.
void showErrorFeedback(
  BuildContext context, {
  required String message,
  String blockedTitle = 'Content Blocked',
}) {
  if (isHarmfulBlockMessage(message)) {
    showHarmfulBlockDialog(context, message: message, title: blockedTitle);
    return;
  }
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}
