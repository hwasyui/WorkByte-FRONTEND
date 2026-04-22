import 'dart:io';
import '../../core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_post_provider.dart';
import '../../services/upload_service.dart';
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
      _submitStatus = 'Creating job...';
    });

    final provider = context.read<JobPostProvider>();
    final token = context.read<AuthProvider>().token!;
    final draft = provider.draftJobData;

    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft data missing. Please start over.')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    // ── 1. Create job post ──────────────────────────────────────────
    final created = await provider.createJobPost(token, {
      ...draft,
      'status': 'active',
    });

    if (!mounted) return;
    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to create job post')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    // ── 2. Create roles + their skills ─────────────────────────────
    setState(() => _submitStatus = 'Saving roles...');
    for (int i = 0; i < provider.draftRoles.length; i++) {
      final payload = Map<String, dynamic>.from(provider.draftRoles[i]);
      payload['job_post_id'] = created.jobPostId;

      final roleCreated = await provider.createJobRole(token, payload);
      if (!mounted) return;
      if (roleCreated == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to create role')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final skillMeta = provider.draftRoleSkillMeta[i] ?? {};
      for (final entry in skillMeta.entries) {
        await provider.createRoleSkill(token, {
          'job_role_id': roleCreated.jobRoleId,
          'skill_id': entry.key,
          'importance_level': entry.value['importance_level'] ?? 'required',
          'is_required': entry.value['importance_level'] == 'required',
        });
        if (!mounted) return;
      }
    }

    // ── 3. Upload files then create records ─────────────────────────
    final draftFiles = provider.draftFiles;
    if (draftFiles.isNotEmpty) {
      setState(() => _submitStatus = 'Uploading files...');
      final uploadService = UploadService();

      for (final fileData in draftFiles) {
        final localPath = fileData['local_path'] as String?;
        if (localPath == null) continue;

        try {
          final uploaded = await uploadService.uploadFile(
            token,
            File(localPath),
            bucket: 'job-files',
          );

          if (uploaded != null) {
            await provider.createJobFile(token, {
              'job_post_id': created.jobPostId,
              'file_name': uploaded['file_name'],
              'file_url': uploaded['file_url'],
              'file_type': uploaded['file_type'],
              'file_size': uploaded['file_size'],
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Warning: could not upload ${fileData['file_name']}: $e'),
                backgroundColor: const Color(0xFFFF9800),
              ),
            );
          }
        }
      }
    }

    provider.clearDraft();
    setState(() => _isSubmitting = false);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Frame1()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobPostProvider>();
    final draft = provider.draftJobData ?? {};
    final roles = provider.draftRoles;
    final skillNamesMap = provider.draftRoleSkillNames;
    final files = provider.draftFiles;

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
                    _buildRow('Title', draft['job_title'] ?? '', Icons.description_outlined),
                    _buildRow('Description', draft['job_description'] ?? '', Icons.article_outlined),
                    _buildRow('Project Type', _capitalize(draft['project_type'] ?? ''), Icons.person_outline),
                    if (draft['working_days'] != null)
                      _buildRow('Working Days', '${draft['working_days']} days', Icons.calendar_today_outlined),
                    if (draft['deadline'] != null)
                      _buildRow('Deadline', draft['deadline'] as String, Icons.calendar_today_outlined),
                    if (draft['experience_level'] != null)
                      _buildRow('Experience Level', _capitalize(draft['experience_level'] as String), Icons.bar_chart_outlined),
                    if (draft['project_scope'] != null)
                      _buildRow('Project Scope', _capitalize(draft['project_scope'] as String), Icons.gps_fixed),

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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${role['budget_currency'] ?? 'IDR'} ${(role['role_budget'] as double).toStringAsFixed(0)}',
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
                        padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10),
                        child: Text(
                          'Attachments (${files.length} file${files.length == 1 ? '' : 's'})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ...files.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 20, right: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.attach_file, size: 16, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    f['file_name'] as String,
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  (f['file_type'] as String).toUpperCase(),
                                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    // ── Submit status ───────────────────────────────
                    if (_isSubmitting && _submitStatus.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 4),
                        child: Center(
                          child: Text(
                            _submitStatus,
                            style: const TextStyle(color: AppColors.primary, fontSize: 12),
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
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
          Positioned(
            right: 24,
            top: 52,
            child: _buildDotGrid(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
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
        const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 20, endIndent: 20),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
