import 'dart:io';
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
  static const Color _primary = Color(0xFF00AAA8);
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

      // Post skill metadata for this role
      final skillMeta = provider.draftRoleSkillMeta[i] ?? {};
      for (final entry in skillMeta.entries) {
        await provider.createRoleSkill(token, {
          'job_role_id': roleCreated.jobRoleId,
          'skill_id': entry.key,
          'importance_level': entry.value['importance_level'] ?? 'required',
          'is_required':
              entry.value['importance_level'] == 'required', // ← derived
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
            // ← add back null check
            await provider.createJobFile(token, {
              'job_post_id': created.jobPostId,
              'file_name': uploaded['file_name'],
              'file_url': uploaded['file_url'],
              'file_type': uploaded['file_type'],
              'file_size': uploaded['file_size'],
            });
          }
        } catch (e) {
          // Non-fatal: show warning but continue
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Warning: could not upload ${fileData['file_name']}: $e',
                ),
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
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: const Color(0xFFFFFFFF),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 27),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────
                Container(
                  color: _primary,
                  padding: const EdgeInsets.only(top: 23),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.only(bottom: 15, left: 18),
                          child: Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 7, left: 29),
                        child: Text(
                          'Post new job',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 20, left: 29),
                        child: Text(
                          'Summary',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ── Job detail rows ───────────────────────────────────
                _buildRow('Title', draft['job_title'] ?? ''),
                _buildRow('Description', draft['job_description'] ?? ''),
                _buildRow(
                  'Project Type',
                  _capitalize(draft['project_type'] ?? ''),
                ),
                if (draft['working_days'] != null)
                  _buildRow('Working Days', '${draft['working_days']} days'),
                if (draft['deadline'] != null)
                  _buildRow('Deadline', draft['deadline'] as String),
                if (draft['experience_level'] != null)
                  _buildRow(
                    'Experience Level',
                    _capitalize(draft['experience_level'] as String),
                  ),
                if (draft['project_scope'] != null)
                  _buildRow(
                    'Project Scope',
                    _capitalize(draft['project_scope'] as String),
                  ),

                // ── Roles + Skills ────────────────────────────────────
                if (roles.isNotEmpty) ...[
                  _sectionLabel('Roles'),
                  ...roles.asMap().entries.map((e) {
                    final role = e.value;
                    final skillNames = skillNamesMap[e.key] ?? [];
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 14,
                        left: 29,
                        right: 29,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF0F0F1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    role['role_title'] as String? ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ),
                                if (role['role_budget'] != null)
                                  Text(
                                    '${role['budget_currency'] ?? 'IDR'} ${(role['role_budget'] as double).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF00AAA8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            if (skillNames.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: skillNames
                                    .map(
                                      (name) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE6F7F7),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF00AAA8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ] else
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  'No skills specified',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFB5B4B4),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                // ── Attachments ───────────────────────────────────────
                if (files.isNotEmpty) ...[
                  _sectionLabel(
                    'Attachments (${files.length} file${files.length == 1 ? '' : 's'})',
                  ),
                  ...files.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 8,
                        left: 29,
                        right: 29,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF0F0F1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.attach_file,
                              size: 14,
                              color: Color(0xFF00AAA8),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                f['file_name'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF333333),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              (f['file_type'] as String).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFB5B4B4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 16),

                // ── Submit status ─────────────────────────────────────
                if (_isSubmitting && _submitStatus.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: Text(
                        _submitStatus,
                        style: const TextStyle(
                          color: Color(0xFF00AAA8),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),

                // ── Post button ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 29),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _onPostJob,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _primary.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Post new job',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _sectionLabel(String text) => Container(
    margin: const EdgeInsets.only(bottom: 10, left: 29, top: 4),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF7D7D7D),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildRow(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        margin: const EdgeInsets.only(bottom: 6, left: 29),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7D7D7D),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.only(bottom: 20, left: 29, right: 44),
        width: double.infinity,
        child: Text(
          value,
          style: const TextStyle(color: Color(0xFFB5B4B4), fontSize: 12),
        ),
      ),
    ],
  );
}
