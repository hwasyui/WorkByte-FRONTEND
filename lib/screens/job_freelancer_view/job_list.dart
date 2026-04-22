import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_post_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/job_post_model.dart';
import '../../widgets/job_list_card.dart';
import '../../widgets/top_bar.dart';
import 'job_detail.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<JobPostModel> _allJobs = [];
  List<JobPostModel> _filteredJobs = [];
  bool _isLoading = true;
  String _sortOption = 'Latest';

  @override
  void initState() {
    super.initState();
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
      setState(() {
        _allJobs = List.from(posts);
        _applySortAndFilter();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
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
                          final urlWithBustingCache = '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
                          displayImage = Image.network(
                            urlWithBustingCache,
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                            cacheWidth: 56,
                            cacheHeight: 56,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, size: 28, color: Colors.white);
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
                              return const Icon(Icons.person, size: 28, color: Colors.white);
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
                      
                      return ScreenTopBar(
                        userAvatar: displayImage,
                      );
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: JobListCard(
        posterLogo: const Icon(
          Icons.business_rounded,
          size: 28,
          color: AppColors.primary,
        ),
        posterName: job.clientName ?? 'Client',
        title: job.jobTitle,
        category: job.projectScope,
        teamSize: job.roleCount,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
        ),
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
