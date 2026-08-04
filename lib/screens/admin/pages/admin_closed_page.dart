import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/moderation_display.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/admin/filter_dropdown_bar.dart';
import '../../../widgets/admin/admin_loading.dart';
import '../../../widgets/admin/admin_empty_state.dart';
import '../../../widgets/admin/admin_fade_in.dart';
import '../../../widgets/admin/admin_badge.dart';
import '../../../widgets/admin/date_range_filter_button.dart';

class AdminClosedPage extends StatefulWidget {
  const AdminClosedPage({super.key});

  @override
  State<AdminClosedPage> createState() => _AdminClosedPageState();
}

class _AdminClosedPageState extends State<AdminClosedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _jobPage = 1;
  int _accountPage = 1;
  DateTimeRange? _dateRange;

  static const _jobReasons = [
    'all',
    kClosureReasonHarmfulText,
    'scam',
    'community_reports',
    'admin_override',
  ];
  static const _accountRoles = ['all', 'freelancer', 'client', 'admin'];
  static const _accountReasons = ['all', 'community_reports', 'admin_override'];

  void _onDateRangeChanged(DateTimeRange? range) {
    setState(() {
      _dateRange = range;
      _jobPage = 1;
      _accountPage = 1;
    });
    final admin = context.read<AdminProvider>();
    admin.loadClosedJobs(
      page: 1,
      closedFrom: _isoDate(range?.start),
      closedTo: _isoDate(range?.end),
    );
    admin.loadClosedAccounts(
      page: 1,
      bannedFrom: _isoDate(range?.start),
      bannedTo: _isoDate(range?.end),
    );
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.loadClosedJobs();
      admin.loadClosedAccounts();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lock_clock_rounded,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Closed Items',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            Text(
                              'Closed jobs and restricted accounts',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DateRangeFilterButton(
                        range: _dateRange,
                        onChanged: _onDateRangeChanged,
                        accentColor: const Color(0xFFD97706),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tab,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
                    labelColor: const Color(0xFFD97706),
                    unselectedLabelColor: const Color(0xFF6B7280),
                    indicatorColor: const Color(0xFFD97706),
                    indicatorWeight: 2.5,
                    tabs: const [
                      Tab(text: 'Closed Jobs'),
                      Tab(text: 'Restricted Accounts'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _ClosedJobsTab(
                    reasons: _jobReasons,
                    page: _jobPage,
                    dateRange: _dateRange,
                    onResetPage: () => setState(() => _jobPage = 1),
                    onPageChange: (page) {
                      setState(() => _jobPage = page);
                      admin.loadClosedJobs(
                        page: page,
                        closedFrom: _isoDate(_dateRange?.start),
                        closedTo: _isoDate(_dateRange?.end),
                      );
                    },
                  ),
                  _ClosedAccountsTab(
                    roles: _accountRoles,
                    reasons: _accountReasons,
                    page: _accountPage,
                    dateRange: _dateRange,
                    onResetPage: () => setState(() => _accountPage = 1),
                    onPageChange: (page) {
                      setState(() => _accountPage = page);
                      admin.loadClosedAccounts(
                        page: page,
                        bannedFrom: _isoDate(_dateRange?.start),
                        bannedTo: _isoDate(_dateRange?.end),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClosedJobsTab extends StatelessWidget {
  final List<String> reasons;
  final int page;
  final DateTimeRange? dateRange;
  final VoidCallback onResetPage;
  final ValueChanged<int> onPageChange;

  const _ClosedJobsTab({
    required this.reasons,
    required this.page,
    required this.dateRange,
    required this.onResetPage,
    required this.onPageChange,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final total =
            (admin.closedJobPagination['total'] as num?)?.toInt() ?? 0;
        final totalPages =
            (admin.closedJobPagination['total_pages'] as num?)?.toInt() ?? 1;
        final closedFrom = _isoDate(dateRange?.start);
        final closedTo = _isoDate(dateRange?.end);

        return Column(
          children: [
            FilterDropdownBar(
              summaryText: admin.closedJobReasonFilter == 'all'
                  ? 'All reasons'
                  : _label(admin.closedJobReasonFilter),
              hasActiveFilter: admin.closedJobReasonFilter != 'all',
              accentColor: const Color(0xFFD97706),
              count: total,
              groups: [
                FilterGroupData(
                  label: 'REASON',
                  options: reasons,
                  labelFor: _label,
                  selected: admin.closedJobReasonFilter,
                  onSelect: (value) {
                    onResetPage();
                    admin.loadClosedJobs(
                      closureReason: value,
                      page: 1,
                      closedFrom: closedFrom,
                      closedTo: closedTo,
                    );
                  },
                ),
              ],
            ),
            Expanded(
              child: admin.isClosedLoading && admin.closedJobs.isEmpty
                  ? const AdminSkeletonList()
                  : admin.closedJobs.isEmpty
                  ? const AdminEmptyState(
                      icon: Icons.work_off_rounded,
                      title: 'No closed jobs found',
                      accent: Color(0xFFD97706),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFFD97706),
                      onRefresh: () => admin.loadClosedJobs(
                        page: page,
                        closedFrom: closedFrom,
                        closedTo: closedTo,
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: admin.closedJobs.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => AdminFadeIn(
                          index: i,
                          child: _ClosedJobCard(job: admin.closedJobs[i]),
                        ),
                      ),
                    ),
            ),
            _Pagination(
              page: page,
              totalPages: totalPages,
              onPageChange: onPageChange,
            ),
          ],
        );
      },
    );
  }
}

class _ClosedAccountsTab extends StatelessWidget {
  final List<String> roles;
  final List<String> reasons;
  final int page;
  final DateTimeRange? dateRange;
  final VoidCallback onResetPage;
  final ValueChanged<int> onPageChange;

  const _ClosedAccountsTab({
    required this.roles,
    required this.reasons,
    required this.page,
    required this.dateRange,
    required this.onResetPage,
    required this.onPageChange,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final total =
            (admin.closedAccountPagination['total'] as num?)?.toInt() ?? 0;
        final totalPages =
            (admin.closedAccountPagination['total_pages'] as num?)?.toInt() ??
            1;
        final bannedFrom = _isoDate(dateRange?.start);
        final bannedTo = _isoDate(dateRange?.end);

        return Column(
          children: [
            FilterDropdownBar(
              summaryText: admin.closedAccountRoleFilter != 'all' || admin.closedAccountReasonFilter != 'all'
                  ? 'Filters active'
                  : 'All accounts',
              hasActiveFilter: admin.closedAccountRoleFilter != 'all' || admin.closedAccountReasonFilter != 'all',
              accentColor: const Color(0xFFD97706),
              count: total,
              groups: [
                FilterGroupData(
                  label: 'ROLE',
                  options: roles,
                  labelFor: _label,
                  selected: admin.closedAccountRoleFilter,
                  onSelect: (value) {
                    onResetPage();
                    admin.loadClosedAccounts(
                      role: value,
                      page: 1,
                      bannedFrom: bannedFrom,
                      bannedTo: bannedTo,
                    );
                  },
                ),
                FilterGroupData(
                  label: 'REASON',
                  options: reasons,
                  labelFor: _label,
                  selected: admin.closedAccountReasonFilter,
                  onSelect: (value) {
                    onResetPage();
                    admin.loadClosedAccounts(
                      banReason: value,
                      page: 1,
                      bannedFrom: bannedFrom,
                      bannedTo: bannedTo,
                    );
                  },
                ),
              ],
            ),
            Expanded(
              child: admin.isClosedLoading && admin.closedAccounts.isEmpty
                  ? const AdminSkeletonList()
                  : admin.closedAccounts.isEmpty
                  ? const AdminEmptyState(
                      icon: Icons.person_off_rounded,
                      title: 'No restricted accounts found',
                      accent: Color(0xFFD97706),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFFD97706),
                      onRefresh: () => admin.loadClosedAccounts(
                        page: page,
                        bannedFrom: bannedFrom,
                        bannedTo: bannedTo,
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: admin.closedAccounts.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => AdminFadeIn(
                          index: i,
                          child: _ClosedAccountCard(
                            account: admin.closedAccounts[i],
                          ),
                        ),
                      ),
                    ),
            ),
            _Pagination(
              page: page,
              totalPages: totalPages,
              onPageChange: onPageChange,
            ),
          ],
        );
      },
    );
  }
}

class _ClosedJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _ClosedJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final reason = job['closure_reason']?.toString() ?? 'closed';
    final note = job['closure_note']?.toString() ?? '';
    final meta = _reasonMeta(reason);
    return _RecordCard(
      icon: Icons.work_outline_rounded,
      title: job['job_title']?.toString() ?? 'Untitled job',
      subtitle:
          job['client_email']?.toString() ??
          job['client_name']?.toString() ??
          'Unknown client',
      badge: meta.label,
      badgeColor: meta.color,
      date: _formatDate(job['closed_at']?.toString()),
      body: note,
    );
  }
}

class _ClosedAccountCard extends StatelessWidget {
  final Map<String, dynamic> account;
  const _ClosedAccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final role = account['role']?.toString() ?? 'user';
    final freelancerName = account['freelancer_name']?.toString() ?? '';
    final clientName = account['client_name']?.toString() ?? '';
    final name = freelancerName.isNotEmpty
        ? freelancerName
        : clientName.isNotEmpty
        ? clientName
        : account['email']?.toString() ?? 'Unknown account';
    final reason = account['ban_reason']?.toString() ?? 'restricted';
    final message = account['ban_message']?.toString() ?? '';
    final meta = _reasonMeta(reason);

    return _RecordCard(
      icon: Icons.person_outline_rounded,
      title: name,
      subtitle: '${account['email'] ?? ''} - ${_label(role)}',
      badge: meta.label,
      badgeColor: meta.color,
      date: _formatDate(account['report_banned_at']?.toString()),
      body: message,
    );
  }
}

