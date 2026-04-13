import 'package:flutter/material.dart';
import '../../../core/constants/text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const SectionHeader({super.key, required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppText.h3.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF333333),
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            'View all >',
            style: AppText.captionSemiBold.copyWith(
              color: const Color(0xFF7D7D7D),
            ),
          ),
        ),
      ],
    );
  }
}
