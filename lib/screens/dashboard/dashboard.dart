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
import '../../widgets/freelancer_card.dart';
import '../../widgets/category_tile.dart';
import '../../widgets/home_bottom_nav_bar.dart';
import '../../widgets/home_header.dart';
import '../freelancer_profile/freelancer_profile.dart';
import '../client_profile/client_profile.dart';
import '../../screens/job_freelancer_view/job_list.dart';
import '../../screens/job_client_view/job_list.dart' as client_job_list;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

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

                  // Popular jobs
                  SectionHeader(title: 'Popular Jobs', onViewAll: () {}),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 178,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        JobCard(
                          posterName: 'Alexa Doe',
                          posterAvatar: Image.network(
                            'https://www.google.com/favicon.ico',
                            width: 35,
                            height: 35,
                          ),
                          title:
                              'Need freelancer to revamp and redesign our website',
                          category: 'Web Development',
                          biddings: '10 biddings',
                          salary: 'Rp. 15.000.000',
                          jobType: 'Team',
                        ),
                        const SizedBox(width: 12),
                        JobCard(
                          posterName: 'Benjamin',
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
                          title: 'Freelancer with UI Design skills needed',
                          category: 'UI Design',
                          biddings: '5 biddings',
                          salary: 'Rp. 15.000.000',
                          jobType: 'Team',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Top Freelancers
                  SectionHeader(title: 'Top Freelancers', onViewAll: () {}),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 175,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        FreelancerCard(
                          name: 'Dennis Wang',
                          username: '@denswang',
                          role: 'UI/UX Designer',
                          rating: 5,
                          avatar: Image.network(
                            'https://i.pravatar.cc/90?img=11',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        FreelancerCard(
                          name: 'Ais Vadelia',
                          username: '@aisvadelia',
                          role: 'Web Designer',
                          rating: 5,
                          avatar: Image.network(
                            'https://i.pravatar.cc/90?img=5',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        FreelancerCard(
                          name: 'Hansen Nugraha',
                          username: '@hansen',
                          role: 'Web Developer',
                          rating: 4,
                          avatar: Image.network(
                            'https://i.pravatar.cc/90?img=8',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

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
