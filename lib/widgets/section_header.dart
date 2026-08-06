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
        // The title is caller-supplied and the action is a fixed width, so the
        // title has to be the one that gives way when the pair won't fit.
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.h3.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
        ),
        const SizedBox(width: 8),
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
