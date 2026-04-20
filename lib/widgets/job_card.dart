import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

class JobCard extends StatelessWidget {
  final String posterName;
  final Widget posterAvatar;
  final String title;
  final String category;
  final String biddings;
  final String salary;
  final String jobType;
  final bool bookmarked;

  const JobCard({
    super.key,
    required this.posterName,
    required this.posterAvatar,
    required this.title,
    required this.category,
    required this.biddings,
    required this.salary,
    required this.jobType,
    this.bookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 253,
      height: 178,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF0F0F1)),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + bookmark
          Row(
            children: [
              posterAvatar,
              const SizedBox(width: 8),
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
              Icon(
                bookmarked ? Icons.bookmark : Icons.bookmark_border,
                size: 20,
                color: const Color(0xFF7D7D7D),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Title
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          // Category & biddings
          Row(
            children: [
              Text(
                category,
                style: AppText.overline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7D7D7D),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                biddings,
                style: AppText.overline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7D7D7D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Tags
          Row(
            children: [
              _Tag(label: salary),
              const SizedBox(width: 6),
              _Tag(label: jobType),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
