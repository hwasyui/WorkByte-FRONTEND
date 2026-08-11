import 'dart:html' as html;

Future<void> openBytesInBrowser(
  List<int> bytes,
  String fileName,
  String mimeType,
) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  // Give the new tab a moment to pick up the blob before revoking it.
  Future.delayed(
    const Duration(minutes: 1),
    () => html.Url.revokeObjectUrl(url),
  );
}
