// Stub for non-web platforms. openDocumentFromUrl only calls this when
// kIsWeb is true, so this body never actually runs - it exists purely so
// the conditional import below has something to resolve to on mobile/desktop.
Future<void> openBytesInBrowser(
  List<int> bytes,
  String fileName,
  String mimeType,
) async {}
