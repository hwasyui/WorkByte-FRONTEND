library;

const _moderationBlockMarkers = ['harmful text'];

const kModerationBlockedBy = 'harmful_text';

bool isModerationBlockedBody(dynamic body) =>
    body is Map && body['blocked_by'] == kModerationBlockedBy;

bool looksLikeModerationBlock(String? message) {
  if (message == null || message.trim().isEmpty) return false;
  final lower = message.toLowerCase();
  return _moderationBlockMarkers.any(lower.contains);
}

const _labelAlternatives =
    r'identity[-_ ]based hate speech'
    r'|identity[-_ ]hate'
    r'|severe[-_ ]toxic(?:ity)?'
    r'|toxicity|toxic'
    r'|obscenity|obscene'
    r'|threats|threat'
    r'|insults|insult';

const _labelList =
    '(?:$_labelAlternatives)'
    '(?:\\s*(?:,|and|&)\\s*(?:$_labelAlternatives))*';

final _flaggedForLabels = RegExp(
  '(flagged|rejected)\\s+(?:for|as)\\s+$_labelList',
  caseSensitive: false,
);

final _parentheticalLabels = RegExp('\\s*\\($_labelList\\)', caseSensitive: false);

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

String? redactModerationLabelsOrNull(String? text) =>
    text == null ? null : redactModerationLabels(text);

const kClosureReasonHarmfulText = 'harmful_text';
const kClosureReasonScam = 'scam';
const kNotifJobClosedHarmfulText = 'job_closed_harmful_text';

bool isHarmfulTextClosure(String? closureReason) =>
    (closureReason ?? '').toLowerCase() == kClosureReasonHarmfulText;

bool isAutomatedClosure(String? closureReason) {
  final reason = (closureReason ?? '').toLowerCase();
  return reason == kClosureReasonScam || reason == kClosureReasonHarmfulText;
}

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
