/// Single place that decides how much of the Harmful Text Detection classifier's
/// output is allowed to reach a client or a freelancer.
///
/// Policy: end users are told *that* an automated safety check blocked their
/// content and what to do next - never *which* category the model fired on.
/// Naming the label ("Identity Hate", "Obscene") turns a false positive into an
/// accusation against a real person, and it hands anyone probing the filter a
/// per-attempt signal to iterate against until they slip through. The label
/// also has little repair value on its own: it never points at the offending
/// words, so the user still has to reread their own text either way.
///
/// Raw labels and per-label scores are not hidden from everyone - they stay on
/// the admin moderation queue, which is where a human decides whether the model
/// was actually right.
library;

/// Wording the backend uses when a write is rejected by the harmful-text gate -
/// every rejection message names the system ("...flagged by Harmful Text
/// Detection"), so one marker covers DM, proposals and contracts.
///
/// Pre-rename phrasings were removed once the stored rows were migrated; there
/// is no longer any text in the system that says "harmful content".
///
/// If the backend's rejection copy ever stops containing this phrase, the check
/// silently starts returning false. That fragility is why
/// [isModerationBlockedBody] is preferred wherever the response body is in reach.
const _moderationBlockMarkers = ['harmful text'];

/// Value the backend puts in the `blocked_by` key of a harmful-text rejection
/// body: `ResponseSchema.error(msg, 400, extra={"blocked_by": "harmful_text"})`.
///
/// This is a wire value, not display copy - it must track the backend exactly.
/// Anything comparing against `blocked_by` must use this constant rather than
/// its own literal, so a backend rename is a one-line change here instead of a
/// hunt through the app.
const kModerationBlockedBy = 'harmful_text';

/// True when a decoded error body carries the backend's structured moderation
/// flag.
///
/// Prefer this over [looksLikeModerationBlock] wherever the raw response body is
/// still in reach: the flag survives any rewording of the message, whereas
/// matching the sentence quietly stops working the next time the copy changes.
/// The text check remains as a fallback for the paths that only ever see a
/// message string.
bool isModerationBlockedBody(dynamic body) =>
    body is Map && body['blocked_by'] == kModerationBlockedBy;

/// True when [message] is a harmful-text rejection rather than an ordinary
/// failure, so the caller can swap a raw error toast for the explanatory
/// blocked-content dialog.
///
/// Fallback for callers that no longer have the response body. Where the body is
/// available, use [isModerationBlockedBody] instead.
bool looksLikeModerationBlock(String? message) {
  if (message == null || message.trim().isEmpty) return false;
  final lower = message.toLowerCase();
  return _moderationBlockMarkers.any(lower.contains);
}

/// Every spelling of a classifier category the backend could put in prose - the
/// raw model labels (toxic, identity_hate) and the humanised forms
/// (obscenity, identity-based hate speech) it used to map them to.
const _labelAlternatives =
    r'identity[-_ ]based hate speech'
    r'|identity[-_ ]hate'
    r'|severe[-_ ]toxic(?:ity)?'
    r'|toxicity|toxic'
    r'|obscenity|obscene'
    r'|threats|threat'
    r'|insults|insult';

/// One label, or several joined by commas / "and" / "&".
const _labelList =
    '(?:$_labelAlternatives)'
    '(?:\\s*(?:,|and|&)\\s*(?:$_labelAlternatives))*';

/// "... flagged for toxicity, insults" -> "... flagged by Harmful Text
/// Detection".
final _flaggedForLabels = RegExp(
  '(flagged|rejected)\\s+(?:for|as)\\s+$_labelList',
  caseSensitive: false,
);

/// "... detected as harmful (toxic, insult)." -> "... detected as harmful."
/// Only strips the parentheses when they hold nothing but labels, so an
/// admin's own aside in brackets is left alone.
final _parentheticalLabels = RegExp('\\s*\\($_labelList\\)', caseSensitive: false);

/// Strips the classifier's categories out of a message the backend wrote,
/// leaving the rest of the sentence intact.
///
/// No longer needed for stored rows - those were migrated. It stays as a
/// boundary guard: the backend deliberately keeps returning labels as structured
/// fields on seven response paths, and prose that named them is exactly the
/// regression this codebase already shipped once. Applied at the model boundary
/// (NotificationModel.fromJson, UserModel.fromJson), it means a backend that
/// starts interpolating labels again cannot reach a widget, rather than the leak
/// depending on nobody making that mistake twice.
String redactModerationLabels(String text) {
  if (text.trim().isEmpty) return text;
  return text
      .replaceAllMapped(
        _flaggedForLabels,
        (m) => '${m.group(1)} by Harmful Text Detection',
      )
      .replaceAll(_parentheticalLabels, '')
      .replaceAll(RegExp(r' {2,}'), ' ')
      .trim();
}

/// [redactModerationLabels] applied to a nullable field, preserving null.
String? redactModerationLabelsOrNull(String? text) =>
    text == null ? null : redactModerationLabels(text);

/// Wire value the backend writes to `job_post.closure_reason` when Harmful Text
/// Detection closes a post (DEFAULT_CLOSURE_REASON_CONTENT in admin_functions.py),
/// and the matching notification type.
///
/// Wire values, not display copy. Compare against these constants rather than
/// writing the literal again - the previous spelling ("content_violation") was
/// duplicated across six screens, so renaming it on the backend broke the banner,
/// the badge and the admin filter silently and all at once.
const kClosureReasonHarmfulText = 'harmful_text';
const kClosureReasonScam = 'scam';
const kNotifJobClosedHarmfulText = 'job_closed_harmful_text';

/// True when the post was closed by Harmful Text Detection.
bool isHarmfulTextClosure(String? closureReason) =>
    (closureReason ?? '').toLowerCase() == kClosureReasonHarmfulText;

/// Closure reasons written by the automated pipeline rather than by a human
/// admin (DEFAULT_CLOSURE_REASON_* in admin_functions.py).
bool isAutomatedClosure(String? closureReason) {
  final reason = (closureReason ?? '').toLowerCase();
  return reason == kClosureReasonScam || reason == kClosureReasonHarmfulText;
}

/// The closure note as a job owner (or any other viewer) is allowed to see it.
///
/// Notes attached to an automated closure are a fixed sentence the backend
/// writes for every such closure (DEFAULT_CLOSURE_NOTE_CONTENT), so they add
/// nothing over the banner's own copy and the appeal button beside it - they are
/// dropped and the banner explains the closure instead.
///
/// A human admin's note is their own writing and is worth keeping, so it is
/// only run through [redactModerationLabels] in case they pasted a category in.
String? viewerFacingClosureNote({
  required String? closureReason,
  required String? closureNote,
}) {
  final note = closureNote?.trim();
  if (note == null || note.isEmpty) return null;
  if (isAutomatedClosure(closureReason)) return null;
  final redacted = redactModerationLabels(note);
  return redacted.isEmpty ? null : redacted;
}
