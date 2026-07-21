import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_post_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/job_post_service.dart';
import '../../services/proposal_service.dart';
import '../dashboard/dashboard.dart';
import '../../models/job_post_model.dart';
import '../job_client_view/job_detail.dart';
import '../post_job/job_detail.dart' show PostNewJobJobDetail;
import '../../widgets/confirm_action_dialog.dart';

class JobListScreen extends StatefulWidget {
  final String? initialQuery;

  const JobListScreen({super.key, this.initialQuery});

  @override
  JobListScreenState createState() => JobListScreenState();
}

class JobListScreenState extends State<JobListScreen> {
  static const Color _primary = AppColors.primary;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allJobs = [];
  List<Map<String, dynamic>> _filteredJobs = [];
  bool _isLoading = true;
  String _sortOption = 'Latest';

  // 👇 NEW: active status filter tab
  String _statusFilter = 'all';

  static const List<_StatusTab> _statusTabs = [
    _StatusTab(key: 'all', label: 'All'),
    _StatusTab(key: 'active', label: 'Active'),
    _StatusTab(key: 'filled', label: 'Filled'),
    _StatusTab(key: 'closed', label: 'Closed'),
    _StatusTab(key: 'draft', label: 'Draft'),
  ];

  final Map<String, List<String?>> _proposalAvatars = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    _searchController.addListener(_onSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchJobs());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final clientId = context.read<ProfileProvider>().clientProfile!.clientId;
      final provider = context.read<JobPostProvider>();
      final jobs = await provider.fetchMyJobPosts(token, clientId);

      setState(() {
        _allJobs = jobs ?? [];
        _applyFilters();
      });

      await _loadTeamPositionCounts(token);
      _fetchProposalAvatars(token);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTeamPositionCounts(String token) async {
    final service = JobPostService();
    final teamJobs = _allJobs.where(
      (job) => (job['project_type'] ?? '') == 'team',
    );
    final results = await Future.wait(
      teamJobs.map((job) async {
        final id = job['job_post_id'] as String?;
        if (id == null) return null;
        try {
          final roles = await service.getJobRoles(token, id);
          return MapEntry(
            id,
            roles.fold<int>(0, (sum, role) => sum + role.positionsAvailable),
          );
        } catch (_) {
          return null;
        }
      }),
    );
    final counts = results.whereType<MapEntry<String, int>>();
    if (!mounted) return;
    setState(() {
      for (final entry in counts) {
        final id = entry.key;
        final total = entry.value;
        for (final job in _allJobs) {
          if (job['job_post_id'] == id) job['position_count'] = total;
        }
      }
      _applyFilters();
    });
  }

  Future<void> _fetchProposalAvatars(String token) async {
    final profileProvider = context.read<ProfileProvider>();
    final proposalService = ProposalService();

    for (final job in _allJobs) {
      final jobPostId = job['job_post_id'] as String?;
      if (jobPostId == null) continue;
      final proposalCount = (job['proposal_count'] ?? 0) as int;
      if (proposalCount == 0) continue;

      try {
        final proposals = await proposalService.getProposalsByJobPost(
          token,
          jobPostId,
        );
        if (!mounted) return;

        final avatars = <String?>[];
        for (final proposal in proposals.take(3)) {
          final freelancer = await profileProvider.fetchFreelancerById(
            token: token,
            freelancerId: proposal.freelancerId,
          );
          avatars.add(freelancer?.profilePictureUrl);
        }
        if (mounted) setState(() => _proposalAvatars[jobPostId] = avatars);
      } catch (e) {
        debugPrint('Failed to fetch avatars for $jobPostId: $e');
      }
    }
  }

