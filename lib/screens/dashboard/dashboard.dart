import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/constants/colors.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/section_header.dart';
import '../../widgets/job_card.dart';
import '../../widgets/home_bottom_nav_bar.dart';
import '../freelancer_profile/freelancer_profile.dart';
import '../client_profile/client_profile.dart';
import '../../screens/post_job/job_detail.dart';
import '../../screens/job_freelancer_view/job_list.dart';
import '../../screens/job_client_view/job_list.dart' as client_job_list;
import '../people_list/people_list_screen.dart';
import '../workspace/workspace.dart';
import '../../services/api_service.dart';
import '../../models/job_post_model.dart';
import '../../models/freelancer_model.dart';
import '../../models/ai_job_match_model.dart';
import '../job_freelancer_view/job_detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  List<AIJobMatchModel> _recommendedJobs = [];
  bool _isLoadingJobs = true;
  bool _noEmbeddingYet = false;

  List<FreelancerModel> _topFreelancers = [];
  bool _isLoadingFreelancers = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendedJobs();
    _loadTopFreelancers();
  }

  Future<void> _loadRecommendedJobs() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      setState(() => _isLoadingJobs = false);
      return;
    }
    try {
      final result = await ApiService.getAIJobRecommendations(
        auth.token!,
        limit: 10,
      );
      if (!mounted) return;
      if (result.isEmpty) {
        setState(() {
          _noEmbeddingYet = true;
          _isLoadingJobs = false;
        });
        return;
      }
      final matches = result['matches'] as List? ?? [];
      setState(() {
        _recommendedJobs = matches
            .map((m) => AIJobMatchModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        _isLoadingJobs = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingJobs = false);
      debugPrint('Error loading AI recommendations: $e');
    }
  }

  Future<void> _tapJob(AIJobMatchModel match) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final data = await ApiService.getJobPostById(auth.token!, match.jobPostId);
    if (!mounted || data == null) return;
    final job = JobPostModel.fromJson(data);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
    );
  }

  Widget _buildRecommendedJobsList() {
    if (_isLoadingJobs) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
      );
    }
    if (_noEmbeddingYet) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Complete your profile to get AI job recommendations',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ),
      );
    }
    if (_recommendedJobs.isEmpty) {
      return Center(
        child: Text(
          'No recommendations yet',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _recommendedJobs.length,
      itemBuilder: (context, index) {
        final job = _recommendedJobs[index];
        return Row(
          children: [
            GestureDetector(
              onTap: () => _tapJob(job),
              child: JobCard(
                posterName: job.experienceLevel != null
                    ? job.experienceLevel!.toUpperCase()
                    : 'ANY LEVEL',
                posterAvatar: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.business, color: AppColors.primary, size: 20),
                ),
                title: job.jobTitle,
                category: job.projectType.toUpperCase(),
                biddings: '${job.proposalCount} proposal${job.proposalCount != 1 ? 's' : ''}',
                salary: job.projectScope.toUpperCase(),
                jobType: job.projectType == 'team' ? 'Team' : 'Individual',
                matchScore: job.matchScoreInt,
              ),
            ),
            if (index < _recommendedJobs.length - 1) const SizedBox(width: 12),
          ],
        );
      },
    );
  }

  Future<void> _loadTopFreelancers() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token != null) {
      try {
        final freelancersData = await ApiService.getAllFreelancers(auth.token!, pageSize: 10);
        if (mounted) {
          setState(() {
            _topFreelancers = freelancersData.map((f) => FreelancerModel.fromJson(f)).toList();
            _isLoadingFreelancers = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingFreelancers = false);
        debugPrint('Error loading top freelancers: $e');
      }
    } else {
      setState(() => _isLoadingFreelancers = false);
    }
  }

  void _handleNavigation(int index) {
    if (index == 1) {
      final profile = context.read<ProfileProvider>();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => profile.isClient
              ? const client_job_list.JobListScreen()
              : const JobListScreen(),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WorkspaceScreen()),
      );
    } else if (index == 3) {
      final profile = context.read<ProfileProvider>();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => profile.isClient
              ? const ClientProfileScreen()
              : const ProfileScreen(),
        ),
      );
    } else {
      setState(() => _currentNavIndex = index);
    }
  }

  void _onDashboardSearch(String query) {
    final profile = context.read<ProfileProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => profile.isClient
            ? client_job_list.JobListScreen(initialQuery: query)
            : JobListScreen(initialQuery: query),
      ),
    );
  }

  void _handleCenterButton() {
    _navigateToPostJob();
  }

  void _navigateToPostJob() {
    final profile = context.read<ProfileProvider>();
    if (!profile.isProfileComplete) {
      _showIncompleteProfileDialog(isClient: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostNewJobJobDetail()),
    );
  }

  void _showIncompleteProfileDialog({required bool isClient}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Profile Incomplete',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          isClient
              ? 'Please complete your profile before posting a job.'
              : 'Please complete your profile before applying to jobs.',
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF7D7D7D)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF7D7D7D))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final p = context.read<ProfileProvider>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => p.isClient ? const ClientProfileScreen() : const ProfileScreen(),
                ),
              );
            },
            child: Text(
              'Complete Now',
              style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Greeting row
                  Consumer2<AuthProvider, ProfileProvider>(
                    builder: (context, auth, profile, child) {
                      final imageUrl = profile.profilePictureUrl;
                      Widget displayImage;
                      if (imageUrl != null && imageUrl.isNotEmpty) {
                        if (imageUrl.startsWith('http')) {
                          displayImage = Image.network(
                            '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, size: 24, color: AppColors.primary),
                          );
                        } else if (File(imageUrl).existsSync()) {
                          displayImage = Image.file(
                            File(imageUrl),
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, size: 24, color: AppColors.primary),
                          );
                        } else {
                          displayImage =
                              const Icon(Icons.person, size: 24, color: AppColors.primary);
                        }
                      } else {
                        displayImage =
                            const Icon(Icons.person, size: 24, color: AppColors.primary);
                      }

                      return Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: displayImage,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi, ${profile.displayName}!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                                Text(
                                  "Let's find your next opportunity",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF7D7D7D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const _NotificationPlaceholder(),
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEC1B1B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Complete profile banner
                  Consumer<ProfileProvider>(
                    builder: (context, profile, _) {
                      if (profile.isProfileComplete) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Complete your profile',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  Text(
                                    'Unlock all features & opportunities',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF7D7D7D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => profile.isClient
                                      ? const ClientProfileScreen()
                                      : const ProfileScreen(),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Complete now',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  SearchBarWidget(onSearch: _onDashboardSearch),
                  const SizedBox(height: 20),

                  // Quick-access cards: Jobs | Freelancers | Clients
                  Consumer<ProfileProvider>(
                    builder: (context, profile, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: _QuickAccessCard(
                              icon: Icons.work_rounded,
                              label: 'Jobs',
                              subtitle: 'View all jobs',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => profile.isClient
                                      ? const client_job_list.JobListScreen()
                                      : const JobListScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickAccessCard(
                              icon: Icons.person_rounded,
                              label: 'Freelancers',
                              subtitle: 'View all freelancers',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PeopleListScreen(showClients: false),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickAccessCard(
                              icon: Icons.business_rounded,
                              label: 'Clients',
                              subtitle: 'View all clients',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PeopleListScreen(showClients: true),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Recommended Jobs — freelancers only
                  Consumer<ProfileProvider>(
                    builder: (context, profile, child) {
                      if (profile.isClient) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Recommended for You',
                            onViewAll: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const JobListScreen()),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 178,
                            child: _buildRecommendedJobsList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),

                  // Top Freelancers — clients only
                  Consumer<ProfileProvider>(
                    builder: (context, profile, child) {
                      if (!profile.isClient) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Top Freelancers',
                            onViewAll: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PeopleListScreen(showClients: false),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 178,
                            child: _isLoadingFreelancers
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : _topFreelancers.isEmpty
                                    ? const Center(child: Text('No freelancers available'))
                                    : ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _topFreelancers.length,
                                        itemBuilder: (context, index) {
                                          final freelancer = _topFreelancers[index];
                                          return Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => PeopleProfileScreen(
                                                      isClient: false,
                                                      freelancer: freelancer,
                                                    ),
                                                  ),
                                                ),
                                                child: JobCard(
                                                  posterName: freelancer.displayName,
                                                  posterAvatar: Container(
                                                    width: 35,
                                                    height: 35,
                                                    decoration: BoxDecoration(
                                                      color: AppColors.secondary,
                                                      borderRadius: BorderRadius.circular(6),
                                                      image: freelancer.profilePictureUrl != null &&
                                                              freelancer.profilePictureUrl!.isNotEmpty
                                                          ? DecorationImage(
                                                              image: freelancer.profilePictureUrl!
                                                                      .startsWith('http')
                                                                  ? NetworkImage(
                                                                          freelancer.profilePictureUrl!)
                                                                      as ImageProvider
                                                                  : FileImage(File(
                                                                      freelancer.profilePictureUrl!)),
                                                              fit: BoxFit.cover,
                                                            )
                                                          : null,
                                                    ),
                                                    child: freelancer.profilePictureUrl == null ||
                                                            freelancer.profilePictureUrl!.isEmpty
                                                        ? const Icon(Icons.person,
                                                            color: AppColors.primary, size: 20)
                                                        : null,
                                                  ),
                                                  title: freelancer.displayName,
                                                  category: freelancer.jobTitle,
                                                  biddings: freelancer.totalProjects > 0
                                                      ? '${freelancer.totalProjects} project${freelancer.totalProjects != 1 ? 's' : ''}'
                                                      : 'New freelancer',
                                                  salary: freelancer.formattedRate,
                                                  jobType: 'Freelancer',
                                                ),
                                              ),
                                              if (index < _topFreelancers.length - 1)
                                                const SizedBox(width: 12),
                                            ],
                                          );
                                        },
                                      ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),

                  // Popular Categories
                  SectionHeader(title: 'Popular Categories', onViewAll: () {}),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _CategoryCard(
                          icon: Icons.code_rounded,
                          iconColor: Color(0xFF4F46E5),
                          iconBg: Color(0xFFE0E7FF),
                          label: 'Web Dev',
                          jobCount: 25,
                          countColor: Color(0xFF4F46E5),
                        ),
                        SizedBox(width: 12),
                        _CategoryCard(
                          icon: Icons.campaign_outlined,
                          iconColor: Color(0xFF059669),
                          iconBg: Color(0xFFD1FAE5),
                          label: 'Marketing',
                          jobCount: 5,
                          countColor: Color(0xFF059669),
                        ),
                        SizedBox(width: 12),
                        _CategoryCard(
                          icon: Icons.design_services_outlined,
                          iconColor: Color(0xFFD97706),
                          iconBg: Color(0xFFFEF3C7),
                          label: 'UI/UX',
                          jobCount: 10,
                          countColor: Color(0xFFD97706),
                        ),
                        SizedBox(width: 12),
                        _CategoryCard(
                          icon: Icons.bar_chart_rounded,
                          iconColor: Color(0xFFDC2626),
                          iconBg: Color(0xFFFEE2E2),
                          label: 'Data Science',
                          jobCount: 8,
                          countColor: Color(0xFFDC2626),
                        ),
                        SizedBox(width: 12),
                        _CategoryCard(
                          icon: Icons.shield_outlined,
                          iconColor: Color(0xFF0891B2),
                          iconBg: Color(0xFFCFFAFE),
                          label: 'Cyber Security',
                          jobCount: 6,
                          countColor: Color(0xFF0891B2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Consumer<AuthProvider>(
        builder: (context, auth, _) => HomeBottomNavBar(
          currentIndex: _currentNavIndex,
          onTap: _handleNavigation,
          onCenterTap: _handleCenterButton,
          showCenterButton: !auth.currentUser!.isFreelancer,
        ),
      ),
    );
  }
}

// ── Dashboard header ───────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return SizedBox(
      width: double.infinity,
      height: topPadding + 190,
      child: Image.asset(
        'assets/dashboard.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
    );
  }
}

// ── Quick-access card ─────────────────────────────────────────────────────────
class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: const Color(0xFF7D7D7D),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Horizontal category card ──────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final int jobCount;
  final Color countColor;

  const _CategoryCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.jobCount,
    required this.countColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$jobCount jobs',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: countColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification placeholder ───────────────────────────────────────────────────
class _NotificationPlaceholder extends StatelessWidget {
  const _NotificationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'No notifications yet',
          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF7D7D7D)),
        ),
      ),
    );
  }
}
