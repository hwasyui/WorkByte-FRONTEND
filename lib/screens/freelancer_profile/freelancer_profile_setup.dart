import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:workbyte_app/providers/auth_provider.dart';
import 'package:workbyte_app/providers/profile_provider.dart';
import 'package:workbyte_app/screens/dashboard/dashboard.dart';
import 'package:workbyte_app/screens/freelancer_profile/cv_upload_entry.dart';
import 'package:workbyte_app/screens/freelancer_profile/freelancer_profile.dart';

class FreelancerProfileSetupScreen extends StatefulWidget {
  const FreelancerProfileSetupScreen({super.key});

  @override
  State<FreelancerProfileSetupScreen> createState() =>
      _FreelancerProfileSetupScreenState();
}

class _FreelancerProfileSetupScreenState
    extends State<FreelancerProfileSetupScreen> {
  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFFE0E7FF);
  static const Color background = Color(0xFFF9F9F9);
  static const Color textDark = Color(0xFF111827);

  bool _navigating = false;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final auth = context.read<AuthProvider>();
    final missing = profile.missingOnboardingFields;

    if (profile.isOnboardingComplete && !_navigating) {
      _navigating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete your profile',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unlock job applications and help clients discover you faster.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: textDark.withOpacity(0.65),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: secondary,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: primary.withOpacity(0.10)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You are almost ready',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Finish the essentials first. You can complete the rest later from your profile.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    color: textDark.withOpacity(0.70),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Missing essentials',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...missing.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: secondary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.checklist_rounded,
                                color: primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _ActionCard(
                      icon: Icons.edit_outlined,
                      title: 'Fill manually',
                      subtitle:
                          'Add your title, bio, skills, and experience step by step.',
                      buttonLabel: 'Start now',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _ActionCard(
                      icon: Icons.description_outlined,
                      title: 'Import from CV',
                      subtitle:
                          'Upload your CV and review the suggested profile details.',
                      buttonLabel: 'Upload CV',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CvUploadEntryScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              color: background,
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: profile.isOnboardingComplete
                      ? () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HomeScreen(),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    disabledBackgroundColor: primary.withOpacity(0.35),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Continue to app',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFFE0E7FF);
  static const Color textDark = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: textDark.withOpacity(0.65),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              buttonLabel,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
