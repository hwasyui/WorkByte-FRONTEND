import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workbyte_app/providers/profile_provider.dart';
import '../../core/constants/colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/job_post_provider.dart';
import '../dashboard/dashboard.dart';
import 'job_detail.dart';
import '../../widgets/confirm_action_dialog.dart';
import '../../widgets/post_job_loading_view.dart';

class JobDraftsScreen extends StatefulWidget {
  const JobDraftsScreen({super.key});

  @override
  State<JobDraftsScreen> createState() => _JobDraftsScreenState();
}

class _JobDraftsScreenState extends State<JobDraftsScreen> {
  static const Color _primary = AppColors.primary;
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _success = Color(0xFF16A34A);
  static const Color _warning = Color(0xFFF59E0B);

  bool _loading = true;

  /// Tracks, per draft job post id, whether that draft already has at least
  /// one saved role. Populated in `_loadDrafts` since `JobPostProvider` only
  /// exposes a single shared `jobRoles` list (overwritten per fetch) rather
  /// than a per-job cache like it has for files.
  final Map<String, bool> _hasRoleByDraftId = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDrafts();
    });
  }

  Future<void> _loadDrafts() async {
    setState(() => _loading = true);

    final token = context.read<AuthProvider>().token;
    final clientId = context.read<ProfileProvider>().clientProfile?.clientId;

    if (token != null &&
        token.isNotEmpty &&
        clientId != null &&
        clientId.isNotEmpty) {
      final provider = context.read<JobPostProvider>();
      await provider.loadDraftJobs(token, clientId);

      _hasRoleByDraftId.clear();
      for (final draft in provider.draftJobPosts) {
        final draftId = (draft.jobPostId ?? '').toString();
        if (draftId.isEmpty) continue;

        await provider.fetchJobRoles(token, draftId);
        // Snapshot immediately: the next iteration's fetch will overwrite
        // provider.jobRoles.
        _hasRoleByDraftId[draftId] = provider.jobRoles.isNotEmpty;

        await provider.fetchJobFiles(token, draftId);
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _openDraft(String draftId) async {
    final token = context.read<AuthProvider>().token;
    final clientId = context.read<ProfileProvider>().clientProfile?.clientId;

    if (token != null &&
        token.isNotEmpty &&
        clientId != null &&
        clientId.isNotEmpty) {
      await context.read<JobPostProvider>().loadDraftJobById(
        token,
        clientId,
        draftId,
      );
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const PostNewJobJobDetail(restoreFromExistingDraft: true),
      ),
    );
  }

  Future<void> _createNewDraft() async {
    context.read<JobPostProvider>().clearDraft();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const PostNewJobJobDetail(restoreFromExistingDraft: false),
      ),
    );
  }

  Future<void> _deleteDraft(String draftId) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      icon: Icons.delete_outline_rounded,
      title: 'Delete draft?',
      message:
          'This removes the selected draft only. Other drafts will remain available.',
      confirmLabel: 'Delete',
      tone: ConfirmDialogTone.destructive,
    );
    if (!confirmed) return;

    final token = context.read<AuthProvider>().token;
    if (token != null && token.isNotEmpty) {
      await context.read<JobPostProvider>().deleteDraftJob(token, draftId);
    }
    _hasRoleByDraftId.remove(draftId);
    await _loadDrafts();
  }

  String _formatRelative(DateTime? date) {
    if (date == null) return 'Recently edited';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} hr ago';
    if (diff.inDays < 7)
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Returns (stepNumber, label) for a draft, based on whether it already
  /// has a saved role and/or uploaded files.
  ({int number, String label}) _stepForDraft(
    JobPostProvider provider,
    String draftId,
  ) {
    if (draftId.isNotEmpty) {
      final hasFiles = provider.filesForJob(draftId).isNotEmpty;
      if (hasFiles) return (number: 3, label: 'Step 3 of 3 · Attachment');

      final hasRole = _hasRoleByDraftId[draftId] ?? false;
      if (hasRole) return (number: 2, label: 'Step 2 of 3 · Role');
    }
    return (number: 1, label: 'Step 1 of 3 · Job detail');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobPostProvider>();
    final drafts = provider.draftJobPosts;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewDraft,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New draft'),
      ),
      body: Column(
        children: [
          _buildHeader(drafts.length),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDrafts,
              color: _primary,
              child: _loading
                  ? const PostJobLoadingView(label: 'Loading drafts...')
                  : drafts.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      children: [
                        _buildSummaryCard(drafts.length),
                        const SizedBox(height: 14),
                        ...drafts
                            .map((draft) => _buildDraftCard(provider, draft))
                            .toList(),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      color: _primary,
      width: double.infinity,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  'Your drafts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 4),
                child: Text(
                  '$count unfinished job post${count == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.folder_copy_outlined, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count saved draft${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Continue any unfinished post or start a new one without losing the others.',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftCard(JobPostProvider provider, dynamic draft) {
    final draftId = (draft.jobPostId ?? '').toString();
    final title = (draft.jobTitle ?? 'Untitled job post').toString();
    final projectType = (draft.projectType ?? 'individual').toString();
    DateTime? updatedAt;

    if (draft.updatedAt != null && draft.updatedAt.toString().isNotEmpty) {
      updatedAt = DateTime.tryParse(draft.updatedAt.toString());
    } else if (draft.createdAt != null &&
        draft.createdAt.toString().isNotEmpty) {
      updatedAt = DateTime.tryParse(draft.createdAt.toString());
    }

    final step = _stepForDraft(provider, draftId);
    final accent = step.number == 3
        ? _success
        : step.number == 2
        ? _warning
        : _primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.description_outlined, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last edited ${_formatRelative(updatedAt)}',
                      style: const TextStyle(color: _textMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'open') {
                    _openDraft(draftId);
                  } else if (value == 'delete') {
                    _deleteDraft(draftId);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'open', child: Text('Continue draft')),
                  PopupMenuItem(value: 'delete', child: Text('Delete draft')),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.more_vert_rounded, color: _textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(icon: Icons.layers_outlined, label: step.label),
              _chip(
                icon: Icons.people_outline_rounded,
                label: projectType == 'team'
                    ? 'Team project'
                    : 'Individual project',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteDraft(draftId),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE11D48),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openDraft(draftId),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Continue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _textDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: _primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No drafts yet',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start a new job post and we will save your progress here automatically across Job Detail, Role, and Attachment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _createNewDraft,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create new draft'),
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
            ],
          ),
        ),
      ],
    );
  }
}
