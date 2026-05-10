import 'package:app/screens/job_freelancer_view/job_list.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

// ── Category definition (now with colors matching dashboard) ─────────────────
class CategoryInfo {
  final String label;
  final String categoryKey;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const CategoryInfo({
    required this.label,
    required this.categoryKey,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

const List<CategoryInfo> kJobCategories = [
  CategoryInfo(
    label: 'Mobile Dev',
    categoryKey: 'mobile_dev',
    icon: Icons.phone_android_rounded,
    iconColor: Color(0xFF0891B2),
    iconBg: Color(0xFFCFFAFE),
  ),
  CategoryInfo(
    label: 'Backend Dev',
    categoryKey: 'backend_dev',
    icon: Icons.dns_rounded,
    iconColor: Color(0xFF7C3AED),
    iconBg: Color(0xFFEDE9FE),
  ),
  CategoryInfo(
    label: 'Web Dev',
    categoryKey: 'web_dev',
    icon: Icons.language_rounded,
    iconColor: Color(0xFF4F46E5),
    iconBg: Color(0xFFE0E7FF),
  ),
  CategoryInfo(
    label: 'UI/UX Design',
    categoryKey: 'ui_ux_design',
    icon: Icons.design_services_rounded,
    iconColor: Color(0xFFD97706),
    iconBg: Color(0xFFFEF3C7),
  ),
  CategoryInfo(
    label: 'Graphic Design',
    categoryKey: 'graphic_design',
    icon: Icons.brush_rounded,
    iconColor: Color(0xFFDB2777),
    iconBg: Color(0xFFFCE7F3),
  ),
  CategoryInfo(
    label: 'Copywriting',
    categoryKey: 'copy_writing',
    icon: Icons.edit_note_rounded,
    iconColor: Color(0xFF065F46),
    iconBg: Color(0xFFD1FAE5),
  ),
  CategoryInfo(
    label: 'Data Analytics',
    categoryKey: 'data_analytics',
    icon: Icons.bar_chart_rounded,
    iconColor: Color(0xFFDC2626),
    iconBg: Color(0xFFFEE2E2),
  ),
  CategoryInfo(
    label: 'Video Editing',
    categoryKey: 'video_editing',
    icon: Icons.videocam_rounded,
    iconColor: Color(0xFFB45309),
    iconBg: Color(0xFFFEF3C7),
  ),
  CategoryInfo(
    label: 'Marketing',
    categoryKey: 'marketing',
    icon: Icons.campaign_rounded,
    iconColor: Color(0xFF059669),
    iconBg: Color(0xFFD1FAE5),
  ),
  CategoryInfo(
    label: 'General',
    categoryKey: 'general',
    icon: Icons.work_outline_rounded,
    iconColor: Color(0xFF374151),
    iconBg: Color(0xFFF3F4F6),
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Browse by Category',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Text(
                'What kind of work are you looking for?',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF7D7D7D),
                ),
              ),
            ),
            // Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemCount: kJobCategories.length,
                itemBuilder: (context, index) {
                  final cat = kJobCategories[index];
                  return _CategoryCard(
                    category: cat,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            JobListScreen(categoryFilter: cat.categoryKey),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final CategoryInfo category;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: category.iconBg, // ← per-category bg
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category.icon,
                size: 22,
                color: category.iconColor, // ← per-category color
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'View jobs',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: category.iconColor, // ← matches icon color
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: category.iconColor, // ← matches icon color
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
