import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

class CategoryTile extends StatelessWidget {
  final Widget icon;
  final String categoryName;
  final String subcategories;
  final int jobCount;

  const CategoryTile({
    super.key,
    required this.icon,
    required this.categoryName,
    required this.subcategories,
    required this.jobCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        border: Border.all(color: AppColors.secondary),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon
          icon,
          const SizedBox(width: 12),
          // Text column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  categoryName,
                  style: AppText.captionSemiBold.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subcategories,
                  style: AppText.overline.copyWith(
                    color: const Color(0xFF7D7D7D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Job count
          Text(
            '$jobCount jobs',
            style: AppText.caption.copyWith(color: const Color(0xFF7D7D7D)),
          ),
        ],
      ),
    );
  }
}
