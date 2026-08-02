import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/admin_colors.dart';
import '../../../models/admin_red_flag_detail_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/admin/admin_action_button.dart';
import '../../../widgets/admin/admin_dialog.dart';
import '../../../widgets/admin/admin_loading.dart';
import '../../../widgets/admin/admin_reason_dialog.dart';
import '../../../widgets/admin/admin_score_row.dart';
import '../../../widgets/app_toast.dart';
import 'review_moderation_detail_dialog.dart';

/// Opens the red-flag diagnosis dialog for a trust-score alert.
Future<void> showRedFlagDetailDialog(
  BuildContext context, {
  required String alertId,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (_) => AdminDetailDialogShell(
      child: _RedFlagDetailView(alertId: alertId),
    ),
  );
}

class _RedFlagDetailView extends StatefulWidget {
  final String alertId;
  const _RedFlagDetailView({required this.alertId});

  @override
  State<_RedFlagDetailView> createState() => _RedFlagDetailViewState();
}

class _RedFlagDetailViewState extends State<_RedFlagDetailView> {
  late Future<RedFlagDetail?> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AdminProvider>().fetchRedFlagDetail(widget.alertId);
  }

  void _reload() {
    setState(() {
      _future = context.read<AdminProvider>().fetchRedFlagDetail(widget.alertId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RedFlagDetail?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 320,
            child: Center(child: AdminLoadingIndicator()),
          );
        }
        final detail = snap.data;
        if (detail == null) {
          return _ErrorBody(onRetry: _reload);
        }
        return _LoadedBody(detail: detail);
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorBody({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 40, color: AdminColors.muted),
          const SizedBox(height: 12),
          Text(
            'Could not load this alert',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AdminColors.ink,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close',
                    style: GoogleFonts.poppins(color: AdminColors.muted)),
              ),
              const SizedBox(width: 8),
              AdminActionButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                color: AdminColors.primary,
                onPressed: onRetry,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  final RedFlagDetail detail;
  const _LoadedBody({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(detail: detail),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            children: [
              _ScoreHistoryChart(detail: detail),
              const _SectionDivider(),
              _ComponentsBreakdown(detail: detail),
              const _SectionDivider(),
              _RecentReviews(detail: detail),
              if (detail.heldReviewsInWindow.isNotEmpty) ...[
                const SizedBox(height: 14),
                _HeldReviewsPanel(detail: detail),
              ],
              if (detail.overriddenReviewsInWindow.isNotEmpty) ...[
                const SizedBox(height: 14),
                _OverriddenReviewsPanel(detail: detail),
              ],
              if (detail.otherOpenAlerts.isNotEmpty) ...[
                const _SectionDivider(),
                _OtherOpenAlerts(detail: detail),
              ],
            ],
          ),
        ),
        _ActionsBar(detail: detail),
      ],
    );
  }
}

// Header --------------------------------------------------------------------

class _Header extends StatelessWidget {
  final RedFlagDetail detail;
  const _Header({required this.detail});

