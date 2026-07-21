import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:workbyte_app/widgets/file_viewer.dart';
import 'package:workbyte_app/widgets/app_toast.dart';
import 'package:workbyte_app/services/session_guard.dart';

String get _backendBase =>
    (dotenv.env['BACKEND'] ?? '').replaceAll(RegExp(r'/$'), '');

/// Downloads [url] with an optional JWT [token] to a temp file and returns it.
/// Returns null if the download fails.
bool isOurBackendUrl(String url) =>
    _backendBase.isNotEmpty && url.startsWith(_backendBase);

Future<File?> downloadToTempFile(String url, {String? token}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final headers = (token != null && isOurBackendUrl(url))
      ? {'Authorization': 'Bearer $token'}
      : <String, String>{};
  final response = await http.get(uri, headers: headers);
  if (isOurBackendUrl(url)) SessionGuard.check(response);
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
  Future<String?> Function()? onRefreshToken,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    if (!context.mounted) return;
    AppToast.error('Invalid document URL');
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
    final isBackend = isOurBackendUrl(url);
    var headers = (token != null && isBackend)
        ? {'Authorization': 'Bearer $token'}
        : <String, String>{};
    var response = await http.get(uri, headers: headers);

    if (response.statusCode == 401 && isBackend && onRefreshToken != null) {
      final newToken = await onRefreshToken();
      if (newToken != null) {
        headers = {'Authorization': 'Bearer $newToken'};
        response = await http.get(uri, headers: headers);
      }
    }

    if (isBackend) SessionGuard.check(response);

    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}');
    }

    final name = fileName ?? uri.pathSegments.lastOrNull ?? 'document';
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$name';

    await File(filePath).writeAsBytes(response.bodyBytes);

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FileViewerScreen(filePath: filePath, fileName: name),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    AppToast.error('Could not open document: $e');
  }
}