  // 👇 NEW: drafts have nothing to view yet — prompt to resume editing instead
  // of opening the read-only job detail screen.
  Future<void> _promptContinueDraft(String draftId) async {
    if (draftId.isEmpty) return;

    final confirmed = await ConfirmActionDialog.show(
      context,
      icon: Icons.edit_note_rounded,
      title: 'Continue this draft?',
      message:
          'This job hasn\'t been posted yet. Continue editing it to finish and publish.',
      confirmLabel: 'Continue draft',
      tone: ConfirmDialogTone.primary,
    );
    if (!confirmed || !mounted) return;

    final token = context.read<AuthProvider>().token;
    final clientId = context.read<ProfileProvider>().clientProfile?.clientId;
    if (token != null && token.isNotEmpty && clientId != null && clientId.isNotEmpty) {
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
        builder: (_) => const PostNewJobJobDetail(restoreFromExistingDraft: true),
      ),
    );
  }

  // 👇 NEW: unified filter — combines search query + status tab
  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredJobs = _allJobs.where((job) {
        final matchesQuery = (job['job_title'] as String? ?? '')
            .toLowerCase()
            .contains(query);
        final status = (job['status'] as String? ?? '').toLowerCase();
        final matchesStatus = _statusFilter == 'all' || status == _statusFilter;
        return matchesQuery && matchesStatus;
      }).toList();
    });
  }

  void _onSearch() => _applyFilters();

  void _onSortChanged(String value) {
    setState(() {
      _sortOption = value;
      int compare(Map a, Map b) => value == 'Latest'
          ? (b['created_at'] ?? '').compareTo(a['created_at'] ?? '')
          : (a['created_at'] ?? '').compareTo(b['created_at'] ?? '');
      _allJobs.sort(compare);
      _filteredJobs.sort(compare);
    });
  }

  // 👇 NEW: count jobs per status for badge numbers
  int _countForStatus(String key) {
    if (key == 'all') return _allJobs.length;
    return _allJobs.where((j) => (j['status'] as String? ?? '') == key).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            // ── Search bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFF0F0F1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF1A1A2E),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search jobs...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFFB5B4B4),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.search,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 👇 NEW: Status filter tab bar
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _statusTabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final tab = _statusTabs[i];
                  final isActive = _statusFilter == tab.key;
                  final count = _countForStatus(tab.key);
                  return GestureDetector(
                    onTap: () {
                      setState(() => _statusFilter = tab.key);
                      _applyFilters();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : const Color(0xFFE8E8E8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tab.label,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF7D7D7D),
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : AppColors.secondary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$count',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // ── Job list ────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _filteredJobs.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: _primary,
                      onRefresh: _fetchJobs,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _filteredJobs.length,
                        itemBuilder: (context, index) =>
                            _buildJobCard(_filteredJobs[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Color(0xFF333333),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Text(
            'My Jobs',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  // ── Job card — unchanged ───────────────────────────────────────────────────
  Widget _buildJobCard(Map<String, dynamic> job) {
    final jobPostId = job['job_post_id'] as String? ?? '';
    final isTeam = (job['project_type'] ?? '') == 'team';
    final proposalCount = (job['proposal_count'] ?? 0) as int;
    final status = job['status'] as String? ?? 'draft';
    final closureReason = job['closure_reason'] as String? ?? '';
    final isScamClosed = status == 'closed' && closureReason == 'scam';
    final isHarmfulClosed =
        status == 'closed' && closureReason == 'content_violation';
    final positionCount = isTeam
        ? (job['position_count'] as int?) ??
              ((job['roles'] as List?)?.fold<int>(
                    0,
                    (sum, role) =>
                        sum +
                        ((role is Map
                                ? (role['positions_available'] as int?)
                                : null) ??
                            1),
                  ) ??
                  (job['role_count'] ?? 0))
        : 1;
    final avatars = _proposalAvatars[jobPostId];
    final avatarCount = avatars != null
        ? avatars.length.clamp(0, 3)
        : proposalCount.clamp(0, 3);

    return GestureDetector(
      onTap: () {
        if (status == 'draft') {
          _promptContinueDraft(jobPostId);
          return;
        }
        final jobModel = JobPostModel.fromJson(job);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClientJobDetailScreen(job: jobModel),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEEEEF5)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.work_rounded,
                  size: 28,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          job['job_title'] ?? 'Untitled',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _statusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isTeam ? 'Team Project' : 'Individual Project',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF7D7D7D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _categoryChip(
                    job['project_category'] as String? ?? 'general',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.group_outlined,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$positionCount position${positionCount == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF7D7D7D),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.gavel,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$proposalCount bid${proposalCount == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF7D7D7D),
                        ),
                      ),
                      if (proposalCount > 0 && avatarCount > 0) ...[
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 20 + ((avatarCount - 1) * 18.0),
                          height: 24,
                          child: Stack(
                            children: List.generate(
                              avatarCount,
                              (i) => _proposalAvatar(
                                i,
                                avatars != null && avatars.length > i
                                    ? avatars[i]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isScamClosed || isHarmfulClosed) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.gpp_bad_rounded,
                            size: 12,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              isScamClosed
                                  ? 'Closed by AI scam detection · Tap to appeal'
                                  : 'Closed by AI content moderation · Tap to appeal',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFDC2626),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _proposalAvatar(int index, String? avatarUrl) {
    final fallbackColors = [
      const Color(0xFFB0C4DE),
      const Color(0xFF98D8C8),
      const Color(0xFFDEB0C4),
    ];
    return Positioned(
      left: index * 18.0,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          color: fallbackColors[index % fallbackColors.length],
        ),
        child: ClipOval(
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person, size: 14, color: Colors.white),
                )
              : const Icon(Icons.person, size: 14, color: Colors.white),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final map = {
      'draft': (const Color(0xFFB5B4B4), const Color(0xFFF5F5F5)),
      'open': (AppColors.primary, AppColors.secondary),
      'closed': (const Color(0xFF7D7D7D), const Color(0xFFF0F0F1)),
      'cancelled': (const Color(0xFFE53935), const Color(0xFFFFEBEE)),
      'filled': (const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
    };
    final colors =
        map[status] ?? (const Color(0xFF7D7D7D), const Color(0xFFF0F0F1));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _capitalize(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colors.$1,
        ),
      ),
    );
  }

  Widget _categoryChip(String category) {
    const labels = {
      'mobile_dev': 'Mobile Dev',
      'backend_dev': 'Backend Dev',
      'web_dev': 'Web Dev',
      'ui_ux_design': 'UI/UX Design',
      'graphic_design': 'Graphic Design',
      'copywriting': 'Copywriting',
      'data_analytics': 'Data Analytics',
      'video_editing': 'Video Editing',
      'general': 'General',
    };
    return Text(
      labels[category] ?? 'General',
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltered =
        _statusFilter != 'all' || _searchController.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.filter_list_off_rounded : Icons.work_outline,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No matching jobs' : 'No jobs posted yet',
            style: const TextStyle(
              color: Color(0xFF7D7D7D),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try a different filter or search term.'
                : 'Your posted jobs will appear here.',
            style: const TextStyle(color: Color(0xFFB5B4B4), fontSize: 12),
          ),
          if (isFiltered) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _statusFilter = 'all');
                _applyFilters();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Clear filters',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sort by',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Latest', 'Oldest'].map((option) {
                final isSelected = _sortOption == option;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _onSortChanged(option);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? _primary : Colors.white,
                      border: Border.all(
                        color: isSelected ? _primary : const Color(0xFFE0E0E0),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      option,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF555555),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

// 👇 NEW: simple data class for tab definitions
class _StatusTab {
  final String key;
  final String label;
  const _StatusTab({required this.key, required this.label});
}
