import 'dart:io';

import 'package:workbyte_app/providers/notification_provider.dart';
import 'package:workbyte_app/screens/workspace/workspace_contract.dart';
import 'package:workbyte_app/services/auth_service.dart';
import 'package:workbyte_app/screens/category/category_list.dart';
import 'package:workbyte_app/screens/dashboard/notification.dart';
import 'package:workbyte_app/services/job_post_service.dart';
import 'package:workbyte_app/widgets/appeal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../auth/login.dart';
import '../../core/constants/colors.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/section_header.dart';
import '../../widgets/job_card.dart';
import '../../widgets/home_bottom_nav_bar.dart';
import '../../widgets/side_drawer.dart';
import '../freelancer_profile/freelancer_profile.dart';
import '../client_profile/client_profile.dart';
import '../../screens/post_job/job_detail.dart';
import '../../screens/job_freelancer_view/job_list.dart';
import '../../screens/job_client_view/job_list.dart' as client_job_list;
import '../people_list/people_list_screen.dart';
import '../workspace/workspace.dart';
import '../dm/dm_thread_list.dart';
import '../../services/api_service.dart';
import '../../services/job_post_service.dart';
import '../../models/job_post_model.dart';
import '../../models/freelancer_model.dart';
import '../job_freelancer_view/job_detail.dart';
import '../recommended/recommended_jobs_screen.dart';

class _CategoryDef {
  final String key;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color countColor;

  const _CategoryDef({
    required this.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.countColor,
  });
}

