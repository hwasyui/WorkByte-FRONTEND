import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadMoreButton extends StatelessWidget {
  final VoidCallback? onTap;

  const LoadMoreButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.expand_more, size: 25, color: Color(0xFFB6B5B5)),
          const SizedBox(width: 4),
          Text(
            'Load more',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB6B5B5),
              height: 15 / 10,
            ),
          ),
        ],
      ),
    );
  }
}
