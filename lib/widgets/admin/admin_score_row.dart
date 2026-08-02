import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/admin_colors.dart';

/// A single 0–1 score rendered as a labelled bar against an optional threshold.
///
/// The core rule of the moderation UI: a null score, or `isMeasured == false`,
/// is NOT zero. It renders an explicit "Not measured" state (no bar) so a blank
/// scorecard never reads as "every model scored this badly". Pass
/// [isMeasured] = false for the telemetry case where the platform never
/// captured the metric (e.g. on_time_measurable == false).
class MeasuredScoreBar extends StatelessWidget {
  final String label;
  final double? value; // 0..1
  final double? threshold; // 0..1, draws a marker + pass/fail tint
  final bool isMeasured;

  /// Extra note shown after the label (e.g. "length-adjusted", revision count).
  final String? note;

  /// When true, higher is worse (fake probability); tints red above threshold.
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
      // higherIsWorse: over threshold is bad (red); else over threshold is good.
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

/// Small chip naming the model that produced a verdict. When the model id
/// starts with `sbert_` it flips to an amber warning chip, signalling a weaker
/// fallback model answered.
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
