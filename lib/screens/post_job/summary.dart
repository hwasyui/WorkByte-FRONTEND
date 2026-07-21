import 'dart:io';
import 'package:workbyte_app/models/job_file_model.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/file_viewer.dart';
import '../../../widgets/app_toast.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_post_provider.dart';
import 'success.dart';

class PostNewJobSummary extends StatefulWidget {
  const PostNewJobSummary({super.key});

  @override
  PostNewJobSummaryState createState() => PostNewJobSummaryState();
}

class PostNewJobSummaryState extends State<PostNewJobSummary> {
  static const Color _primary = AppColors.primary;
  bool _isSubmitting = false;
  String _submitStatus = '';

  Future<void> _onPostJob() async {
    setState(() {
      _isSubmitting = true;
      _submitStatus = 'Publishing job...';
    });

    final provider = context.read<JobPostProvider>();
    final token = context.read<AuthProvider>().token!;
    final draft = provider.draftJobData;

    if (draft == null) {
      AppToast.error('Draft data missing. Please start over.');
      setState(() => _isSubmitting = false);
      return;
    }

    final jobPostId = provider.currentDraftJobPostId;

    if (jobPostId == null || jobPostId.isEmpty) {
      AppToast.error('Draft job not found.');
      setState(() => _isSubmitting = false);
      return;
    }

    // Final save + publish the existing draft
    final updated = await provider.updateJobPost(
      token: token,
      jobPostId: jobPostId,
      data: {...draft, 'status': 'active'},
    );

    if (!mounted) return;

    if (updated == null) {
      AppToast.error(provider.error ?? 'Failed to publish job.');
      setState(() => _isSubmitting = false);
      return;
    }

    setState(() {
      _submitStatus = 'Finalizing...';
    });

    provider.clearDraft();

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Frame1()),
    );
  }

  Future<void> _openFile({
    String? localPath,
    String? url,
    required String fileName,
  }) async {
    try {
      String filePath;

      // Local draft file
      if (localPath != null && localPath.isNotEmpty) {
        filePath = localPath;
      }
      // Uploaded file
      else if (url != null && url.isNotEmpty) {
        AppToast.info('Downloading file...', duration: const Duration(seconds: 1));

        final response = await http.get(Uri.parse(url));

        if (response.statusCode != 200) {
          throw Exception('Failed to download file');
        }

        final dir = await getTemporaryDirectory();

        final file = File('${dir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes);

        filePath = file.path;
      } else {
        throw Exception('No file available');
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              FileViewerScreen(filePath: filePath, fileName: fileName),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      AppToast.error('Unable to open file.\n$e');
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<JobPostProvider>();

      final token = context.read<AuthProvider>().token!;

      final jobPostId = provider.currentDraftJobPostId;

      if (jobPostId != null && jobPostId.isNotEmpty) {
        await provider.fetchJobFiles(token, jobPostId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobPostProvider>();
    final draft = provider.draftJobData ?? {};
    final roles = provider.draftRoles;
    final skillNamesMap = provider.draftRoleSkillNames;
    final jobPostId =
        provider.currentDraftJobPostId ?? provider.draftJobData?['job_post_id'];

    final List<JobFileModel> files = provider.currentDraftJobPostId == null
        ? []
        : provider.filesForJob(provider.currentDraftJobPostId!);

    return Scaffold(
      backgroundColor: _primary,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Job detail rows ─────────────────────────────
                    _buildRow(
                      'Title',
                      draft['job_title'] ?? '',
                      Icons.description_outlined,
                    ),
                    _buildRow(
                      'Description',
                      draft['job_description'] ?? '',
                      Icons.article_outlined,
                    ),
                    _buildRow(
                      'Project Type',
                      _capitalize(draft['project_type'] ?? ''),
                      Icons.person_outline,
                    ),
                    if (draft['estimated_duration'] != null)
                      _buildRow(
                        'Estimated Duration',
                        '${draft['estimated_duration']}',
                        Icons.calendar_today_outlined,
                      ),
                    if (draft['deadline'] != null)
                      _buildRow(
                        'Deadline',
                        draft['deadline'] as String,
                        Icons.calendar_today_outlined,
                      ),
                    if (draft['experience_level'] != null)
                      _buildRow(
                        'Experience Level',
                        _capitalize(draft['experience_level'] as String),
                        Icons.bar_chart_outlined,
                      ),
                    // if (draft['project_scope'] != null)
                    //   _buildRow('Project Scope', _capitalize(draft['project_scope'] as String), Icons.gps_fixed),

                    // ── Roles ───────────────────────────────────────
                    if (roles.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
                        child: Text(
                          'Roles',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ...roles.asMap().entries.map((e) {
                        final role = e.value;
                        final skillNames = skillNamesMap[e.key] ?? [];
                        final title = role['role_title'] as String? ?? '';
                        final initials = title
                            .trim()
                            .split(' ')
                            .where((w) => w.isNotEmpty)
                            .take(2)
                            .map((w) => w[0].toUpperCase())
                            .join();

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        skillNames.isNotEmpty
                                            ? skillNames.join(', ')
                                            : 'No skills specified',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (role['role_budget'] != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${role['budget_currency'] ?? 'IDR'} ${((role['role_budget'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    // ── Attachments ─────────────────────────────────
                    if (files.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 20,
                          bottom: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.attach_file,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Attachments (${files.length})",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),

                      ...files.map((file) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _iconForType(file.resolvedFileType),
                                    color: AppColors.primary,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.fileName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        file.fileSizeFormatted,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    file.resolvedFileType.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                InkWell(
                                  onTap: () => _openFile(
                                    url: file.fileUrl,
                                    fileName: file.fileName,
                                  ),
                                  child: const Text(
                                    "View",
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ], // ── Submit status ───────────────────────────────
                    if (_isSubmitting && _submitStatus.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 4),
                        child: Center(
                          child: Text(
                            _submitStatus,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // ── Post button ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _onPostJob,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_outlined, size: 18),
                          label: const Text(
                            'Post new job',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(right: 24, top: 52, child: _buildDotGrid()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
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
                      'Summary',
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
                  color: Colors.white.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, IconData icon) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(
          height: 1,
          color: Color(0xFFF0F0F0),
          indent: 20,
          endIndent: 20,
        ),
      ],
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
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'uploaded':
        return const Color(0xFF16A34A);
      case 'uploading':
        return const Color(0xFFF59E0B);
      case 'error':
        return const Color(0xFFE11D48);
      default:
        return Colors.grey;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
