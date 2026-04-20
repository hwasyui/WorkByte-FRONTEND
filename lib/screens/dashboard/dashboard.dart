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
import '../../widgets/category_tile.dart';
import '../../widgets/home_bottom_nav_bar.dart';
import '../../widgets/home_header.dart';
import '../freelancer_profile/freelancer_profile.dart';
import '../client_profile/client_profile.dart';
import '../../screens/job_freelancer_view/job_list.dart';
import '../../screens/job_client_view/job_list.dart' as client_job_list;
import '../people_list/people_list_screen.dart';
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
      final result = await ApiService.getAIJobRecommendations(auth.token!, limit: 10);
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
      print('Error loading AI recommendations: $e');
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
      return const Center(child: CircularProgressIndicator());
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
                    color: const Color(0xFF227C9D),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 20,
                  ),
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
        final freelancersData = await ApiService.getAllFreelancers(auth.token!, limit: 10);
        if (mounted) {
          setState(() {
            _topFreelancers = freelancersData.map((freelancer) => FreelancerModel.fromJson(freelancer)).toList();
            _isLoadingFreelancers = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingFreelancers = false;
          });
        }
        print('Error loading top freelancers: $e');
      }
    } else {
      setState(() {
        _isLoadingFreelancers = false;
      });
    }
  }

  void _handleNavigation(int index) {
    if (index == 1) {
      final profile = context.read<ProfileProvider>();
      if (profile.isClient) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const client_job_list.JobListScreen(),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JobListScreen()),
        );
      }
    } else if (index == 3) {
      final profile = context.read<ProfileProvider>();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PeopleListScreen(
            showClients: !profile.isClient,
          ),
        ),
      );
    } else if (index == 4) {
      final profile = context.read<ProfileProvider>();
      if (profile.isClient) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ClientProfileScreen()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      }
    } else {
      setState(() {
        _currentNavIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _TealHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 29),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Consumer2<AuthProvider, ProfileProvider>(
                    builder: (context, auth, profile, child) {
                      final imageUrl = profile.profilePictureUrl;
                      
                      Widget displayImage;
                      if (imageUrl != null && imageUrl.isNotEmpty) {
                        if (imageUrl.startsWith('http')) {
                          final urlWithBustingCache = '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
                          displayImage = Image.network(
                            urlWithBustingCache,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            cacheWidth: 64,
                            cacheHeight: 64,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, size: 32, color: Colors.white);
                            },
                          );
                        } else if (File(imageUrl).existsSync()) {
                          displayImage = Image.file(
                            File(imageUrl),
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            cacheWidth: 64,
                            cacheHeight: 64,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, size: 32, color: Colors.white);
                            },
                          );
                        } else {
                          displayImage = const Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.white,
                          );
                        }
                      } else {
                        displayImage = const Icon(
                          Icons.person,
                          size: 32,
                          color: Colors.white,
                        );
                      }
                      
                      return HomeHeader(
                        userName: profile.displayName,
                        userAvatar: displayImage,
                      );
                    },
                  ),
                  const SizedBox(height: 22),

                  // Search bar
                  const SearchBarWidget(),
                  const SizedBox(height: 26),

                  // AI Recommended Jobs - Only show for freelancers
                  Consumer<ProfileProvider>(
                    builder: (context, profile, child) {
                      if (profile.isClient) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(title: 'Recommended for You', onViewAll: () {}),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 178,
                            child: _buildRecommendedJobsList(),
                          ),
                          const SizedBox(height: 26),
                        ],
                      );
                    },
                  ),


                  // Top freelancers - Only show for clients
                  Consumer<ProfileProvider>(
                    builder: (context, profile, child) {
                      if (!profile.isClient) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(title: 'Top Freelancers', onViewAll: () {}),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 178,
                            child: _isLoadingFreelancers
                                ? const Center(child: CircularProgressIndicator())
                                : _topFreelancers.isEmpty
                                    ? const Center(child: Text('No freelancers available'))
                                    : ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _topFreelancers.length,
                                        itemBuilder: (context, index) {
                                          final freelancer = _topFreelancers[index];
                                          return Row(
                                            children: [
                                              JobCard(
                                                posterName: freelancer.displayName,
                                                posterAvatar: Container(
                                                  width: 35,
                                                  height: 35,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF227C9D),
                                                    borderRadius: BorderRadius.circular(6),
                                                    image: freelancer.profilePictureUrl != null && 
                                                           freelancer.profilePictureUrl!.isNotEmpty
                                                        ? DecorationImage(
                                                            image: freelancer.profilePictureUrl!.startsWith('http')
                                                                ? NetworkImage(freelancer.profilePictureUrl!)
                                                                : FileImage(File(freelancer.profilePictureUrl!)) as ImageProvider,
                                                            fit: BoxFit.cover,
                                                          )
                                                        : null,
                                                  ),
                                                  child: freelancer.profilePictureUrl == null || 
                                                         freelancer.profilePictureUrl!.isEmpty
                                                      ? const Icon(
                                                          Icons.person,
                                                          color: Colors.white,
                                                          size: 20,
                                                        )
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
                                              if (index < _topFreelancers.length - 1) const SizedBox(width: 12),
                                            ],
                                          );
                                        },
                                      ),
                          ),
                          const SizedBox(height: 26),
                        ],
                      );
                    },
                  ),

                  // Popular categories
                  SectionHeader(title: 'Popular Categories', onViewAll: () {}),
                  const SizedBox(height: 12),
                  CategoryTile(
                    icon: const Icon(
                      Icons.code,
                      color: Color(0xFF00AAA8),
                      size: 22,
                    ),
                    categoryName: 'Web Development',
                    subcategories: 'Company profile, Ecommerce, Ecatalog, ...',
                    jobCount: 25,
                  ),
                  const SizedBox(height: 10),
                  CategoryTile(
                    icon: const Icon(
                      Icons.campaign_outlined,
                      color: Color(0xFF00AAA8),
                      size: 22,
                    ),
                    categoryName: 'Marketing',
                    subcategories: 'Telemarketing, Digital Marketing, SEO, ...',
                    jobCount: 5,
                  ),
                  const SizedBox(height: 10),
                  CategoryTile(
                    icon: const Icon(
                      Icons.design_services_outlined,
                      color: Color(0xFF00AAA8),
                      size: 22,
                    ),
                    categoryName: 'UI/UX Design',
                    subcategories: 'Figma, Photoshop, Slicing HTML, UI, ...',
                    jobCount: 10,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _handleNavigation,
        showCenterButton: context.watch<ProfileProvider>().isClient,
      ),
    );
  }
}

class _TealHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipPath(
      clipper: _EllipseClipper(),
      child: Container(
        width: double.infinity,
        color: AppColors.primary,
        padding: EdgeInsets.only(
          top: topPadding + 16,
          bottom: 36,
          left: 29,
          right: 29,
        ),
        child: Text(
          'Find your dream job',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _EllipseClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_EllipseClipper oldClipper) => false;
}
