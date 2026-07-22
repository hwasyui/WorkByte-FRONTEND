import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/admin_provider.dart';
import '../../../widgets/admin/admin_fade_in.dart';

class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadOverviewData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final stats = admin.dashboardStats;
        final newUsers = _si(stats, 'new_freelancers_this_month') +
            _si(stats, 'new_clients_this_month');
        final newFreelancers = _si(stats, 'new_freelancers_this_month');
        final totalJobs = _si(stats, 'total_jobs_all') > 0
            ? _si(stats, 'total_jobs_all')
            : admin.totalJobs;
        final pending = admin.pendingReports;
        final accepted = _si(stats, 'reports_accepted');
        final dismissed = _si(stats, 'reports_dismissed');
        final totalReports = pending + accepted + dismissed;

        return RefreshIndicator(
          color: const Color(0xFF4F46E5),
          onRefresh: () => admin.loadOverviewData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (_, constraints) {
                final wide = constraints.maxWidth > 640;
                final usersCard = _StatCard(
                  icon: Icons.people_alt_rounded,
                  iconColor: const Color(0xFF4F46E5),
                  iconBg: const Color(0xFFEEF2FF),
                  title: 'Total Users',
                  subtitle: 'All registered users on the platform',
                  value: admin.totalUsers,
                  label: 'Total Users',
                  growthText: admin.totalUsers > 0 && newUsers > 0
                      ? '+${(newUsers / admin.totalUsers * 100).round()}% this month'
                      : null,
                  chartColor: const Color(0xFF4F46E5),
                  useBarChart: false,
                );
                final freelancersCard = _StatCard(
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFF059669),
                  iconBg: const Color(0xFFECFDF5),
                  title: 'Freelancers',
                  subtitle: 'All registered freelancers',
                  value: admin.totalFreelancers,
                  label: 'Freelancers',
                  growthText: admin.totalFreelancers > 0 && newFreelancers > 0
                      ? '+${(newFreelancers / admin.totalFreelancers * 100).round()}% this month'
                      : null,
                  chartColor: const Color(0xFF059669),
                  useBarChart: true,
                );
                final jobsCard = _StatCard(
                  icon: Icons.work_rounded,
                  iconColor: const Color(0xFF0891B2),
                  iconBg: const Color(0xFFECFEFF),
                  title: 'Jobs',
                  subtitle: 'All job postings on the platform',
                  value: totalJobs,
                  label: 'Total Jobs',
                  growthText: null,
                  chartColor: const Color(0xFF0891B2),
                  useBarChart: false,
                );
                final reportsCard = _ReportsCard(
                  pending: pending,
                  accepted: accepted,
                  dismissed: dismissed,
                  total: totalReports,
                );

                if (wide) {
                  return Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: usersCard),
                            const SizedBox(width: 16),
                            Expanded(child: freelancersCard),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: jobsCard),
                            const SizedBox(width: 16),
                            Expanded(child: reportsCard),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }
                return Column(
                  children: [
                    usersCard,
                    const SizedBox(height: 16),
                    freelancersCard,
                    const SizedBox(height: 16),
                    jobsCard,
                    const SizedBox(height: 16),
                    reportsCard,
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ─── Stat card (Total Users / Freelancers / Jobs) ─────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final int value;
  final String label;
  final String? growthText;
  final Color chartColor;
  final bool useBarChart;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.label,
    required this.growthText,
    required this.chartColor,
    required this.useBarChart,
  });

  @override
  Widget build(BuildContext context) {
    final data = _trend(value);
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: icon,
            iconColor: iconColor,
            iconBg: iconBg,
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left: stat info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CountUpNumber(
                      value: value,
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    if (growthText != null) ...[
                      const SizedBox(height: 12),
                      _GrowthBadge(text: growthText!, color: chartColor),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right: chart
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 110,
                  child: useBarChart
                      ? _BarChart(data: data, color: chartColor)
                      : _LineChart(data: data, color: chartColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Reports card ─────────────────────────────────────────────────────────────

class _ReportsCard extends StatelessWidget {
  final int pending;
  final int accepted;
  final int dismissed;
  final int total;

  const _ReportsCard({
    required this.pending,
    required this.accepted,
    required this.dismissed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.flag_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFFFBEB),
            title: 'Reports',
            subtitle: 'Overview of system reports',
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: big number
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CountUpNumber(
                    value: total,
                    style: GoogleFonts.poppins(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Reports',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _GrowthBadge(
                    text: pending > 0
                        ? '+$pending pending'
                        : '0 pending',
                    color: const Color(0xFFD97706),
                  ),
                ],
              ),
              const Spacer(),
              // Center: donut chart
              SizedBox(
                width: 100,
                height: 100,
                child: _DonutChart(
                  pending: pending,
                  accepted: accepted,
                  dismissed: dismissed,
                  total: total,
                ),
              ),
              const SizedBox(width: 20),
              // Right: legend
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReportLegend(
                    color: const Color(0xFFEA580C),
                    label: 'Open Reports',
                    count: pending,
                    total: total,
                  ),
                  const SizedBox(height: 12),
                  _ReportLegend(
                    color: const Color(0xFFFB923C),
                    label: 'In Review',
                    count: accepted,
                    total: total,
                  ),
                  const SizedBox(height: 12),
                  _ReportLegend(
                    color: const Color(0xFFFED7AA),
                    label: 'Resolved',
                    count: dismissed,
                    total: total,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared structural widgets ────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return AdminHoverLift(
      lift: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// Animates the big stat number counting up from 0 on first paint.
class _CountUpNumber extends StatelessWidget {
  final int value;
  final TextStyle style;
  const _CountUpNumber({required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(v.toString(), style: style),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;

  const _CardHeader({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GrowthBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _GrowthBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;

  const _ReportLegend({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0
        ? '(${(count / total * 100).toStringAsFixed(1)}%)'
        : '(0%)';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$count $pct',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

// ─── Charts ───────────────────────────────────────────────────────────────────

class _LineChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  const _LineChart({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return const SizedBox.shrink();
    final rawMax = data.reduce(max);
    final maxY = (rawMax <= 0 ? 10.0 : rawMax) * 1.2;
    final interval = (maxY / 4).ceilToDouble();

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1F2937),
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    s.y.toInt().toString(),
                    GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: Colors.white,
                strokeWidth: 1.5,
                strokeColor: color,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                const labels = [
                  'May 1',
                  'May 8',
                  'May 15',
                  'May 22',
                  'May 29'
                ];
                final i = value.toInt();
                if (i < 0 || i >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    labels[i],
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: const Color(0xFF9CA3AF),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0xFFF3F4F6),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  const _BarChart({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final rawMax = data.reduce(max);
    final maxY = (rawMax <= 0 ? 10.0 : rawMax) * 1.2;
    final interval = (maxY / 4).ceilToDouble();

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1F2937),
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(
              rod.toY.toInt().toString(),
              GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        maxY: maxY,
        barGroups: data.asMap().entries.map((e) {
          final isLast = e.key == data.length - 1;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: max(e.value, 0.01),
                color: isLast ? color : color.withOpacity(0.45),
                width: 20,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                const labels = [
                  'May 1',
                  'May 8',
                  'May 15',
                  'May 22',
                  'May 29'
                ];
                final i = value.toInt();
                if (i < 0 || i >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    labels[i],
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: const Color(0xFF9CA3AF),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0xFFF3F4F6),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        alignment: BarChartAlignment.spaceAround,
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  final int pending;
  final int accepted;
  final int dismissed;
  final int total;

  const _DonutChart({
    required this.pending,
    required this.accepted,
    required this.dismissed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    if (total <= 0) {
      return PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: 1,
              color: const Color(0xFFE5E7EB),
              showTitle: false,
              radius: 20,
            ),
          ],
          centerSpaceRadius: 30,
          sectionsSpace: 0,
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: [
          if (pending > 0)
            PieChartSectionData(
              value: pending.toDouble(),
              color: const Color(0xFFEA580C),
              showTitle: false,
              radius: 20,
            ),
          if (accepted > 0)
            PieChartSectionData(
              value: accepted.toDouble(),
              color: const Color(0xFFFB923C),
              showTitle: false,
              radius: 20,
            ),
          if (dismissed > 0)
            PieChartSectionData(
              value: dismissed.toDouble(),
              color: const Color(0xFFFED7AA),
              showTitle: false,
              radius: 20,
            ),
        ],
        centerSpaceRadius: 30,
        sectionsSpace: 2,
        startDegreeOffset: -90,
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

int _si(Map<String, dynamic> m, String k) =>
    (m[k] as num?)?.toInt() ?? 0;

List<double> _trend(int total) {
  if (total <= 0) return [2.0, 3.0, 3.0, 4.0, 5.0];
  final t = total.toDouble();
  return [
    (t * 0.52).roundToDouble(),
    (t * 0.65).roundToDouble(),
    (t * 0.76).roundToDouble(),
    (t * 0.89).roundToDouble(),
    t,
  ];
}
