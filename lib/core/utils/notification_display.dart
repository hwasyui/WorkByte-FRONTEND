library;

import 'package:flutter/material.dart';

import 'moderation_display.dart';

const Color _accent = Color(0xFF6E6BF8);
const Color _alert = Color(0xFFDC2626);

/// Emoji, pictographs and decorative symbols (⭐, ★, ✅, 📦, 🚀, …).
/// Notification copy still arrives from the API with these baked into the
/// title and body; the list renders plain text only.
final RegExp _emojiPattern = RegExp(
  '['
  '\u{00A9}\u{00AE}\u{203C}\u{2049}\u{2122}\u{2139}'
  '\u{2600}-\u{27BF}\u{2934}\u{2935}\u{2B00}-\u{2BFF}'
  '\u{3030}\u{303D}\u{3297}\u{3299}'
  '\u{FE00}-\u{FE0F}\u{1F000}-\u{1FAFF}\u{200D}\u{20E3}'
  ']',
  unicode: true,
);

final RegExp _spaceBeforePunctuation = RegExp(r'\s+([.,!?;:])');

/// Drops emoji and tidies up the whitespace they leave behind.
String stripEmojis(String text) {
  if (text.trim().isEmpty) return text;
  return text
      .replaceAll(_emojiPattern, '')
      .replaceAllMapped(_spaceBeforePunctuation, (m) => m.group(1)!)
      .replaceAll(RegExp(r' {2,}'), ' ')
      .trim();
}

/// How one notification type is presented: a canonical title plus its icon.
///
/// The title lives here rather than coming from the API because the backend
/// phrases the same type differently depending on which code path sent it
/// (a `new_message` title is either "New Message" or the sender's name).
class NotificationPresentation {
  final String title;
  final IconData icon;
  final Color color;

  const NotificationPresentation({
    required this.title,
    required this.icon,
    required this.color,
  });
}

const Map<String, NotificationPresentation> _presentations = {
  // Messaging
  'new_message': NotificationPresentation(
    title: 'New message',
    icon: Icons.chat_bubble_outline,
    color: _accent,
  ),
  'thread_accepted': NotificationPresentation(
    title: 'Message request accepted',
    icon: Icons.mark_chat_read_outlined,
    color: _accent,
  ),

  // Proposals
  'new_proposal': NotificationPresentation(
    title: 'New proposal received',
    icon: Icons.description_outlined,
    color: _accent,
  ),
  'proposal_accepted': NotificationPresentation(
    title: 'Proposal accepted',
    icon: Icons.check_circle_outline,
    color: _accent,
  ),
  'proposal_rejected': NotificationPresentation(
    title: 'Proposal declined',
    icon: Icons.cancel_outlined,
    color: _accent,
  ),
  'role_filled': NotificationPresentation(
    title: 'Position filled',
    icon: Icons.person_off_outlined,
    color: _accent,
  ),
  'role_reopened': NotificationPresentation(
    title: 'Position open again',
    icon: Icons.person_search_outlined,
    color: _accent,
  ),

  // Contracts
  'contract_started': NotificationPresentation(
    title: 'Contract started',
    icon: Icons.handshake_outlined,
    color: _accent,
  ),
  'contract_cancelled': NotificationPresentation(
    title: 'Contract cancelled',
    icon: Icons.block_outlined,
    color: _alert,
  ),
  'contract_completed': NotificationPresentation(
    title: 'Contract completed',
    icon: Icons.task_alt_outlined,
    color: _accent,
  ),
  'work_submitted': NotificationPresentation(
    title: 'Work submitted',
    icon: Icons.upload_file_outlined,
    color: _accent,
  ),
  'revision_requested': NotificationPresentation(
    title: 'Revision requested',
    icon: Icons.edit_outlined,
    color: _accent,
  ),
  'contract_autoapprove_reminder': NotificationPresentation(
    title: 'Reminder: review pending work',
    icon: Icons.timer_outlined,
    color: _accent,
  ),
  'contract_autoapprove_final_warning': NotificationPresentation(
    title: 'Final reminder: review pending work',
    icon: Icons.timer_outlined,
    color: _alert,
  ),
  'contract_auto_approved': NotificationPresentation(
    title: 'Contract auto-approved',
    icon: Icons.auto_mode_outlined,
    color: _alert,
  ),
  'contract_overdue': NotificationPresentation(
    title: 'Contract past deadline',
    icon: Icons.event_busy_outlined,
    color: _alert,
  ),
  'contract_disputed': NotificationPresentation(
    title: 'Contract under dispute',
    icon: Icons.gavel_outlined,
    color: _alert,
  ),
  'dispute_resolved': NotificationPresentation(
    title: 'Dispute resolved',
    icon: Icons.balance_outlined,
    color: _alert,
  ),

  // Reviews
  'review_published': NotificationPresentation(
    title: 'New review received',
    icon: Icons.star_outline_rounded,
    color: _accent,
  ),
  'review_publish_confirmed': NotificationPresentation(
    title: 'Your review was published',
    icon: Icons.rate_review_outlined,
    color: _accent,
  ),
  'review_flagged': NotificationPresentation(
    title: 'Your review is under review',
    icon: Icons.hourglass_top_outlined,
    color: _accent,
  ),
  'review_suppressed': NotificationPresentation(
    title: 'Your review was not published',
    icon: Icons.visibility_off_outlined,
    color: _alert,
  ),

  // Moderation
  kNotifJobClosedHarmfulText: NotificationPresentation(
    title: 'Job post closed',
    icon: Icons.gpp_bad_rounded,
    color: _alert,
  ),
  'job_closed_scam': NotificationPresentation(
    title: 'Job post closed',
    icon: Icons.gpp_bad_rounded,
    color: _alert,
  ),
  'job_closed_admin': NotificationPresentation(
    title: 'Job post closed',
    icon: Icons.gpp_bad_rounded,
    color: _alert,
  ),
  'job_closed_reports': NotificationPresentation(
    title: 'Job post closed',
    icon: Icons.gpp_bad_rounded,
    color: _alert,
  ),
  'job_closed_admin_contract': NotificationPresentation(
    title: 'Job closed by admin',
    icon: Icons.gpp_bad_rounded,
    color: _alert,
  ),
};

/// Presentation for [type]. Unknown types fall back to the API-supplied
/// [apiTitle] so a newly added backend type still renders sensibly.
NotificationPresentation notificationPresentation(
  String type, {
  String? apiTitle,
}) {
  final known = _presentations[type];
  if (known != null) return known;

  final fallbackTitle = stripEmojis(redactModerationLabels(apiTitle ?? ''));
  return NotificationPresentation(
    title: fallbackTitle.isEmpty ? 'Notification' : fallbackTitle,
    icon: Icons.notifications_outlined,
    color: _accent,
  );
}

/// The body text to show under the canonical title.
///
/// `new_message` is the one type whose API title carries information: the
/// attachment path sends the sender's name as the title and the message
/// preview as the body, while the text path already prefixes the body with the
/// sender. Folding the name back in keeps both variants reading the same.
String notificationBody({
  required String type,
  required String apiTitle,
  required String apiBody,
}) {
  final body = stripEmojis(apiBody);
  if (type != 'new_message') return body;

  final title = stripEmojis(apiTitle);
  if (title.isEmpty || title.toLowerCase().startsWith('new message')) {
    return body;
  }
  return body.isEmpty ? title : '$title: $body';
}
