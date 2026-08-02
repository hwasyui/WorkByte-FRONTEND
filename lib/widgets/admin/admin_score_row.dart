import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/admin_colors.dart';

class MeasuredScoreBar extends StatelessWidget {
  final String label;
  final double? value;
  final double? threshold;
  final bool isMeasured;

  final String? note;

  final bool higherIsWorse;
  final Color accent;

  const MeasuredScoreBar({
    super.key,
    required this.label,
    required this.value,
    this.threshold,
    this.isMeasured = true,
    this.note,
    this.higherIsWorse = false,
    this.accent = AdminColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final measured = isMeasured && value != null;
    final v = (value ?? 0).clamp(0.0, 1.0);

    Color barColor = accent;
    if (measured && threshold != null) {
      final over = v >= threshold!;
      final good = higherIsWorse ? !over : over;
      barColor = good ? AdminColors.green : AdminColors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AdminColors.body,
                    ),
                    children: [
                      if (note != null)
                        TextSpan(
                          text: '  $note',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AdminColors.faint,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (measured)
                Text(
                  v.toStringAsFixed(3),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: barColor,
                  ),
                )
              else
                _NotMeasuredPill(),
            ],
          ),
          if (measured) ...[
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                return SizedBox(
                  height: 8,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: v == 0 ? 0.01 : v,
                        child: Container(
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      if (threshold != null)
                        Positioned(
                          left: (w * threshold!.clamp(0.0, 1.0)) - 1,
                          top: -2,
                          bottom: -2,
                          child: Container(
                            width: 2,
                            color: AdminColors.ink,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            if (threshold != null) ...[
              const SizedBox(height: 3),
              Text(
                'Threshold ${threshold!.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AdminColors.faint,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _NotMeasuredPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AdminColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.remove_circle_outline_rounded,
              size: 11, color: AdminColors.faint),
          const SizedBox(width: 4),
          Text(
            'Not measured',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AdminColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class ModelVerdictChip extends StatelessWidget {
  final String? modelUsed;

  const ModelVerdictChip({super.key, required this.modelUsed});

  @override
  Widget build(BuildContext context) {
    final id = modelUsed ?? '';
    if (id.isEmpty) return const SizedBox.shrink();
    final isFallback = id.startsWith('sbert_');
    final color = isFallback ? AdminColors.amber : AdminColors.muted;
    final bg = isFallback ? AdminColors.amberBg : AdminColors.surfaceAlt;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: isFallback
            ? Border.all(color: AdminColors.amberBorder)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFallback
                ? Icons.warning_amber_rounded
                : Icons.memory_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isFallback ? 'Fallback: $id' : id,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
