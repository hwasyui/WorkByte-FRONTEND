import 'dart:io';
import '../../core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/job_post_provider.dart';
import '../../../../models/job_file_model.dart';
import 'summary.dart';
import '../../widgets/post_job_loading_view.dart';

class PostNewJobFiles extends StatefulWidget {
  const PostNewJobFiles({super.key});

  @override
  State<PostNewJobFiles> createState() => _PostNewJobFilesState();
}

class _PostNewJobFilesState extends State<PostNewJobFiles> {
  static const Color _primary = AppColors.primary;
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF16A34A);
  static const Color _danger = Color(0xFFE11D48);
  static const Color _warning = Color(0xFFF59E0B);

  // Each entry: { file_name, file_type, file_size, local_path, file_url,
  //               job_file_id, status: 'uploading' | 'uploaded' | 'error' }
  final List<Map<String, dynamic>> _files = [];
  bool _isHydrating = false;
  bool _isScreenReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreFiles();
    });
  }

  Future<void> _restoreFiles() async {
    _isHydrating = true;
    final provider = context.read<JobPostProvider>();
    final token = context.read<AuthProvider>().token;
    final jobPostId = provider.currentDraftJobPostId;

    final restored = <Map<String, dynamic>>[];

    // 1. Pull anything already persisted on the backend for this job post.
    if (jobPostId != null &&
        jobPostId.isNotEmpty &&
        token != null &&
        token.isNotEmpty) {
      await provider.fetchJobFiles(token, jobPostId);
      for (final f in provider.filesForJob(jobPostId)) {
        restored.add({
          'job_file_id': f.jobFileId,
          'file_name': f.fileName,
          'file_type': f.fileType,
          'file_size': f.fileSize,
          'file_url': f.fileUrl,
          'local_path': null,
          'status': 'uploaded',
        });
      }
    }

    // 2. Merge in any locally-picked entries not yet uploaded (e.g. an
    // upload that failed or never completed before leaving the screen).
    for (final f in provider.draftFiles) {
      final alreadyUploaded = f['job_file_id'] != null;
      final alreadyRestored = restored.any(
        (r) => r['job_file_id'] != null && r['job_file_id'] == f['job_file_id'],
      );
      if (!alreadyUploaded && !alreadyRestored) {
        restored.add({...f, 'status': f['status'] ?? 'error'});
      }
    }

    if (!mounted) return;
    setState(() {
      _files
        ..clear()
        ..addAll(restored);
      _isScreenReady = true;
    });
    _isHydrating = false;
    _syncToProvider();
  }

  void _syncToProvider() {
    if (_isHydrating) return;
    context.read<JobPostProvider>().setDraftFiles(_files);
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

    final newEntries = <Map<String, dynamic>>[];
    for (final picked in result.files) {
      if (picked.path == null) continue;
      final name = picked.name;
      final ext = name.contains('.')
          ? name.rsplit('.').last.toLowerCase()
          : 'bin';
      final alreadyAdded = _files.any((f) => f['local_path'] == picked.path);
      if (alreadyAdded) continue;
      newEntries.add({
        'file_name': name,
        'file_type': ext,
        'file_size': picked.size,
        'local_path': picked.path!,
        'file_url': null,
        'job_file_id': null,
        'status': 'uploading',
      });
    }

    if (newEntries.isEmpty) return;

    setState(() => _files.addAll(newEntries));
    _syncToProvider();

    for (final entry in newEntries) {
      _uploadFile(entry);
    }
  }

  Future<void> _uploadFile(Map<String, dynamic> entry) async {
    final token = context.read<AuthProvider>().token;
    final provider = context.read<JobPostProvider>();
    final jobPostId = provider.currentDraftJobPostId;
    final localPath = entry['local_path'] as String?;

    if (token == null ||
        token.isEmpty ||
        jobPostId == null ||
        jobPostId.isEmpty ||
        localPath == null) {
      _updateEntry(entry, {'status': 'error'});
      return;
    }

    try {
      final JobFileModel? uploaded = await provider.uploadSingleJobFile(
        token,
        jobPostId,
        File(localPath),
      );

      if (!mounted) return;

      if (uploaded == null) {
        _updateEntry(entry, {'status': 'error'});
        return;
      }

      _updateEntry(entry, {
        'job_file_id': uploaded.jobFileId,
        'file_url': uploaded.fileUrl,
        'status': 'uploaded',
      });
    } catch (_) {
      if (mounted) _updateEntry(entry, {'status': 'error'});
    }
  }

  void _updateEntry(Map<String, dynamic> entry, Map<String, dynamic> patch) {
    final index = _files.indexOf(entry);
    if (index == -1) return;
    setState(() => _files[index] = {..._files[index], ...patch});
    _syncToProvider();
  }

  Future<void> _retryUpload(int index) async {
    setState(() => _files[index] = {..._files[index], 'status': 'uploading'});
    _syncToProvider();
    await _uploadFile(_files[index]);
  }

  Future<void> _removeFile(int index) async {
    final entry = _files[index];
    final jobFileId = entry['job_file_id'] as String?;
    final provider = context.read<JobPostProvider>();
    final token = context.read<AuthProvider>().token;
    final jobPostId = provider.currentDraftJobPostId;

    if (jobFileId != null &&
        jobFileId.isNotEmpty &&
        token != null &&
        token.isNotEmpty &&
        jobPostId != null &&
        jobPostId.isNotEmpty) {
      await provider.deleteJobFile(token, jobFileId, jobPostId);
    }

    if (!mounted) return;
    setState(() => _files.removeAt(index));
    _syncToProvider();
  }

  bool get _isAnyUploading => _files.any((f) => f['status'] == 'uploading');

  void _onNext() {
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
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: !_isScreenReady
                ? const PostJobLoadingView(label: 'Loading attachments...')
                : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepProgress(),
                  _buildSectionLabel('Attachments'),
                  _buildIntroText(
                    'Attach reference files for freelancers (briefs, mockups, NDAs, etc.)',
                  ),
                  const SizedBox(height: 12),
                  _buildUploadCard(),
                  const SizedBox(height: 4),
                  _buildInfoBanner(
                    'PDF, DOC, PNG, JPG, ZIP — max 50MB each. Files upload automatically as you attach them.',
                  ),
                  const SizedBox(height: 8),
                  if (_files.isNotEmpty) ...[
                    _buildFileCountLabel(),
                    const SizedBox(height: 10),
                    ..._files.asMap().entries.map(
                      (e) => _buildFileCard(e.key, e.value),
                    ),
                  ] else
                    _buildEmptyState(),
                ],
              ),
            ),
          ),
          if (_isScreenReady) _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _primary,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            top: -20,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(right: 24, top: 52, child: _buildDotGrid()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      'Post new job',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      'Attachments (Optional)',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotGrid() {
    return Column(
      children: List.generate(
        4,
        (row) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: List.generate(
              3,
              (col) => Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step progress ─────────────────────────────────────────────────
  Widget _buildStepProgress() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: const [
          _StepPill(
            index: 1,
            label: 'Job detail',
            active: false,
            completed: true,
          ),
          SizedBox(width: 8),
          Expanded(child: Divider(color: _border, thickness: 1)),
          SizedBox(width: 8),
          _StepPill(index: 2, label: 'Role', active: false, completed: true),
          SizedBox(width: 8),
          Expanded(child: Divider(color: _border, thickness: 1)),
          SizedBox(width: 8),
          _StepPill(
            index: 3,
            label: 'Attachment',
            active: true,
            completed: false,
          ),
        ],
      ),
    );
  }

  // ── Section helpers ───────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 4, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: _textDark,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildIntroText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Text(
        text,
        style: const TextStyle(color: _textMuted, fontSize: 12.5, height: 1.4),
      ),
    );
  }

  Widget _buildInfoBanner(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: _primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Upload card ────────────────────────────────────────────────────
  Widget _buildUploadCard() {
    return GestureDetector(
      onTap: _pickFiles,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(left: 20, right: 20),
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _primary.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                color: _primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap to attach files',
              style: TextStyle(
                color: _textDark,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'You can select multiple files at once',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── File list ──────────────────────────────────────────────────────
  Widget _buildFileCountLabel() {
    final uploadedCount = _files.where((f) => f['status'] == 'uploaded').length;
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Text(
        '${_files.length} file${_files.length == 1 ? '' : 's'} selected · $uploadedCount uploaded',
        style: const TextStyle(
          color: _textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'uploading':
        return 'Uploading...';
      case 'uploaded':
        return 'Uploaded';
      case 'error':
        return 'Upload failed · tap to retry';
      default:
        return '';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'uploading':
        return _warning;
      case 'uploaded':
        return _success;
      case 'error':
        return _danger;
      default:
        return _textMuted;
    }
  }

  Widget _buildFileCard(int index, Map<String, dynamic> f) {
    final size = f['file_size'] as int?;
    final status = f['status'] as String? ?? 'uploaded';
    final file = JobFileModel(
      jobFileId: f['job_file_id'] ?? '',
      jobPostId: '',
      fileUrl: f['file_url'] ?? '',
      fileType: f['file_type'] ?? '',
      fileName: f['file_name'] ?? '',
      fileSize: f['file_size'],
    );

    final type = file.resolvedFileType;

    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: status == 'error' ? _danger.withOpacity(0.4) : _border,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconForType(type), color: _primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f['file_name'] as String,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _textDark,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 5,
                  children: [
                    if (status == 'uploading')
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: _warning,
                        ),
                      )
                    else
                      Icon(
                        status == 'uploaded'
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        size: 12,
                        color: _statusColor(status),
                      ),

                    GestureDetector(
                      onTap: status == 'error'
                          ? () => _retryUpload(index)
                          : null,
                      child: Text(
                        size != null
                            ? '${_statusLabel(status)} · ${_formatSize(size)}'
                            : _statusLabel(status),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _statusColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Text(
              type.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                color: _textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _removeFile(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Color(0xFFE11D48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 4),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.folder_off_outlined,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No files attached yet. You can skip this step and add files later.',
              style: TextStyle(color: _textMuted, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isAnyUploading ? null : _onNext,
              icon: _isAnyUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                _isAnyUploading ? 'Uploading files...' : 'Next: Summary',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: _onSkip,
              child: const Text(
                'Skip this step',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.index,
    required this.label,
    required this.active,
    required this.completed,
  });

  final int index;
  final String label;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    const primary = AppColors.primary;
    final Color bg = completed
        ? const Color(0xFFEAF8EE)
        : active
        ? primary.withOpacity(0.10)
        : const Color(0xFFF3F4F6);
    final Color fg = completed
        ? const Color(0xFF16A34A)
        : active
        ? primary
        : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: completed
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                : Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