class _RecordCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final String date;
  final String body;

  const _RecordCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.date,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return AdminHoverLift(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFFD97706)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AdminBadge(label: badge, color: badgeColor, outlined: true),
              ],
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                body,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF4B5563),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              date,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _Pagination extends StatelessWidget {
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChange;

  const _Pagination({
    required this.page,
    required this.totalPages,
    required this.onPageChange,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $page of $totalPages',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: page > 1 ? () => onPageChange(page - 1) : null,
                color: const Color(0xFFD97706),
                iconSize: 20,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: page < totalPages
                    ? () => onPageChange(page + 1)
                    : null,
                color: const Color(0xFFD97706),
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

({String label, Color color}) _reasonMeta(String reason) {
  switch (reason) {
    case 'scam':
      return (label: 'Job Scam Detection', color: const Color(0xFFC2410C));
    case kClosureReasonHarmfulText:
      return (label: 'Harmful Text Detection', color: const Color(0xFFDB2777));
    case 'community_reports':
      return (label: 'Community Reports', color: const Color(0xFFEA580C));
    case 'admin_override':
      return (label: 'Admin Override', color: const Color(0xFF4F46E5));
    default:
      return (label: _label(reason), color: const Color(0xFFDC2626));
  }
}

String? _isoDate(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _label(String value) {
  if (value.isEmpty) return '-';
  return value
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '-';
  try {
    final dt = DateTime.parse(dateStr);
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) {
    return '-';
  }
}
