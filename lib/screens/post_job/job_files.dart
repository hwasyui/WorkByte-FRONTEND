import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../providers/job_post_provider.dart';
import 'summary.dart';

class PostNewJobFiles extends StatefulWidget {
  const PostNewJobFiles({super.key});

  @override
  State<PostNewJobFiles> createState() => _PostNewJobFilesState();
}

class _PostNewJobFilesState extends State<PostNewJobFiles> {
  static const Color _primary = Color(0xFF00AAA8);

  // Each entry: { file_name, file_type, file_size, local_path }
  // file_url is NOT set yet — that happens in summary.dart on submit
  final List<Map<String, dynamic>> _files = [];

  @override
  void initState() {
    super.initState();
    final existing = List<Map<String, dynamic>>.from(
      context.read<JobPostProvider>().draftFiles,
    );
    _files.addAll(existing);
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'png',
        'jpg',
        'jpeg',
        'zip',
        'rar',
      ],
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      for (final picked in result.files) {
        if (picked.path == null) continue;
        final name = picked.name;
        final ext = name.contains('.')
            ? name.rsplit('.').last.toLowerCase()
            : 'bin';
        // Avoid duplicates by path
        final alreadyAdded = _files.any((f) => f['local_path'] == picked.path);
        if (!alreadyAdded) {
          _files.add({
            'file_name': name,
            'file_type': ext,
            'file_size': picked.size,
            'local_path': picked.path!, // temporary, used on submit
            'file_url': null, // filled in by summary.dart
          });
        }
      }
    });
  }

  void _removeFile(int index) => setState(() => _files.removeAt(index));

  void _onNext() {
    context.read<JobPostProvider>().setDraftFiles(_files);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostNewJobSummary()),
    );
  }

  void _onSkip() {
    context.read<JobPostProvider>().setDraftFiles([]);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostNewJobSummary()),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Icons.image_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_outlined;
      default:
        return Icons.attach_file;
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Container(
              color: _primary,
              padding: const EdgeInsets.only(top: 23, bottom: 29),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 29),
                    child: Text(
                      'Post new job',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 29),
                    child: Text(
                      'Attachments (Optional)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(29, 24, 29, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attach reference files for freelancers (briefs, mockups, NDAs, etc.)',
                      style: TextStyle(color: Color(0xFF7D7D7D), fontSize: 11),
                    ),
                    const SizedBox(height: 20),

                    // ── Pick button ───────────────────────────────────
                    GestureDetector(
                      onTap: _pickFiles,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _primary),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              color: _primary,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap to attach files',
                              style: TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'PDF, DOC, PNG, JPG, ZIP — max 50MB each',
                              style: TextStyle(
                                color: Color(0xFFB5B4B4),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── File list ─────────────────────────────────────
                    if (_files.isNotEmpty) ...[
                      Text(
                        '${_files.length} file${_files.length == 1 ? '' : 's'} selected',
                        style: const TextStyle(
                          color: Color(0xFF7D7D7D),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._files.asMap().entries.map((e) {
                        final f = e.value;
                        final type = f['file_type'] as String? ?? '';
                        final size = f['file_size'] as int?;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF0F0F1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _iconForType(type),
                                  color: _primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f['file_name'] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF333333),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (size != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatSize(size),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFB5B4B4),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F0F1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  type.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF7D7D7D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _removeFile(e.key),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Color(0xFFB5B4B4),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),

            // ── Bottom buttons ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(29, 8, 29, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: _onSkip,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Color(0xFFB5B4B4),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on String {
  List<String> rsplit(String sep) {
    final idx = lastIndexOf(sep);
    if (idx == -1) return [this];
    return [substring(0, idx), substring(idx + 1)];
  }
}
