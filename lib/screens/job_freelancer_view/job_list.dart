import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_post_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/saved_items_provider.dart';
import '../../models/job_post_model.dart';
import '../../services/job_post_service.dart';
import '../../widgets/top_bar.dart';
import 'job_detail.dart';

// ── Category meta ────────────────────────────────────────────────────────────
const Map<String, String> kCategoryLabels = {
  'mobiledev': 'Mobile Dev',
  'backenddev': 'Backend Dev',
  'webdev': 'Web Dev',
  'uiuxdesign': 'UI/UX Design',
  'graphicdesign': 'Graphic Design',
  'copywriting': 'Copywriting',
  'dataanalytics': 'Data Analytics',
  'videoediting': 'Video Editing',
  'marketing': 'Marketing',
  'general': 'General',
  // legacy snake_case keys (keep for backward compat)
  'mobile_dev': 'Mobile Dev',
  'backend_dev': 'Backend Dev',
  'web_dev': 'Web Dev',
  'ui_ux_design': 'UI/UX Design',
  'graphic_design': 'Graphic Design',
  'data_analytics': 'Data Analytics',
  'video_editing': 'Video Editing',
};

const Map<String, IconData> kCategoryIcons = {
  'mobiledev': Icons.phone_android_rounded,
  'backenddev': Icons.dns_rounded,
  'webdev': Icons.language_rounded,
  'uiuxdesign': Icons.design_services_rounded,
  'graphicdesign': Icons.brush_rounded,
  'copywriting': Icons.edit_note_rounded,
  'dataanalytics': Icons.bar_chart_rounded,
  'videoediting': Icons.videocam_rounded,
  'marketing': Icons.campaign_rounded,
  'general': Icons.work_outline_rounded,
};

// ── Screen ───────────────────────────────────────────────────────────────────
class JobListScreen extends StatefulWidget {
  final String? initialQuery;
  final String? categoryFilter;

  const JobListScreen({super.key, this.initialQuery, this.categoryFilter});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  static const Color _primary = AppColors.primary;

  final TextEditingController _searchController = TextEditingController();
  List<JobPostModel> _allJobs = [];
  List<JobPostModel> _filteredJobs = [];
  bool _isLoading = true;
  String _sortOption = 'Latest';

  /// Active category filter — starts from widget.categoryFilter, can be cleared
  String? _activeCategoryFilter;

  final Map<String, int> _positionCounts = {};
  final Map<String, String?> _clientProfilePictures = {};

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _activeCategoryFilter = widget.categoryFilter;
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

  // ── Data fetching ──────────────────────────────────────────────────────────
  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      await context.read<JobPostProvider>().fetchAllJobPosts(token);
      final posts = context.read<JobPostProvider>().jobPosts;
      _allJobs = List<JobPostModel>.from(posts);

      await _loadTeamPositionCounts(token);
      await _loadClientProfilePictures(token);

