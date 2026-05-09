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

class JobListScreen extends StatefulWidget {
  final String? initialQuery;

  const JobListScreen({super.key, this.initialQuery});

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

  final Map<String, int> _positionCounts = {};
  final Map<String, String?> _clientProfilePictures = {};

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
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  void _onSearch() => setState(() => _applySortAndFilter());

  void _onSortChanged(String value) {
    setState(() {
      _sortOption = value;
      _applySortAndFilter();
    });
  }

  void _applySortAndFilter() {
    final query = _searchController.text.toLowerCase();
    _filteredJobs = _allJobs
        .where((j) => j.jobTitle.toLowerCase().contains(query))
        .toList();

    _filteredJobs.sort(
      (a, b) => _sortOption == 'Latest'
          ? (b.createdAt ?? '').compareTo(a.createdAt ?? '')
          : (a.createdAt ?? '').compareTo(b.createdAt ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer2<AuthProvider, ProfileProvider>(
                    builder: (context, auth, profile, child) {
                      final imageUrl = profile.profilePictureUrl;

                      Widget displayImage;
                      if (imageUrl != null && imageUrl.isNotEmpty) {
                        if (imageUrl.startsWith('http')) {
                          final urlWithBustingCache =
                              '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
                          displayImage = Image.network(
                            urlWithBustingCache,
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                            cacheWidth: 56,
                            cacheHeight: 56,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 28,
                                color: Colors.white,
                              );
                            },
                          );
                        } else if (File(imageUrl).existsSync()) {
                          displayImage = Image.file(
                            File(imageUrl),
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                            cacheWidth: 56,
                            cacheHeight: 56,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 28,
                                color: Colors.white,
                              );
                            },
                          );
                        } else {
                          displayImage = const Icon(
                            Icons.person,
                            size: 28,
                            color: Colors.white,
                          );
                        }
                      } else {
                        displayImage = const Icon(
                          Icons.person,
                          size: 28,
                          color: Colors.white,
                        );
                      }

                      return ScreenTopBar(userAvatar: displayImage);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Available jobs',
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
                ],
              ),
            ),
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
                          hintText: 'Search jobs...',
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
                      color: AppColors.primary,
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
                      color: AppColors.primary,
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
                    color: AppColors.primary,
                  ),
                ),
              )
            : const Center(
                child: Icon(
                  Icons.business_rounded,
                  size: 28,
                  color: AppColors.primary,
                ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No jobs available',
            style: GoogleFonts.poppins(
              color: const Color(0xFF7D7D7D),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new opportunities.',
            style: GoogleFonts.poppins(
              color: const Color(0xFFB5B4B4),
              fontSize: 12,
            ),
          ),
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
}
