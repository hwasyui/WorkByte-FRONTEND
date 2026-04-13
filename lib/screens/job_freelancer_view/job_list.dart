import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../widgets/job_list_card.dart';
import '../../widgets/load_more_button.dart';
import '../../widgets/top_bar.dart';
import 'team_job_detail.dart';
import 'single_job_detail.dart';

class JobListScreen extends StatelessWidget {
  const JobListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: back + bell + avatar (reusable widget)
                  ScreenTopBar(
                    userAvatar: Image.network(
                      'https://i.pravatar.cc/40?img=8',
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Row 2: title (left) + Latest + filter (right)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Available jobs',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Latest',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7D7D7D),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.filter_list,
                        size: 20,
                        color: Color(0xFF333333),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Search bar ────────────────────────────────────────────
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
                      child: Text(
                        'Search jobs...',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7D7D7D),
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

            // ── Job cards list ────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(29, 16, 29, 16),
                children: [
                  // Card 1 – salary tag + 3 stacked avatars + biddings count
                  JobListCard(
                    posterLogo: Image.network(
                      'https://www.google.com/favicon.ico',
                      width: 35,
                      height: 35,
                    ),
                    posterName: 'Alexa Doe',
                    title: 'Need freelancer to revamp and redesign our website',
                    category: 'Web Development',
                    teamSize: 10,
                    typeTag: 'Team',
                    salaryTag: 'Rp. 15.000.000',
                    bidderAvatars: [
                      Image.network(
                        'https://i.pravatar.cc/50?img=8',
                        fit: BoxFit.cover,
                      ),
                      Image.network(
                        'https://i.pravatar.cc/50?img=11',
                        fit: BoxFit.cover,
                      ),
                      Image.network(
                        'https://i.pravatar.cc/50?img=5',
                        fit: BoxFit.cover,
                      ),
                    ],
                    biddingsLabel: '+50 biddings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeamJobDetailScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Card 2
                  JobListCard(
                    posterLogo: Image.network(
                      'https://www.google.com/favicon.ico',
                      width: 35,
                      height: 35,
                    ),
                    posterName: 'Alexa Doe',
                    title: 'Need freelancer to revamp and redesign our website',
                    category: 'Web Development',
                    teamSize: 1,
                    salaryTag: 'Rp. 6.000.000',
                    bidderAvatars: [
                      Image.network(
                        'https://i.pravatar.cc/50?img=8',
                        fit: BoxFit.cover,
                      ),
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SingleJobDetailScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Card 3 – salary tag + 2 stacked avatars
                  JobListCard(
                    posterLogo: Image.network(
                      'https://www.google.com/favicon.ico',
                      width: 35,
                      height: 35,
                    ),
                    posterName: 'Alexa Doe',
                    title: 'Need freelancer to revamp and redesign our website',
                    category: 'Web Development',
                    teamSize: 5,
                    typeTag: 'Team',
                    salaryTag: 'Rp. 15.000.000',
                    bidderAvatars: [
                      Image.network(
                        'https://i.pravatar.cc/50?img=11',
                        fit: BoxFit.cover,
                      ),
                      Image.network(
                        'https://i.pravatar.cc/50?img=5',
                        fit: BoxFit.cover,
                      ),
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeamJobDetailScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Load more
                  Center(child: LoadMoreButton(onTap: () {})),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