      if (!mounted) return;
      setState(() {
        _applySortAndFilter();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTeamPositionCounts(String token) async {
    final service = JobPostService();
    final teamJobs = _allJobs.where(
      (job) => (job.projectType ?? '').toLowerCase() == 'team',
    );

    final results = await Future.wait(
      teamJobs.map((job) async {
        try {
          final roles = await service.getJobRoles(token, job.jobPostId);
          final total = roles.fold<int>(
            0,
            (sum, role) => sum + role.positionsAvailable,
          );
          return MapEntry(job.jobPostId, total);
        } catch (_) {
          return null;
        }
      }),
    );

    if (!mounted) return;
    setState(() {
      _positionCounts.clear();
      for (final entry in results.whereType<MapEntry<String, int>>()) {
        _positionCounts[entry.key] = entry.value;
      }
      _applySortAndFilter();
    });
  }

  Future<void> _loadClientProfilePictures(String token) async {
    final profileProvider = context.read<ProfileProvider>();
    final clientIds = _allJobs
        .map((job) => job.clientId)
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final clientId in clientIds) {
      if (_clientProfilePictures.containsKey(clientId)) continue;
      try {
        final client = await profileProvider.fetchClientById(
          token: token,
          clientId: clientId,
        );
        if (!mounted) return;
        _clientProfilePictures[clientId] = client?.profilePictureUrl;
      } catch (_) {
        _clientProfilePictures[clientId] = null;
      }
    }

    if (!mounted) return;
    setState(() {});
  }

  // ── Filtering / sorting ────────────────────────────────────────────────────
  void _onSearch() => setState(() => _applySortAndFilter());

  void _onSortChanged(String value) {
    setState(() {
      _sortOption = value;
      _applySortAndFilter();
    });
  }

  void _clearCategoryFilter() {
    setState(() {
      _activeCategoryFilter = null;
      _applySortAndFilter();
    });
  }

  void _applySortAndFilter() {
    final query = _searchController.text.toLowerCase();

    _filteredJobs = _allJobs.where((j) {
      // Text search
      final matchesQuery = j.jobTitle.toLowerCase().contains(query);

      // Category filter
      final matchesCategory =
          _activeCategoryFilter == null ||
          (j.projectCategory).toLowerCase() ==
              _activeCategoryFilter!.toLowerCase();

      return matchesQuery && matchesCategory;
    }).toList();

    _filteredJobs.sort(
      (a, b) => _sortOption == 'Latest'
          ? (b.createdAt ?? '').compareTo(a.createdAt ?? '')
          : (a.createdAt ?? '').compareTo(b.createdAt ?? ''),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isFiltered = _activeCategoryFilter != null;
    final String screenTitle = isFiltered
        ? (kCategoryLabels[_activeCategoryFilter] ?? 'Jobs')
        : 'Available jobs';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
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
                    'Available Jobs',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ── Active category filter chip ──
            if (isFiltered)
              Padding(
                padding: const EdgeInsets.fromLTRB(29, 12, 29, 0),
                child: Row(
                  children: [
                    Icon(
                      kCategoryIcons[_activeCategoryFilter] ??
                          Icons.label_outline_rounded,
                      size: 14,
                      color: _primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              kCategoryLabels[_activeCategoryFilter] ??
                                  _activeCategoryFilter!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _clearCategoryFilter,
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: _primary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_filteredJobs.length} result${_filteredJobs.length == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(29, 12, 29, 0),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFF0F0F1)),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF333333),
                        ),
                        decoration: InputDecoration(
                          hintText: isFiltered
                              ? 'Search in ${kCategoryLabels[_activeCategoryFilter] ?? _activeCategoryFilter}...'
                              : 'Search jobs...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF7D7D7D),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.search,
                      color: Color(0xFF7D7D7D),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),

            // ── Job list ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primary),
                    )
                  : _filteredJobs.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: _primary,
                      onRefresh: _fetchJobs,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(29, 16, 29, 16),
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

  // ── Job card ───────────────────────────────────────────────────────────────
  Widget _buildJobCard(JobPostModel job) {
    final isTeam = (job.projectType ?? '').toLowerCase() == 'team';
    final proposalCount = job.proposalCount;
    final positionCount = isTeam
        ? (_positionCounts[job.jobPostId] ?? job.roleCount)
        : 1;
    final clientAvatarUrl = _clientProfilePictures[job.clientId];

    return Consumer<SavedItemsProvider>(
      builder: (context, saved, _) {
        final isSaved = saved.isJobSaved(job.jobPostId);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
          ),
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
                _clientAvatar(clientAvatarUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.jobTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        job.clientName ?? 'Client',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF7D7D7D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _categoryChip(job.projectCategory),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.group_outlined,
                            size: 15,
                            color: _primary,
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
                          const Icon(Icons.gavel, size: 15, color: _primary),
                          const SizedBox(width: 4),
                          Text(
                            '$proposalCount bid${proposalCount == 1 ? '' : 's'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF7D7D7D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => saved.toggleSaveJob(job),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSaved
                          ? AppColors.secondary
                          : const Color(0xFFF8F8FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEEEEF5)),
                    ),
                    child: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                      color: _primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _clientAvatar(String? avatarUrl) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.business_rounded,
                    size: 28,
                    color: _primary,
                  ),
                ),
              )
            : const Center(
                child: Icon(Icons.business_rounded, size: 28, color: _primary),
              ),
      ),
    );
  }

  Widget _categoryChip(String category) {
    final label = kCategoryLabels[category.toLowerCase()] ?? 'General';
    final icon =
        kCategoryIcons[category.toLowerCase()] ?? Icons.work_outline_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _primary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _activeCategoryFilter != null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered
                ? (kCategoryIcons[_activeCategoryFilter] ?? Icons.work_outline)
                : Icons.work_outline,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'No ${kCategoryLabels[_activeCategoryFilter] ?? _activeCategoryFilter} jobs'
                : 'No jobs available',
            style: GoogleFonts.poppins(
              color: const Color(0xFF7D7D7D),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try clearing the filter or check back later.'
                : 'Check back later for new opportunities.',
            style: GoogleFonts.poppins(
              color: const Color(0xFFB5B4B4),
              fontSize: 12,
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _clearCategoryFilter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Clear filter',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primary,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort by',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            for (final option in ['Latest', 'Oldest'])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option, style: GoogleFonts.poppins(fontSize: 13)),
                trailing: _sortOption == option
                    ? const Icon(Icons.check, color: _primary)
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
}
