import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/admin_provider.dart';
import '../../../widgets/admin/admin_fade_in.dart';
import '../../../widgets/admin/admin_empty_state.dart';

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
        final totalJobs = _si(stats, 'total_jobs_all') > 0
            ? _si(stats, 'total_jobs_all')
            : admin.totalJobs;
        final pending = admin.pendingReports;
        final accepted = _si(stats, 'reports_accepted');
        final dismissed = _si(stats, 'reports_dismissed');
        final totalReports = pending + accepted + dismissed;
        final pendingAppeals =
            admin.appeals.where((a) => a['status'] == 'pending').length;
        final disputes = admin.disputedContracts.length;
        final activityItems = _buildActivityItems(admin);

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
                  footer: _UserSplitBar(
                    freelancers: admin.totalFreelancers,
                    clients: admin.totalClients,
                  ),
                );
                final attentionCard = _AttentionCard(
                  pendingAppeals: pendingAppeals,
                  disputes: disputes,
                  onTapAppeals: () => admin.setPage(AdminPage.appeals),
                  onTapDisputes: () => admin.setPage(AdminPage.disputes),
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
                  useBarChart: true,
                );
                final reportsCard = _ReportsCard(
                  pending: pending,
                  accepted: accepted,
                  dismissed: dismissed,
                  total: totalReports,
                );

                final cardGrid = wide
                    ? Column(
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: usersCard),
                                const SizedBox(width: 16),
                                Expanded(child: attentionCard),
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
                        ],
                      )
                    : Column(
                        children: [
                          usersCard,
                          const SizedBox(height: 16),
                          attentionCard,
                          const SizedBox(height: 16),
                          jobsCard,
                          const SizedBox(height: 16),
                          reportsCard,
                        ],
                      );

                return Column(
                  children: [
                    _HeroBanner(
                      wide: wide,
                      pendingReports: pending,
                      pendingAppeals: pendingAppeals,
                      disputes: disputes,
                      onRefresh: () => admin.loadOverviewData(),
                    ),
                    const SizedBox(height: 20),
                    cardGrid,
                    const SizedBox(height: 16),
                    _RecentActivitySection(
                      items: activityItems,
                      onNavigate: admin.setPage,
                    ),
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

class _HeroBanner extends StatelessWidget {
  final bool wide;
  final int pendingReports;
  final int pendingAppeals;
  final int disputes;
  final VoidCallback onRefresh;

  const _HeroBanner({
    required this.wide,
    required this.pendingReports,
    required this.pendingAppeals,
    required this.disputes,
    required this.onRefresh,
  });

  String get _summary {
    final clauses = <String>[];
    if (pendingReports > 0) {
      clauses.add('$pendingReports report${pendingReports == 1 ? '' : 's'}');
    }
    if (pendingAppeals > 0) {
      clauses.add('$pendingAppeals appeal${pendingAppeals == 1 ? '' : 's'}');
    }
    if (disputes > 0) {
      clauses.add('$disputes dispute${disputes == 1 ? '' : 's'}');
    }
    if (clauses.isEmpty) {
      return "Everything's running smoothly — no items need attention right now.";
    }
    String joined;
    if (clauses.length == 1) {
      joined = clauses.first;
    } else if (clauses.length == 2) {
      joined = '${clauses[0]} and ${clauses[1]}';
    } else {
      joined = '${clauses.sublist(0, clauses.length - 1).join(', ')}, and ${clauses.last}';
    }
    return '$joined need your attention.';
  }

  @override
  Widget build(BuildContext context) {
    final refreshButton = OutlinedButton.icon(
      onPressed: onRefresh,
      icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
      label: Text(
        'Refresh',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.15),
        side: BorderSide(color: Colors.white.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    final chips = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BannerChip(icon: Icons.flag_rounded, label: 'Reports', count: pendingReports),
        const SizedBox(width: 8),
        _BannerChip(icon: Icons.gavel_rounded, label: 'Appeals', count: pendingAppeals),
        const SizedBox(width: 8),
        _BannerChip(icon: Icons.report_problem_rounded, label: 'Disputes', count: disputes),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.space_dashboard_rounded,
              size: 110,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _bannerText()),
                    const SizedBox(width: 20),
                    chips,
                    const SizedBox(width: 16),
                    refreshButton,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bannerText(),
                    const SizedBox(height: 16),
                    chips,
                    const SizedBox(height: 16),
                    refreshButton,
                  ],
                ),
        ],
      ),
    );
  }

  Widget _bannerText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Admin Overview',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _summary,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.white.withOpacity(0.85),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _BannerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _BannerChip({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserSplitBar extends StatelessWidget {
  final int freelancers;
  final int clients;

  const _UserSplitBar({required this.freelancers, required this.clients});

  @override
  Widget build(BuildContext context) {
    final total = freelancers + clients;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: total <= 0
                ? Container(color: const Color(0xFFF3F4F6))
                : Row(
                    children: [
                      Expanded(
                        flex: freelancers > 0 ? freelancers : 0,
                        child: Container(color: const Color(0xFF4F46E5)),
                      ),
                      Expanded(
                        flex: clients > 0 ? clients : 0,
                        child: Container(color: const Color(0xFF0891B2)),
                      ),
                      if (freelancers <= 0 && clients <= 0)
                        Expanded(child: Container(color: const Color(0xFFF3F4F6))),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _dot(const Color(0xFF4F46E5)),
            const SizedBox(width: 5),
            Text(
              'Freelancers $freelancers',
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(width: 12),
            _dot(const Color(0xFF0891B2)),
            const SizedBox(width: 5),
            Text(
              'Clients $clients',
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF6B7280)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dot(Color color) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _AttentionCard extends StatelessWidget {
  final int pendingAppeals;
  final int disputes;
  final VoidCallback onTapAppeals;
  final VoidCallback onTapDisputes;

  const _AttentionCard({
    required this.pendingAppeals,
    required this.disputes,
    required this.onTapAppeals,
    required this.onTapDisputes,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.priority_high_rounded,
            iconColor: const Color(0xFFDC2626),
            iconBg: const Color(0xFFFEF2F2),
            title: 'Needs Attention',
            subtitle: 'Appeals and disputes awaiting review',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _AttentionStat(
                  icon: Icons.gavel_rounded,
                  count: pendingAppeals,
                  label: 'Pending Appeals',
                  color: const Color(0xFFD97706),
                  bg: const Color(0xFFFFFBEB),
                  onTap: onTapAppeals,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AttentionStat(
                  icon: Icons.report_problem_rounded,
                  count: disputes,
                  label: 'Disputed Contracts',
                  color: const Color(0xFFDC2626),
                  bg: const Color(0xFFFEF2F2),
                  onTap: onTapDisputes,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttentionStat extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _AttentionStat({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: 16, color: color.withOpacity(0.6)),
              ],
            ),
            const SizedBox(height: 8),
            _CountUpNumber(
              value: count,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF6B7280),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

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
  final Widget? footer;

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
    this.footer,
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
          if (footer != null) ...[
            const SizedBox(height: 16),
            footer!,
          ],
        ],
      ),
    );
  }
}

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReportLegend(
                    color: const Color(0xFFEA580C),
                    label: 'Pending',
                    count: pending,
                  ),
                  const SizedBox(height: 12),
                  _ReportLegend(
                    color: const Color(0xFFF59E0B),
                    label: 'Confirmed',
                    count: accepted,
                  ),
                  const SizedBox(height: 12),
                  _ReportLegend(
                    color: const Color(0xFF059669),
                    label: 'Dismissed',
                    count: dismissed,
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

  const _ReportLegend({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
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
          '$count',
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
              color: const Color(0xFFF59E0B),
              showTitle: false,
              radius: 20,
            ),
          if (dismissed > 0)
            PieChartSectionData(
              value: dismissed.toDouble(),
              color: const Color(0xFF059669),
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

enum _ActivityType { job, appeal, dispute }

class _ActivityItem {
  final _ActivityType type;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final DateTime time;
  final AdminPage target;

  const _ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.time,
    required this.target,
  });
}

Color _jobStatusColor(String status) {
  switch (status) {
    case 'active':
      return const Color(0xFF059669);
    case 'filled':
      return const Color(0xFF0891B2);
    case 'closed':
      return const Color(0xFFDC2626);
    case 'draft':
      return const Color(0xFF9CA3AF);
    default:
      return const Color(0xFFD97706);
  }
}

DateTime _parseTime(dynamic raw) {
  if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
  return DateTime.tryParse(raw.toString()) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

List<_ActivityItem> _buildActivityItems(AdminProvider admin) {
  final items = <_ActivityItem>[];

  for (final job in admin.recentJobs) {
    final status = job['status'] as String? ?? 'draft';
    final color = _jobStatusColor(status);
    items.add(_ActivityItem(
      type: _ActivityType.job,
      title: job['job_title'] as String? ?? 'Untitled Job',
      subtitle: 'Posted by ${job['client_name'] as String? ?? 'Unknown client'}',
      statusLabel: status.replaceAll('_', ' '),
      statusColor: color,
      icon: Icons.work_rounded,
      iconColor: color,
      iconBg: color.withOpacity(0.1),
      time: _parseTime(job['posted_at'] ?? job['created_at']),
      target: AdminPage.jobs,
    ));
  }

  for (final appeal in admin.appeals) {
    if (appeal['status'] != 'pending') continue;
    final isAccount = appeal['target_type'] == 'user';
    final userName = appeal['user_name'] as String? ??
        appeal['user_email'] as String? ??
        'Unknown user';
    final jobTitle = appeal['job_title'] as String?;
    items.add(_ActivityItem(
      type: _ActivityType.appeal,
      title: isAccount ? 'Account appeal — $userName' : 'Job appeal — ${jobTitle ?? userName}',
      subtitle: (appeal['message'] as String? ?? '').trim(),
      statusLabel: 'Pending',
      statusColor: const Color(0xFFD97706),
      icon: Icons.gavel_rounded,
      iconColor: const Color(0xFFD97706),
      iconBg: const Color(0xFFFFFBEB),
      time: _parseTime(appeal['created_at']),
      target: AdminPage.appeals,
    ));
  }

  for (final contract in admin.disputedContracts) {
    final clientName = contract['client_name'] as String? ??
        contract['client_email'] as String? ??
        'Unknown client';
    final freelancerName = contract['freelancer_name'] as String? ??
        contract['freelancer_email'] as String? ??
        'Unknown freelancer';
    items.add(_ActivityItem(
      type: _ActivityType.dispute,
      title: 'Dispute — ${contract['contract_title'] as String? ?? 'Untitled Contract'}',
      subtitle: '$clientName vs $freelancerName',
      statusLabel: 'Disputed',
      statusColor: const Color(0xFFDC2626),
      icon: Icons.report_problem_rounded,
      iconColor: const Color(0xFFDC2626),
      iconBg: const Color(0xFFFEF2F2),
      time: _parseTime(contract['dispute_raised_at']),
      target: AdminPage.disputes,
    ));
  }

  items.sort((a, b) => b.time.compareTo(a.time));
  return items.take(8).toList();
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class _RecentActivitySection extends StatelessWidget {
  final List<_ActivityItem> items;
  final ValueChanged<AdminPage> onNavigate;

  const _RecentActivitySection({
    required this.items,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _CardHeader(
                  icon: Icons.dynamic_feed_rounded,
                  iconColor: const Color(0xFF4F46E5),
                  iconBg: const Color(0xFFEEF2FF),
                  title: 'Recent Activity',
                  subtitle: 'Latest items needing review',
                ),
              ),
              if (items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length} items',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: AdminEmptyState(
                icon: Icons.task_alt_rounded,
                title: 'All caught up',
                subtitle: 'No recent activity needs your attention.',
                accent: Color(0xFF4F46E5),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < items.length; i++)
                  AdminFadeIn(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ActivityRow(
                        item: items[i],
                        onTap: () => onNavigate(items[i].target),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final _ActivityItem item;
  final VoidCallback onTap;

  const _ActivityRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AdminHoverLift(
      lift: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 17, color: item.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ActivityBadge(label: item.statusLabel, color: item.statusColor),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(item.time),
                    style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ActivityBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

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
