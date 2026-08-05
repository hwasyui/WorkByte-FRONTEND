import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';

class PostJobLoadingView extends StatelessWidget {
  final String label;

  const PostJobLoadingView({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.6,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
