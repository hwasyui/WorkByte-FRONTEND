import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_post_provider.dart';
import 'success.dart';

class PostNewJobSummary extends StatefulWidget {
  const PostNewJobSummary({super.key});

  @override
  PostNewJobSummaryState createState() => PostNewJobSummaryState();
}

class PostNewJobSummaryState extends State<PostNewJobSummary> {
  static const Color _primary = Color(0xFF00AAA8);
  bool _isSubmitting = false;

  Future<void> _onPostJob() async {
    setState(() => _isSubmitting = true);

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

    for (final roleData in provider.draftRoles) {
      final payload = Map<String, dynamic>.from(roleData);
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
                // ── Header ────────────────────────────────────────
                Stack(
                  clipBehavior: Clip.none,
                  children: [
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
                            padding: EdgeInsets.only(bottom: 57, left: 29),
                            child: Text(
                              'Summary',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 29,
                      child: Text(
                        draft['project_type'] == 'team' ? 'Team' : 'Individual',
                        style: const TextStyle(
                          color: Color(0xFFB5B4B4),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                _buildRow('Title', draft['job_title'] ?? ''),
                _buildRow('Description', draft['job_description'] ?? ''),

                if (draft['working_days'] != null)
                  _buildRow('Working days', '${draft['working_days']} days'),

                if (draft['deadline'] != null)
                  _buildRow('Deadline', draft['deadline'] as String),

                // ── Roles ──────────────────────────────────────────
                if (roles.isNotEmpty) ...[
                  _sectionLabel('Roles'),
                  for (final role in roles)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 8,
                        left: 29,
                        right: 29,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            role['role_title'] as String? ?? '',
                            style: const TextStyle(
                              color: Color(0xFFB5B4B4),
                              fontSize: 12,
                            ),
                          ),
                          if (role['role_budget'] != null)
                            Text(
                              'Rp. ${(role['role_budget'] as double).toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFFB5B4B4),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],

                // ── Post Button ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 29),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _onPostJob,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
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

  Widget _sectionLabel(String text) => Container(
    margin: const EdgeInsets.only(bottom: 8, left: 29),
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
