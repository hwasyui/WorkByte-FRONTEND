import 'package:flutter/material.dart';
import '../../../core/constants/text_styles.dart';

class FreelancerCard extends StatelessWidget {
  final String name;
  final String username;
  final String role;
  final Widget avatar;
  final double rating;

  const FreelancerCard({
    super.key,
    required this.name,
    required this.username,
    required this.role,
    required this.avatar,
    this.rating = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 131,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF0F0F1)),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE0E0E0),
            child: ClipOval(child: avatar),
          ),
          const SizedBox(height: 8),
          // Stars
          _StarRating(rating: rating),
          const SizedBox(height: 6),
          // Name
          Text(
            name,
            textAlign: TextAlign.center,
            style: AppText.overline.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 2),
          // Username
          Text(
            username,
            textAlign: TextAlign.center,
            style: AppText.overline.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7D7D7D),
            ),
          ),
          const SizedBox(height: 2),
          // Role
          Text(
            role,
            textAlign: TextAlign.center,
            style: AppText.overline.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7D7D7D),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating.floor() ? Icons.star : Icons.star_border,
          color: const Color(0xFFFFD700),
          size: 14,
        );
      }),
    );
  }
}
