import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/section_header.dart';
import '../../widgets/job_card.dart';
import '../../widgets/freelancer_card.dart';
import '../../widgets/category_tile.dart';
import '../../widgets/home_bottom_nav_bar.dart';
import '../../widgets/home_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Teal curved header ──────────────────────────────────────
          _TealHeader(),

          // ── Scrollable body ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 29),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Greeting row
                  HomeHeader(
                    userName: 'Alexa Joe',
                    userAvatar: Image.network(
                      'https://i.pravatar.cc/60?img=12',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Search bar
                  const SearchBarWidget(),

                  const SizedBox(height: 26),

                  // ── Popular Jobs ──────────────────────────────────
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

                  // ── Top Freelancers ───────────────────────────────
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

                  // ── Popular Categories ────────────────────────────
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

                  // Bottom padding so last item clears the nav bar
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (i) => setState(() => _currentNavIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Teal curved top header
// ─────────────────────────────────────────────────────────────────────────────

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
          "Find your dream job",
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

/// Clips the bottom of the teal banner with a gentle downward ellipse curve,
/// matching the Figma design's rotated ellipse overlay effect.
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
