import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6C63FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Content
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 32),
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.work_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'WorkByte',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'AI-Powered Freelance Platform',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About section
                  _SectionTitle(title: 'About WorkByte'),
                  const SizedBox(height: 12),
                  _InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WorkByte is a freelance platform that connects skilled '
                          'professionals with clients from around the world. Whether '
                          'you\'re looking for great talent or your next opportunity, '
                          'WorkByte makes it simple.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF555555),
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We use smart technology behind the scenes to help you find '
                          'the right match faster and to keep the platform safe and '
                          'trustworthy for everyone.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF555555),
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Signing In section
                  _SectionTitle(title: 'Signing In'),
                  const SizedBox(height: 12),

                  _FeatureCard(
                    icon: Icons.lock_open_rounded,
                    iconColor: const Color(0xFF0891B2),
                    iconBg: const Color(0xFFCFFAFE),
                    accentColor: const Color(0xFF0891B2),
                    badge: 'Google Sign-In',
                    title: 'Sign In with Google',
                    description:
                        'Sign in quickly and securely using your Google account — '
                        'no need to remember another password. On your first login, '
                        'just choose whether you\'re joining as a freelancer or a client.',
                    highlights: const [
                      'One-tap sign-in with Google',
                      'No extra password to remember',
                      'Choose your role on first login',
                    ],
                  ),

                  const SizedBox(height: 28),

                  // AI Features section
                  _SectionTitle(title: 'AI-Powered Features'),
                  const SizedBox(height: 12),

                  _FeatureCard(
                    icon: Icons.document_scanner_outlined,
                    iconColor: const Color(0xFF4F46E5),
                    iconBg: const Color(0xFFEEECFB),
                    accentColor: const Color(0xFF4F46E5),
                    badge: 'CV Reading',
                    title: 'Smart CV Reading',
                    description:
                        'Upload your CV and WorkByte reads it for you, picking out '
                        'your skills and experience automatically.',
                    highlights: const [
                      'Reads your CV for you',
                      'Highlights your key skills and experience',
                    ],
                  ),

                  const SizedBox(height: 14),

                  _FeatureCard(
                    icon: Icons.manage_accounts_outlined,
                    iconColor: const Color(0xFF0891B2),
                    iconBg: const Color(0xFFCFFAFE),
                    accentColor: const Color(0xFF0891B2),
                    badge: 'Profile Setup',
                    title: 'Quick Profile Setup',
                    description:
                        'No need to fill out your profile from scratch — upload your '
                        'CV and WorkByte fills it in for you. You can always review '
                        'and edit it before saving.',
                    highlights: const [
                      'Fills your profile from your CV',
                      'Easy to review and edit',
                    ],
                  ),

                  const SizedBox(height: 14),

                  _FeatureCard(
                    icon: Icons.auto_awesome_rounded,
                    iconColor: const Color(0xFF0EA5E9),
                    iconBg: const Color(0xFFE0F2FE),
                    accentColor: const Color(0xFF0EA5E9),
                    badge: 'Job Discovery',
                    title: 'Smart Job Discovery',
                    description:
                        'WorkByte shows you jobs that fit your skills, plus what\'s '
                        'trending with other freelancers right now.',
                    highlights: const [
                      'Jobs picked to match your skills',
                      'See what\'s popular on the platform',
                    ],
                  ),

                  const SizedBox(height: 14),

                  _FeatureCard(
                    icon: Icons.manage_search_rounded,
                    iconColor: const Color(0xFF059669),
                    iconBg: const Color(0xFFD1FAE5),
                    accentColor: const Color(0xFF059669),
                    badge: 'Job Fit',
                    title: 'Job Fit Analysis',
                    description:
                        'Curious how well you fit a job? Get a quick breakdown of '
                        'your matching skills, any gaps, and tips to improve your '
                        'chances.',
                    highlights: const [
                      'Shows your matching skills and gaps',
                      'Gives tips to boost your chances',
                    ],
                  ),

                  const SizedBox(height: 14),

                  _FeatureCard(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF7C3AED),
                    iconBg: const Color(0xFFF3E8FF),
                    accentColor: const Color(0xFF7C3AED),
                    badge: 'Harmful Text',
                    title: 'Harmful Text Detection',
                    description:
                        'WorkByte automatically checks job posts, profiles, and '
                        'messages to help keep the community safe and respectful.',
                    highlights: const [
                      'Helps keep content safe and respectful',
                      'Flagged content is reviewed by our team',
                    ],
                  ),

                  const SizedBox(height: 14),

                  _FeatureCard(
                    icon: Icons.gpp_bad_outlined,
                    iconColor: const Color(0xFFDC2626),
                    iconBg: const Color(0xFFFEE2E2),
                    accentColor: const Color(0xFFDC2626),
                    badge: 'Scam Protection',
                    title: 'Job Scam Detection',
                    description:
                        'New job posts are automatically checked to help catch '
                        'scams and fake listings before they reach you.',
                    highlights: const [
                      'Helps catch scam job posts early',
                      'Suspicious posts are reviewed by our team',
                    ],
                  ),

                  const SizedBox(height: 14),

                  _FeatureCard(
                    icon: Icons.star_outline_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    iconBg: const Color(0xFFFEF3C7),
                    accentColor: const Color(0xFFF59E0B),
                    badge: 'Ratings',
                    title: 'Fair Freelancer Ratings',
                    description:
                        'Freelancers get a fair, easy-to-understand rating based on '
                        'things like client feedback and work history.',
                    highlights: const [
                      'Fair, easy-to-understand ratings',
                      'Based on client feedback and work history',
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Version info
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Version 1.0.1',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '© 2025 WorkByte. All rights reserved.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable widgets

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color accentColor;
  final String badge;
  final String title;
  final String description;
  final List<String> highlights;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.accentColor,
    required this.badge,
    required this.title,
    required this.description,
    required this.highlights,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconBg.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF555555),
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 14),
                ...highlights.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            h,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF374151),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
