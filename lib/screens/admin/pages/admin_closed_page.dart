import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/admin_provider.dart';

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

  static const _jobReasons = [
    'all',
    'content_violation',
    'scam',
    'community_reports',
    'admin_override',
  ];
  static const _accountRoles = ['all', 'freelancer', 'client', 'admin'];
  static const _accountReasons = ['all', 'community_reports', 'admin_override'];

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
                      Column(
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
                    onResetPage: () => setState(() => _jobPage = 1),
                    onPageChange: (page) {
                      setState(() => _jobPage = page);
                      admin.loadClosedJobs(page: page);
                    },
                  ),
                  _ClosedAccountsTab(
                    roles: _accountRoles,
                    reasons: _accountReasons,
                    page: _accountPage,
                    onResetPage: () => setState(() => _accountPage = 1),
                    onPageChange: (page) {
                      setState(() => _accountPage = page);
                      admin.loadClosedAccounts(page: page);
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
  final VoidCallback onResetPage;
  final ValueChanged<int> onPageChange;

  const _ClosedJobsTab({
    required this.reasons,
    required this.page,
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

        return Column(
          children: [
            _ClosedJobsFilterSection(
              reasons: reasons,
              selectedReason: admin.closedJobReasonFilter,
              count: total,
              onReasonSelect: (value) {
                onResetPage();
                admin.loadClosedJobs(closureReason: value, page: 1);
              },
            ),
            Expanded(
              child: admin.isClosedLoading && admin.closedJobs.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD97706),
                      ),
                    )
                  : admin.closedJobs.isEmpty
                  ? const _EmptyClosed(
                      icon: Icons.work_off_rounded,
                      text: 'No closed jobs found',
                    )
                  : RefreshIndicator(
                      color: const Color(0xFFD97706),
                      onRefresh: () => admin.loadClosedJobs(page: page),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: admin.closedJobs.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _ClosedJobCard(job: admin.closedJobs[i]),
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
  final VoidCallback onResetPage;
  final ValueChanged<int> onPageChange;

  const _ClosedAccountsTab({
    required this.roles,
    required this.reasons,
    required this.page,
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

        return Column(
          children: [
            _ClosedAccountsFilterSection(
              roles: roles,
              reasons: reasons,
              selectedRole: admin.closedAccountRoleFilter,
              selectedReason: admin.closedAccountReasonFilter,
              count: total,
              onRoleSelect: (value) {
                onResetPage();
                admin.loadClosedAccounts(role: value, page: 1);
              },
              onReasonSelect: (value) {
                onResetPage();
                admin.loadClosedAccounts(banReason: value, page: 1);
              },
            ),
            Expanded(
              child: admin.isClosedLoading && admin.closedAccounts.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD97706),
                      ),
                    )
                  : admin.closedAccounts.isEmpty
                  ? const _EmptyClosed(
                      icon: Icons.person_off_rounded,
                      text: 'No restricted accounts found',
                    )
                  : RefreshIndicator(
                      color: const Color(0xFFD97706),
                      onRefresh: () => admin.loadClosedAccounts(page: page),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: admin.closedAccounts.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ClosedAccountCard(
                          account: admin.closedAccounts[i],
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
    return _RecordCard(
      icon: Icons.work_outline_rounded,
      title: job['job_title']?.toString() ?? 'Untitled job',
      subtitle:
          job['client_email']?.toString() ??
          job['client_name']?.toString() ??
          'Unknown client',
      badge: _label(reason),
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

    return _RecordCard(
      icon: Icons.person_outline_rounded,
      title: name,
      subtitle: '${account['email'] ?? ''} - ${_label(role)}',
      badge: _label(reason),
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
  final String date;
  final String body;

  const _RecordCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.date,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              _Badge(text: badge),
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
    );
  }
}

class _ClosedJobsFilterSection extends StatelessWidget {
  final List<String> reasons;
  final String selectedReason;
  final int count;
  final ValueChanged<String> onReasonSelect;

  const _ClosedJobsFilterSection({
    required this.reasons,
    required this.selectedReason,
    required this.count,
    required this.onReasonSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list_rounded, size: 15, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                'Filter by Reason',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF9CA3AF), letterSpacing: 0.4),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                child: Text('$count closed', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: reasons.map((r) {
                final active = selectedReason == r;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onReasonSelect(r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFFD97706) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                        border: active ? null : Border.all(color: const Color(0xFFE5E7EB), width: 1),
                      ),
                      child: Text(
                        _label(r),
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : const Color(0xFF6B7280)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedAccountsFilterSection extends StatelessWidget {
  final List<String> roles;
  final List<String> reasons;
  final String selectedRole;
  final String selectedReason;
  final int count;
  final ValueChanged<String> onRoleSelect;
  final ValueChanged<String> onReasonSelect;

  const _ClosedAccountsFilterSection({
    required this.roles,
    required this.reasons,
    required this.selectedRole,
    required this.selectedReason,
    required this.count,
    required this.onRoleSelect,
    required this.onReasonSelect,
  });

  Widget _chipRow(List<String> options, String selected, ValueChanged<String> onTap) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final active = selected == opt;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onTap(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFD97706) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                  border: active ? null : Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: Text(
                  _label(opt),
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : const Color(0xFF6B7280)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list_rounded, size: 15, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                'Filters',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF9CA3AF), letterSpacing: 0.4),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                child: Text('$count restricted', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('ROLE', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFFB0B7C3), letterSpacing: 0.8)),
          const SizedBox(height: 6),
          _chipRow(roles, selectedRole, onRoleSelect),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),
          Text('REASON', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFFB0B7C3), letterSpacing: 0.8)),
          const SizedBox(height: 6),
          _chipRow(reasons, selectedReason, onReasonSelect),
        ],
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

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFD97706),
        ),
      ),
    );
  }
}

class _EmptyClosed extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyClosed({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: const Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text(
            text,
            style: GoogleFonts.poppins(color: const Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

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
