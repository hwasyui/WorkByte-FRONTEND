import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';

/// Reusable teal header used on job detail screens.
/// Shows back/share/bookmark actions, company logo, poster name,
/// username, job title, category, and tag chips.
class JobDetailHeader extends StatelessWidget {
  final Widget companyLogo;
  final String posterName;
  final String username;
  final String jobTitle;
  final String category;
  final List<String>
  tags; // e.g. ['Rp. 6.000.000', 'Team', '23/02/2023', 'Milestone']
  final bool bookmarked;
  final VoidCallback? onBack;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;

  const JobDetailHeader({
    super.key,
    required this.companyLogo,
    required this.posterName,
    required this.username,
    required this.jobTitle,
    required this.category,
    required this.tags,
    this.bookmarked = false,
    this.onBack,
    this.onShare,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Teal section ─────────────────────────────────────────────
        Container(
          color: AppColors.primary,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            bottom: 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Action icons row
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack ?? () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onShare,
                    child: const Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: onBookmark,
                    child: Icon(
                      bookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Company logo + poster info
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo in circular white bg
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAF9FE),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: companyLogo,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        posterName,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        username,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        // ── White rounded card section ────────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFF9F9F9),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(27, 20, 27, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job title
              Text(
                jobTitle,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF333333),
                  height: 30 / 20,
                ),
              ),
              const SizedBox(height: 8),
              // Category
              Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7D7D7D),
                ),
              ),
              const SizedBox(height: 12),
              // Tag chips row
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: tags.map((tag) => _TagChip(label: tag)).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
