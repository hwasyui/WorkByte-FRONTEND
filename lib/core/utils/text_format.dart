/// Converts a raw, backend-style value (snake_case or plain lowercase, e.g.
/// `'web_development'`, `'active'`, `'entry'`) into a human-readable Title
/// Case label (`'Web Development'`, `'Active'`, `'Entry'`) for display.
///
/// Returns [fallback] when [value] is null or blank.
String toTitleCase(String? value, {String fallback = ''}) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return fallback;
  return v
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
