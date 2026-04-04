import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

class JobListCard extends StatelessWidget {
  final Widget posterLogo;
  final String posterName;
  final String title;
  final String category;
  final int teamSize;
  final List<Widget> bidderAvatars;
  final String? biddingsLabel; // e.g. "+50 biddings"
  final String? salaryTag; // e.g. "Rp. 15.000.000"
  final String? typeTag; // e.g. "Team"
  final bool bookmarked;
  final VoidCallback? onBookmark;
  final VoidCallback? onTap;

  const JobListCard({
    super.key,
    required this.posterLogo,
    required this.posterName,
    required this.title,
    required this.category,
    required this.teamSize,
    this.bidderAvatars = const [],
    this.biddingsLabel,
    this.salaryTag,
    this.typeTag,
    this.bookmarked = false,
    this.onBookmark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF0F0F1)),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: logo + name + bookmark ──────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Company logo
                SizedBox(width: 35, height: 35, child: posterLogo),
                const SizedBox(width: 10),
                // Poster name
                Expanded(
                  child: Text(
                    posterName,
                    style: AppText.captionSemiBold.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
                // Bookmark
                GestureDetector(
                  onTap: onBookmark,
                  child: Icon(
                    bookmarked ? Icons.bookmark : Icons.bookmark_border,
                    size: 20,
                    color: const Color(0xFF7D7D7D),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Job title ────────────────────────────────────────────
            Text(
              title,
              style: AppText.captionSemiBold.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),

            const SizedBox(height: 10),

            // ── Category + team size ─────────────────────────────────
            Row(
              children: [
                Text(
                  category,
                  style: AppText.overline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7D7D7D),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.group_outlined,
                  size: 12,
                  color: Color(0xFF7D7D7D),
                ),
                const SizedBox(width: 3),
                Text(
                  '$teamSize',
                  style: AppText.overline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7D7D7D),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Tag row (salary OR type) ─────────────────────────────
            if (salaryTag != null || typeTag != null)
              Row(
                children: [
                  if (salaryTag != null) _OutlineTag(label: salaryTag!),
                  if (salaryTag != null && typeTag != null)
                    const SizedBox(width: 8),
                  if (typeTag != null) _OutlineTag(label: typeTag!),
                ],
              ),

            if (salaryTag != null || typeTag != null)
              const SizedBox(height: 12),

            // ── Bidder avatars ───────────────────────────────────────
            if (bidderAvatars.isNotEmpty)
              Row(
                children: [
                  _StackedAvatars(avatars: bidderAvatars),
                  if (biddingsLabel != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      biddingsLabel!,
                      style: AppText.overline.copyWith(
                        color: const Color(0xFF7D7D7D),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Outline chip tag ──────────────────────────────────────────────────────────
class _OutlineTag extends StatelessWidget {
  final String label;
  const _OutlineTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppText.overline.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ── Stacked circular avatars ──────────────────────────────────────────────────
class _StackedAvatars extends StatelessWidget {
  final List<Widget> avatars;
  final double size;
  final double overlap;

  const _StackedAvatars({
    required this.avatars,
    this.size = 25,
    this.overlap = 10,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCount = avatars.length;
    final totalWidth = size + (visibleCount - 1) * (size - overlap);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: List.generate(visibleCount, (i) {
          return Positioned(
            left: i * (size - overlap),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF9F9F9), width: 1),
                color: const Color(0xFFE0E0E0),
              ),
              child: ClipOval(child: avatars[i]),
            ),
          );
        }),
      ),
    );
  }
}
