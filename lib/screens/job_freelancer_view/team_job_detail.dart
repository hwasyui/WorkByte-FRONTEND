import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../widgets/job_detail_header.dart';
import '../../widgets/job_detail_tab_bar.dart';
import '../../widgets/role_card.dart';
import '../../widgets/load_more_button.dart';
import '../../widgets/bidding_bottom_sheet.dart';

class TeamJobDetailScreen extends StatefulWidget {
  const TeamJobDetailScreen({super.key});

  @override
  State<TeamJobDetailScreen> createState() => _TeamJobDetailScreenState();
}

class _TeamJobDetailScreenState extends State<TeamJobDetailScreen> {
  int _selectedTab = 0; // 0 = Details, 1 = Terms, 2 = Bidding

  static const _tabs = ['Details', 'Terms', 'Bidding (35)'];

  static const _description =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\n\n'
      'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum\n\n'
      'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Teal header ─────────────────────────────────────────
            JobDetailHeader(
              companyLogo: Image.network(
                'https://www.google.com/favicon.ico',
                fit: BoxFit.contain,
              ),
              posterName: 'Alexa Doe',
              username: '@alexadoe',
              jobTitle: 'Need freelancer to revamp and redesign website',
              category: 'Web Development',
              tags: const ['Rp. 6.000.000', 'Team', '23/02/2023', 'Milestone'],
            ),

            // ── Tab bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(27, 20, 27, 0),
              child: JobDetailTabBar(
                tabs: _tabs,
                selectedIndex: _selectedTab,
                onTabSelected: (i) => setState(() => _selectedTab = i),
              ),
            ),

            // ── Tab content ─────────────────────────────────────────
            if (_selectedTab == 0) _buildDetailsTab(),
            if (_selectedTab == 1) _buildPlaceholderTab('Terms'),
            if (_selectedTab == 2) _buildPlaceholderTab('Bidding'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 20, 27, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            'Description',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF333333),
              height: 20 / 13,
            ),
          ),

          const SizedBox(height: 28),

          // Roles
          Text(
            'Roles',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),

          RoleCard(
            roleTitle: 'UI Designer',
            roleDescription: 'We need UI Designer who can work with team',
            salary: 'Rp. 1.500.000',
            onApply: () => showBiddingBottomSheet(context),
          ),

          const SizedBox(height: 14),

          RoleCard(
            roleTitle: 'Frontend Web Developer',
            roleDescription:
                'We need frontend developer who has experienced ReactJS',
            salary: 'Rp.4.000.000',
            onApply: () => showBiddingBottomSheet(context),
          ),

          const SizedBox(height: 28),

          // Load more
          Center(child: LoadMoreButton(onTap: () {})),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          '$label content coming soon',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF7D7D7D),
          ),
        ),
      ),
    );
  }
}
