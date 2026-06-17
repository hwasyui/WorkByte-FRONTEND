import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads [url] with an optional JWT [token] to a temp file and returns it.
/// Returns null if the download fails.
Future<File?> downloadToTempFile(String url, {String? token}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final headers = token != null ? {'Authorization': 'Bearer $token'} : <String, String>{};
  final response = await http.get(uri, headers: headers);
  if (response.statusCode != 200) return null;
  final tempDir = await getTemporaryDirectory();
  final fileName = uri.pathSegments.lastOrNull ?? 'audio';
  final tempFile = File('${tempDir.path}/$fileName');
  await tempFile.writeAsBytes(response.bodyBytes);
  return tempFile;
}

Future<void> openDocumentFromUrl(
  BuildContext context,
  String url, {
  String? token,
  String? fileName,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid document URL')),
    );
    return;
  }

  if (!context.mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    final headers = token != null ? {'Authorization': 'Bearer $token'} : <String, String>{};
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}');
    }

    final name = fileName ?? uri.pathSegments.lastOrNull ?? 'document';
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$name';

    await File(filePath).writeAsBytes(response.bodyBytes);

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open document: $e')),
    );
  }
}
