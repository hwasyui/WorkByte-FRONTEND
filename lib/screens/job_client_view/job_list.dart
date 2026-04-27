import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_post_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/proposal_service.dart';
import '../dashboard/dashboard.dart';
import '../../models/job_post_model.dart';
import '../job_client_view/job_detail.dart';

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

  // jobPostId → up to 3 freelancer avatar URLs
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
        _filteredJobs = List.from(_allJobs);
        _isLoading = false;
      });

      // Load avatars after list is rendered
      _fetchProposalAvatars(token);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  /// Fetch up to 3 real freelancer avatars per job from proposal list
  Future<void> _fetchProposalAvatars(String token) async {
    final profileProvider = context.read<ProfileProvider>();
    final proposalService = ProposalService();

    for (final job in _allJobs) {
      final jobPostId = job['job_post_id'] as String?;
      if (jobPostId == null) continue;

      final proposalCount = (job['proposal_count'] ?? 0) as int;
      if (proposalCount == 0) continue;

      try {
        // Fetch proposals for this job
        final proposals = await proposalService.getProposalsByJobPost(
          token,
          jobPostId,
        );
        if (!mounted) return;

        // Fetch each freelancer's avatar (up to 3)
        final avatars = <String?>[];
        for (final proposal in proposals.take(3)) {
          final freelancer = await profileProvider.fetchFreelancerById(
            token: token,
            freelancerId: proposal.freelancerId,
          );
          avatars.add(freelancer?.profilePictureUrl);
        }

        if (mounted) {
          setState(() => _proposalAvatars[jobPostId] = avatars);
        }
      } catch (e) {
        debugPrint('Failed to fetch avatars for $jobPostId: $e');
        // Non-fatal — falls back to colored circles
      }
    }
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredJobs = _allJobs
          .where(
            (job) => (job['job_title'] as String? ?? '').toLowerCase().contains(
              query,
            ),
          )
          .toList();
    });
  }

  void _onSortChanged(String value) {
    setState(() {
      _sortOption = value;
      _allJobs.sort(
        (a, b) => value == 'Latest'
            ? (b['created_at'] ?? '').compareTo(a['created_at'] ?? '')
            : (a['created_at'] ?? '').compareTo(b['created_at'] ?? ''),
      );
      _filteredJobs.sort(
        (a, b) => value == 'Latest'
            ? (b['created_at'] ?? '').compareTo(a['created_at'] ?? '')
            : (a['created_at'] ?? '').compareTo(b['created_at'] ?? ''),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1A1A2E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'My Jobs',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showSortSheet,
                    child: Row(
                      children: [
                        Text(
                          _sortOption,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
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
                    const Icon(Icons.search, color: AppColors.primary, size: 22),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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

  // ── Job card ──────────────────────────────────────────────────────────────
  Widget _buildJobCard(Map<String, dynamic> job) {
    final jobPostId = job['job_post_id'] as String? ?? '';
    final isTeam = (job['project_type'] ?? '') == 'team';
    final roleCount = job['role_count'] ?? 0;
    final proposalCount = (job['proposal_count'] ?? 0) as int;
    final status = job['status'] as String? ?? 'draft';
    final scope = _capitalize(job['project_scope'] ?? '');

    final avatars = _proposalAvatars[jobPostId];
    final avatarCount = avatars != null
        ? avatars.length.clamp(0, 3)
        : proposalCount.clamp(0, 3);

    return GestureDetector(
      onTap: () {
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
            // ── Logo container ───────────────────────────────────────────
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

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status badge
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

                  // Sub-title: project type
                  Text(
                    isTeam ? 'Team Project' : 'Individual Project',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF7D7D7D),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tags row: scope badge + role/bid count
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          scope,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.group_outlined,
                          size: 15, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        isTeam ? '$roleCount' : '$proposalCount',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Proposal avatar — real photo or colored fallback ─────────────────────
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

  // ── Status badge ──────────────────────────────────────────────────────────
  Widget _statusBadge(String status) {
    final map = {
      'draft': (const Color(0xFFB5B4B4), const Color(0xFFF5F5F5)),
      'open': (AppColors.primary, AppColors.secondary),
      'closed': (const Color(0xFF7D7D7D), const Color(0xFFF0F0F1)),
      'cancelled': (const Color(0xFFE53935), const Color(0xFFFFEBEE)),
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

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No jobs posted yet',
            style: TextStyle(
              color: Color(0xFF7D7D7D),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your posted jobs will appear here.',
            style: TextStyle(color: Color(0xFFB5B4B4), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Sort bottom sheet ─────────────────────────────────────────────────────
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort by',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 16),
            for (final option in ['Latest', 'Oldest'])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option, style: const TextStyle(fontSize: 13)),
                trailing: _sortOption == option
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _onSortChanged(option);
                },
              ),
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