  String _typeLabel(String raw) {
    if (raw.isEmpty) return 'Alert';
    return raw
        .split('_')
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final subject = detail.subject;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Pill(
                      label: subject.isClient ? 'CLIENT' : 'FREELANCER',
                      color: subject.isClient
                          ? AdminColors.purple
                          : AdminColors.primary,
                    ),
                    const SizedBox(width: 6),
                    _Pill(
                      label: _typeLabel(detail.alertType).toUpperCase(),
                      color: AdminColors.amber,
                    ),
                    if (detail.isResolved) ...[
                      const SizedBox(width: 6),
                      const _Pill(label: 'RESOLVED', color: AdminColors.green),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subject.name ?? 'Unknown subject',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail.message,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AdminColors.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AdminColors.muted,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// 1. Score history chart -----------------------------------------------------

class _ScoreHistoryChart extends StatelessWidget {
  final RedFlagDetail detail;
  const _ScoreHistoryChart({required this.detail});

  @override
  Widget build(BuildContext context) {
    final points = detail.scoreHistory
        .where((p) => p.score != null)
        .toList();
    final drop = detail.drop;

    return _Section(
      title: 'Trust score history',
      trailing: drop.delta != null
          ? _DeltaBadge(delta: drop.delta!)
          : null,
      child: points.length < 2
          ? Text(
              'Not enough history to plot.',
              style: GoogleFonts.poppins(fontSize: 12, color: AdminColors.faint),
            )
          : SizedBox(
              height: 160,
              child: _buildChart(points, drop),
            ),
    );
  }

  Widget _buildChart(List<ScoreHistoryPoint> points, ScoreDrop drop) {
    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.score!))
        .toList();

    // Find the index range of the drop segment to highlight it.
    int? dropStart;
    int? dropEnd;
    for (var i = 0; i < points.length; i++) {
      final at = points[i].recordedAt;
      if (at == null) continue;
      if (drop.fromRecordedAt != null &&
          dropStart == null &&
          !at.isBefore(drop.fromRecordedAt!)) {
        dropStart = i;
      }
      if (drop.toRecordedAt != null && !at.isAfter(drop.toRecordedAt!)) {
        dropEnd = i;
      }
    }

    final List<LineChartBarData> bars = [
      LineChartBarData(
        spots: spots,
        isCurved: false,
        color: AdminColors.primary,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 3,
            color: Colors.white,
            strokeWidth: 1.5,
            strokeColor: AdminColors.primary,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              AdminColors.primary.withOpacity(0.12),
              AdminColors.primary.withOpacity(0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    ];

    // Overlay the drop segment in red.
    if (dropStart != null && dropEnd != null && dropEnd > dropStart) {
      bars.add(
        LineChartBarData(
          spots: [
            for (var i = dropStart; i <= dropEnd; i++) spots[i],
          ],
          isCurved: false,
          color: AdminColors.red,
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
      );
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AdminColors.ink,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      s.y.toStringAsFixed(2),
                      GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ))
                .toList(),
          ),
        ),
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: 0,
        maxY: 1,
        lineBarsData: bars,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: ((points.length - 1) / 3).ceilToDouble().clamp(1, 999),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                final at = points[i].recordedAt;
                if (at == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${at.month}/${at.day}',
                    style: GoogleFonts.poppins(
                        fontSize: 9, color: AdminColors.faint),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 0.25,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  value.toStringAsFixed(2),
                  style:
                      GoogleFonts.poppins(fontSize: 9, color: AdminColors.faint),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.25,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AdminColors.surfaceAlt, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  final double delta;
  const _DeltaBadge({required this.delta});

  @override
  Widget build(BuildContext context) {
    final negative = delta < 0;
    final color = negative ? AdminColors.red : AdminColors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            negative ? Icons.trending_down_rounded : Icons.trending_up_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            'Δ ${delta.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// 2. Components breakdown ----------------------------------------------------

class _ComponentsBreakdown extends StatelessWidget {
  final RedFlagDetail detail;
  const _ComponentsBreakdown({required this.detail});

  String _label(String raw) => raw
      .split('_')
      .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final comps = detail.currentComponents;
    if (comps == null || comps.isEmpty) {
      return _Section(
        title: 'Trust score components',
        child: Text(
          'No current component breakdown is available for this subject.',
          style: GoogleFonts.poppins(fontSize: 12, color: AdminColors.faint),
        ),
      );
    }

    // A trust-score drop is caused by a LOW input, so the outlier is the entry
    // furthest BELOW the group — flag the lowest, plus anything within a small
    // band of it.
    final entries = comps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final lowest = entries.first.value;
    const band = 0.05;

    return _Section(
      title: 'Trust score components',
      subtitle: 'Lowest inputs first — the likely cause of the drop is flagged.',
      child: Column(
        children: entries.map((e) {
          final isCause = e.value <= lowest + band;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: EdgeInsets.symmetric(
              horizontal: isCause ? 10 : 0,
              vertical: isCause ? 4 : 0,
            ),
            decoration: isCause
                ? BoxDecoration(
                    color: AdminColors.redBg,
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Row(
              children: [
                if (isCause)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.error_outline_rounded,
                        size: 14, color: AdminColors.red),
                  ),
                Expanded(
                  child: MeasuredScoreBar(
                    label: _label(e.key),
                    value: e.value,
                    accent: isCause ? AdminColors.red : AdminColors.primary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// 3. Recent reviews ----------------------------------------------------------

class _RecentReviews extends StatelessWidget {
  final RedFlagDetail detail;
  const _RecentReviews({required this.detail});

  @override
  Widget build(BuildContext context) {
    final reviews = detail.recentReviews;
    return _Section(
      title: 'Recent reviews in window (${reviews.length})',
      child: reviews.isEmpty
          ? Text(
              'No reviews in the drop window.',
              style: GoogleFonts.poppins(fontSize: 12, color: AdminColors.faint),
            )
          : Column(
              children: reviews.map((r) => _ReviewRow(review: r)).toList(),
            ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewRow({required this.review});

  @override
  Widget build(BuildContext context) {
    final avgStars = (review['avg_stars'] as num?)?.toDouble();
    final status = review['status']?.toString() ?? '';
    final authenticity = (review['authenticity'] as num?)?.toDouble();
    final overallPass = review['overall_pass'];
    final reviewer = review['reviewer']?.toString() ??
        review['reviewer_name']?.toString() ??
        'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AdminColors.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (avgStars != null) ...[
            const Icon(Icons.star_rounded, size: 14, color: AdminColors.amber),
            const SizedBox(width: 3),
            Text(
              avgStars.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AdminColors.body,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              reviewer,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 12, color: AdminColors.body),
            ),
          ),
          if (authenticity != null) ...[
            Text(
              'auth ${authenticity.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(fontSize: 10, color: AdminColors.muted),
            ),
            const SizedBox(width: 8),
          ],
          if (overallPass != null)
            _PassChip(pass: overallPass == true),
          if (status.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AdminColors.faint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PassChip extends StatelessWidget {
  final bool pass;
  const _PassChip({required this.pass});

  @override
  Widget build(BuildContext context) {
    final color = pass ? AdminColors.green : AdminColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(pass ? Icons.check_rounded : Icons.close_rounded,
              size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            pass ? 'pass' : 'fail',
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// 4. Held reviews CTA --------------------------------------------------------

class _HeldReviewsPanel extends StatelessWidget {
  final RedFlagDetail detail;
  const _HeldReviewsPanel({required this.detail});

  @override
  Widget build(BuildContext context) {
    final held = detail.heldReviewsInWindow;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.amberBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.amberBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_rounded, size: 16, color: AdminColors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${detail.heldReviewCount} held review'
                  '${detail.heldReviewCount == 1 ? '' : 's'} — rule on '
                  '${detail.heldReviewCount == 1 ? 'it' : 'these'} first',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.body,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Resolving this alert before adjudicating the held reviews may hide '
            'the underlying cause.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AdminColors.body,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          ...held.map((r) => _DeepLinkReviewRow(review: r)),
        ],
      ),
    );
  }
}

// 5. Overridden reviews ------------------------------------------------------

class _OverriddenReviewsPanel extends StatelessWidget {
  final RedFlagDetail detail;
  const _OverriddenReviewsPanel({required this.detail});

  @override
  Widget build(BuildContext context) {
    final items = detail.overriddenReviewsInWindow;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.published_with_changes_rounded,
                  size: 16, color: AdminColors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Published over pipeline objection '
                  '(${detail.overriddenReviewCount})',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.body,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'These failed the pipeline (overall_pass = false) but an admin '
            'published them anyway — frequently the actual cause of the drop.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AdminColors.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map((r) => _DeepLinkReviewRow(review: r)),
        ],
      ),
    );
  }
}

/// A tappable review row that deep-links into the review moderation dialog.
/// Closes the current red-flag dialog first so only one detail dialog is open.
class _DeepLinkReviewRow extends StatelessWidget {
  final Map<String, dynamic> review;
  const _DeepLinkReviewRow({required this.review});

  @override
  Widget build(BuildContext context) {
    final id = (review['id'] ?? review['review_id'] ?? '').toString();
    final isClient = review['review_type'] == 'client' ||
        review['is_client_review'] == true;
    final label = review['reviewer']?.toString() ??
        review['reviewer_name']?.toString() ??
        review['overall_comment']?.toString() ??
        'Review $id';

    return InkWell(
      onTap: id.isEmpty
          ? null
          : () {
              Navigator.pop(context);
              showReviewModerationDialog(
                context,
                id: id,
                isClientReview: isClient,
              );
            },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AdminColors.primary,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: AdminColors.primary),
          ],
        ),
      ),
    );
  }
}

// 6. Other open alerts -------------------------------------------------------

class _OtherOpenAlerts extends StatelessWidget {
  final RedFlagDetail detail;
  const _OtherOpenAlerts({required this.detail});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Other open alerts (${detail.otherOpenAlerts.length})',
      child: Column(
        children: detail.otherOpenAlerts.map((a) {
          final id = (a['id'] ?? a['alert_id'] ?? '').toString();
          final msg = a['message']?.toString() ?? 'Alert';
          return InkWell(
            onTap: id.isEmpty
                ? null
                : () {
                    Navigator.pop(context);
                    showRedFlagDetailDialog(context, alertId: id);
                  },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.flag_outlined,
                      size: 14, color: AdminColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      msg,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AdminColors.body),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: AdminColors.faint),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Actions --------------------------------------------------------------------

class _ActionsBar extends StatelessWidget {
  final RedFlagDetail detail;
  const _ActionsBar({required this.detail});

  Future<void> _resolve(BuildContext context) async {
    final admin = context.read<AdminProvider>();
    final alertId = detail.alertId;
    final hasHeld = detail.heldReviewsInWindow.isNotEmpty;
    final outcome = await showAdminReasonDialog(
      context,
      title: 'Resolve this alert?',
      submitLabel: 'Resolve',
      accentColor: AdminColors.green,
      icon: Icons.check_circle_outline_rounded,
      warningText: hasHeld
          ? 'There are still held reviews in this window. Consider ruling on '
              'them before clearing the alert.'
          : null,
      onSubmit: (reason) => admin.resolveReviewRedFlag(alertId, reason: reason),
    );
    if (outcome != null && outcome.success && context.mounted) {
      Navigator.pop(context);
      if (outcome.resolutionRecorded == false) {
        AppToast.error(
          'Alert resolved, but the note was NOT stored — the database '
          'migration is still pending.',
        );
      } else {
        AppToast.success('Alert resolved.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (detail.isResolved) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        decoration: const BoxDecoration(
          color: AdminColors.surfaceSoft,
          border: Border(top: BorderSide(color: AdminColors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 15, color: AdminColors.green),
                const SizedBox(width: 6),
                Text(
                  'This alert has been resolved.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.body,
                  ),
                ),
              ],
            ),
            if (detail.resolutionNote != null) ...[
              const SizedBox(height: 4),
              Text(
                detail.resolutionNote!,
                style:
                    GoogleFonts.poppins(fontSize: 12, color: AdminColors.muted),
              ),
            ],
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AdminColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: AdminActionButton(
          label: 'Resolve alert',
          icon: Icons.check_circle_outline_rounded,
          color: AdminColors.green,
          onPressed: () => _resolve(context),
        ),
      ),
    );
  }
}

// Shared layout primitives ---------------------------------------------------

class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  const _Section({
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.ink,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: GoogleFonts.poppins(fontSize: 11, color: AdminColors.faint),
          ),
        ],
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Divider(height: 1, color: AdminColors.border),
      );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
