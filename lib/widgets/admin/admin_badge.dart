import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Small pill/chip used for status, type, and reason labels across the
/// admin pages. Consolidates the half-dozen near-identical private badge
/// widgets each page used to define on its own.
class AdminBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool outlined;

  const AdminBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: outlined ? Border.all(color: color.withOpacity(0.35)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
