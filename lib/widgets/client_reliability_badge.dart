import 'package:flutter/material.dart';
import '../core/constants/text_styles.dart';

/// Small chip showing a client's "Responsive" / "Unresponsive" label,
/// fetched from GET /clients/{id}/reliability. Renders nothing while loading
/// or if the label is unavailable, so it never blocks the surrounding layout.
class ClientReliabilityBadge extends StatelessWidget {
  final String? label;

  const ClientReliabilityBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    if (label == null || label!.isEmpty) return const SizedBox.shrink();

    final isGood = label == 'Responsive';
    final color = isGood ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final bg = isGood ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final icon = isGood ? Icons.check_circle_rounded : Icons.warning_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label!,
            style: AppText.overline.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