const List<_CategoryDef> _kCategoryDefs = [
  _CategoryDef(
    key: 'webdev',
    label: 'Web Dev',
    icon: Icons.language_rounded,
    iconColor: Color(0xFF4F46E5),
    iconBg: Color(0xFFE0E7FF),
    countColor: Color(0xFF4F46E5),
  ),
  _CategoryDef(
    key: 'marketing',
    label: 'Marketing',
    icon: Icons.campaign_rounded,
    iconColor: Color(0xFF059669),
    iconBg: Color(0xFFD1FAE5),
    countColor: Color(0xFF059669),
  ),
  _CategoryDef(
    key: 'ui_ux_design',
    label: 'UI/UX Design',
    icon: Icons.design_services_rounded,
    iconColor: Color(0xFFD97706),
    iconBg: Color(0xFFFEF3C7),
    countColor: Color(0xFFD97706),
  ),
  _CategoryDef(
    key: 'data_analytics',
    label: 'Data Analytics',
    icon: Icons.bar_chart_rounded,
    iconColor: Color(0xFFDC2626),
    iconBg: Color(0xFFFEE2E2),
    countColor: Color(0xFFDC2626),
  ),
  _CategoryDef(
    key: 'mobile_dev',
    label: 'Mobile Dev',
    icon: Icons.phone_android_rounded,
    iconColor: Color(0xFF0891B2),
    iconBg: Color(0xFFCFFAFE),
    countColor: Color(0xFF0891B2),
  ),
  _CategoryDef(
    key: 'backend_dev',
    label: 'Backend Dev',
    icon: Icons.dns_rounded,
    iconColor: Color(0xFF7C3AED),
    iconBg: Color(0xFFEDE9FE),
    countColor: Color(0xFF7C3AED),
  ),
  _CategoryDef(
    key: 'graphic_design',
    label: 'Graphic Design',
    icon: Icons.brush_rounded,
    iconColor: Color(0xFFDB2777),
    iconBg: Color(0xFFFCE7F3),
    countColor: Color(0xFFDB2777),
  ),
  _CategoryDef(
    key: 'copy_writing',
    label: 'Copywriting',
    icon: Icons.edit_note_rounded,
    iconColor: Color(0xFF065F46),
    iconBg: Color(0xFFD1FAE5),
    countColor: Color(0xFF065F46),
  ),
  _CategoryDef(
    key: 'video_editing',
    label: 'Video Editing',
    icon: Icons.videocam_rounded,
    iconColor: Color(0xFFB45309),
    iconBg: Color(0xFFFEF3C7),
    countColor: Color(0xFFB45309),
  ),
  _CategoryDef(
    key: 'general',
    label: 'General',
    icon: Icons.work_outline_rounded,
    iconColor: Color(0xFF374151),
    iconBg: Color(0xFFF3F4F6),
    countColor: Color(0xFF374151),
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<JobPostModel> _relevantJobs = [];
  List<JobPostModel> _popularJobs = [];
  bool _isLoadingRelevant = true;
  bool _isLoadingPopular = true;
  bool _noEmbeddingYet = false;

  List<FreelancerModel> _topFreelancers = [];
  bool _isLoadingFreelancers = true;

  Map<String, int> _categoryCounts = {};
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRelevantJobs();
      _loadPopularJobs();
      _loadTopFreelancers();
      _loadCategoryCounts();
      context.read<NotificationProvider>().fetchUnreadCount();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadRelevantJobs();
      _loadPopularJobs();
    }
  }

  Future<void> _loadRelevantJobs() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      setState(() => _isLoadingRelevant = false);
      return;
    }
    setState(() {
      _isLoadingRelevant = true;
      _noEmbeddingYet = false;
      _relevantJobs = [];
    });
    try {
      final jobs = await JobPostService().getRelevantJobs(
        auth.token!,
        limit: 10,
      );
      if (!mounted) return;
      if (jobs.isEmpty) {
        setState(() {
          _noEmbeddingYet = true;
          _isLoadingRelevant = false;
        });
        return;
      }
      setState(() {
        _relevantJobs = jobs;
        _isLoadingRelevant = false;
      });
    } on SessionExpiredException {
      if (!mounted) return;
      await context.read<AuthProvider>().handleSessionExpired(
        profileProvider: context.read<ProfileProvider>(),
        notificationProvider: context.read<NotificationProvider>(),
      );
    } catch (e) {
      if (mounted) setState(() => _isLoadingRelevant = false);
      debugPrint('Error loading relevant jobs: $e');
    }
  }

  Future<void> _loadPopularJobs() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      setState(() => _isLoadingPopular = false);
      return;
    }
    setState(() {
      _isLoadingPopular = true;
      _popularJobs = [];
    });
    try {
      final jobs = await JobPostService().getPopularJobs(
        auth.token!,
        pageSize: 10,
      );
      if (!mounted) return;
      setState(() {
        _popularJobs = jobs;
        _isLoadingPopular = false;
      });
    } on SessionExpiredException {
      if (!mounted) return;
      await context.read<AuthProvider>().handleSessionExpired(
        profileProvider: context.read<ProfileProvider>(),
        notificationProvider: context.read<NotificationProvider>(),
      );
    } catch (e) {
      if (mounted) setState(() => _isLoadingPopular = false);
      debugPrint('Error loading popular jobs: $e');
    }
  }

  Future<void> _loadCategoryCounts() async {
    setState(() => _isLoadingCategories = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final counts = await JobPostService().getCategoryCounts(token);
      if (mounted) setState(() => _categoryCounts = counts);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  // ── Sorted category cards ──────────────────────────────────────────────────
  List<_CategoryDef> get _sortedCategories {
    final sorted = [..._kCategoryDefs];
    sorted.sort(
      (a, b) =>
          (_categoryCounts[b.key] ?? 0).compareTo(_categoryCounts[a.key] ?? 0),
    );
    return sorted;
  }

  void _tapJob(JobPostModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
    );
  }

  Widget _buildJobFeedEmpty(String message, VoidCallback onRefresh) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onRefresh,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 14,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Refresh',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalJobList(
    List<JobPostModel> jobs,
    bool isLoading,
    VoidCallback onRefresh, {
    String emptyMessage = 'No jobs found',
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    }
    if (jobs.isEmpty) {
      return _buildJobFeedEmpty(emptyMessage, onRefresh);
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return Row(
          children: [
            GestureDetector(
              onTap: () => _tapJob(job),
              child: JobCard(
                posterName: job.clientName ?? 'Client',
                posterAvatar: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: job.jobTitle,
                category: job.projectType.toUpperCase(),
                biddings:
                    '${job.proposalCount} proposal${job.proposalCount != 1 ? 's' : ''}',
                salary: job.projectScope.toUpperCase(),
                jobType: job.projectType == 'team' ? 'Team' : 'Individual',
              ),
            ),
            if (index < jobs.length - 1) const SizedBox(width: 12),
          ],
        );
      },
    );
  }

  Future<void> _loadTopFreelancers() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token != null) {
      try {
        final freelancersData = await ApiService.getAllFreelancers(
          auth.token!,
          pageSize: 10,
        );
        if (mounted) {
          setState(() {
            _topFreelancers = freelancersData
                .map((f) => FreelancerModel.fromJson(f))
                .toList();
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
      final profile = context.read<ProfileProvider>();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => profile.isClient
              ? const WorkspaceScreen()
              : const WorkspaceContractScreen(),
        ),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DMThreadListScreen()),
      );
    } else {
      setState(() => _currentNavIndex = index);
    }
  }

  void _handleSearch(String query) {
    if (query.isEmpty) return;
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
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    // block if account is banned
    if (auth.isReportBanned) {
      _showBannedDialog();
      return;
    }
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
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF7D7D7D),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF7D7D7D)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final p = context.read<ProfileProvider>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => p.isClient
                      ? const ClientProfileScreen()
                      : const ProfileScreen(),
                ),
              );
            },
            child: Text(
              'Complete Now',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBannedDialog() {
    final auth = context.read<AuthProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFCDD2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.gavel_rounded,
                color: Color(0xFFC62828),
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Account Restricted',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFB71C1C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              auth.banMessage ??
                  'Your account has been restricted due to community reports. You cannot post jobs at this time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppealDialog.show(
                context,
                targetType: 'user',
                targetId: auth.userId!,
                targetLabel: 'Account Restriction',
                closureNote: auth.banMessage,
              ).then((_) => auth.refreshUser());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Submit Appeal',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Full-screen gate: account has been closed by admin
    if (auth.isReportBanned) {
      return _BannedAccountGate(
        banMessage: auth.banMessage,
        userId: auth.userId ?? '',
      );
    }

    // Sort categories by real count descending
    final sortedCategories = [..._kCategoryDefs]
      ..sort(
        (a, b) => (_categoryCounts[b.key] ?? 0).compareTo(
          _categoryCounts[a.key] ?? 0,
        ),
      );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const SideDrawer(),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          context.read<AuthProvider>().refreshUser();
        }
      },
      floatingActionButton: Consumer<ProfileProvider>(
        builder: (_, profile, __) {
          if (!profile.isClient) return const SizedBox.shrink();
          return GestureDetector(
            onTap: _handleCenterButton,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.32),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ── User greeting row ──
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
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 24,
                              color: AppColors.primary,
                            ),
                          );
                        } else if (File(imageUrl).existsSync()) {
                          displayImage = Image.file(
                            File(imageUrl),
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 24,
                              color: AppColors.primary,
                            ),
                          );
                        } else {
                          displayImage = const Icon(
                            Icons.person,
                            size: 24,
                            color: AppColors.primary,
                          );
                        }
                      } else {
                        displayImage = const Icon(
                          Icons.person,
                          size: 24,
                          color: AppColors.primary,
                        );
                      }

                      return Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: displayImage,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi, ${profile.displayName}!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                                Text(
                                  "Let's find your next opportunity",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF7D7D7D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // AFTER — live unread badge, navigates to real NotificationScreen
                          Consumer<NotificationProvider>(
                            builder: (context, notifProvider, _) {
                              final count = notifProvider.unreadCount;
                              return GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationScreen(),
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
                                    if (count > 0)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEC1B1B),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            count > 99 ? '99+' : '$count',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              height: 1,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── Complete profile banner ──
                  Consumer<ProfileProvider>(
                    builder: (context, profile, _) {
                      if (profile.isProfileComplete)
                        return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  Text(
                                    'Unlock all features & opportunities',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Complete now',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
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

                  // ── Search bar ──
                  SearchBarWidget(onSearch: _handleSearch),
                  const SizedBox(height: 20),

                  // ── Quick access cards ──
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
                                  builder: (_) => const JobListScreen(),
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
                                  builder: (_) => const PeopleListScreen(
                                    showClients: false,
                                  ),
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
                                  builder: (_) =>
                                      const PeopleListScreen(showClients: true),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Most Relevant (freelancers only) ──
                  Consumer<ProfileProvider>(
                    builder: (context, profile, child) {
                      if (profile.isClient) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Most Relevant',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const RecommendedJobsScreen(),
                                  ),
                                ),
                                child: Text(
                                  'View all >',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF7D7D7D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 178,
                            child: _buildHorizontalJobList(
                              _relevantJobs,
                              _isLoadingRelevant,
                              _loadRelevantJobs,
                              emptyMessage: _noEmbeddingYet
                                  ? 'Complete your profile to see relevant jobs'
                                  : 'No relevant jobs found',
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),

                  // ── Most Popular ──
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Most Popular',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const JobListScreen(),
                              ),
                            ),
                            child: Text(
                              'View all >',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7D7D7D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 178,
                        child: _buildHorizontalJobList(
                          _popularJobs,
                          _isLoadingPopular,
                          _loadPopularJobs,
                          emptyMessage: 'No popular jobs right now',
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                  // ── Top Freelancers (clients only) ──
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
                                builder: (_) =>
                                    const PeopleListScreen(showClients: false),
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
                                ? const Center(
                                    child: Text('No freelancers available'),
                                  )
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
                                                builder: (_) =>
                                                    PeopleProfileScreen(
                                                      isClient: false,
                                                      freelancer: freelancer,
                                                    ),
                                              ),
                                            ),
                                            child: JobCard(
                                              posterName:
                                                  freelancer.displayName,
                                              posterAvatar: Container(
                                                width: 35,
                                                height: 35,
                                                decoration: BoxDecoration(
                                                  color: AppColors.secondary,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  image:
                                                      freelancer.profilePictureUrl !=
                                                              null &&
                                                          freelancer
                                                              .profilePictureUrl!
                                                              .isNotEmpty
                                                      ? DecorationImage(
                                                          image:
                                                              freelancer
                                                                  .profilePictureUrl!
                                                                  .startsWith(
                                                                    'http',
                                                                  )
                                                              ? NetworkImage(
                                                                      freelancer
                                                                          .profilePictureUrl!,
                                                                    )
                                                                    as ImageProvider
                                                              : FileImage(
                                                                  File(
                                                                    freelancer
                                                                        .profilePictureUrl!,
                                                                  ),
                                                                ),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : null,
                                                ),
                                                child:
                                                    freelancer.profilePictureUrl ==
                                                            null ||
                                                        freelancer
                                                            .profilePictureUrl!
                                                            .isEmpty
                                                    ? const Icon(
                                                        Icons.person,
                                                        color:
                                                            AppColors.primary,
                                                        size: 20,
                                                      )
                                                    : null,
                                              ),
                                              title: freelancer.displayName,
                                              category: freelancer.jobTitle,
                                              biddings:
                                                  freelancer.totalProjects > 0
                                                  ? '${freelancer.totalProjects} project${freelancer.totalProjects != 1 ? 's' : ''}'
                                                  : 'New freelancer',
                                              salary: freelancer.formattedRate,
                                              jobType: 'Freelancer',
                                            ),
                                          ),
                                          if (index <
                                              _topFreelancers.length - 1)
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

                  // ── Popular Categories ──
                  SectionHeader(
                    title: 'Popular Categories',
                    onViewAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoryListScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 122,
                    child: _isLoadingCategories
                        ? ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: 5,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, __) => _CategoryCardSkeleton(),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: sortedCategories.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final cat = sortedCategories[index];
                              final count = _categoryCounts[cat.key] ?? 0;
                              return _CategoryCard(
                                icon: cat.icon,
                                iconColor: cat.iconColor,
                                iconBg: cat.iconBg,
                                label: cat.label,
                                jobCount: count,
                                countColor: cat.countColor,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        JobListScreen(categoryFilter: cat.key),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Consumer2<AuthProvider, ProfileProvider>(
        builder: (context, auth, profile, _) => HomeBottomNavBar(
          currentIndex: _currentNavIndex,
          onTap: _handleNavigation,
          showCenterButton: false,
        ),
      ),
    );
  }
}

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
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
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

// ── Category Card ─────────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final int jobCount;
  final Color countColor;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.jobCount,
    required this.countColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$jobCount jobs',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: countColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Card Skeleton (loading state) ────────────────────────────────────
class _CategoryCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 10,
            width: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 10,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

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
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF7D7D7D),
          ),
        ),
      ),
    );
  }
}

// ── Banned-account gate ───────────────────────────────────────────────────────
// Shown instead of the normal app when the user's account has been closed.

class _BannedAccountGate extends StatelessWidget {
  final String? banMessage;
  final String userId;

  const _BannedAccountGate({this.banMessage, required this.userId});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    size: 44,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Account Closed',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  banMessage ??
                      'Your account has been closed by the WorkByte team. '
                          'You can no longer access the platform.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                // info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFCC02).withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xFFF57F17),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'If you believe this was a mistake, you can submit an appeal. '
                          'Our team will review it within 3–5 business days.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF5D4037),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // appeal button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => AppealDialog.show(
                      context,
                      targetType: 'user',
                      targetId: userId,
                      targetLabel: 'Your Account',
                      closureNote: banMessage,
                    ),
                    icon: const Icon(Icons.gavel_rounded, size: 18),
                    label: Text(
                      'Submit an Appeal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // logout
                TextButton(
                  onPressed: () async {
                    final profile = context.read<ProfileProvider>();
                    await auth.logout(profileProvider: profile);
                    if (context.mounted) {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: Text(
                    'Sign out',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9CA3AF),
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
}
