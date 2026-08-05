import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/admin/filter_dropdown_bar.dart';
import '../../../widgets/admin/date_range_filter_button.dart';
import '../../../widgets/admin/admin_dialog.dart';
import '../../../widgets/admin/admin_empty_state.dart';
import '../../../widgets/admin/admin_fade_in.dart';
import '../../../widgets/admin/admin_loading.dart';
import '../../../widgets/admin/admin_badge.dart';
import '../../../widgets/admin/admin_action_button.dart';
import '../../../core/utils/text_format.dart';
import '../../../widgets/app_toast.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  DateTimeRange? _dateRange;

  String? _isoDate(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadReports();
    });
  }

  void _onDateRangeChanged(DateTimeRange? range) {
    setState(() => _dateRange = range);
    context.read<AdminProvider>().loadReports(
      startDate: _isoDate(range?.start),
      endDate: _isoDate(range?.end),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final startDate = _isoDate(_dateRange?.start);
        final endDate = _isoDate(_dateRange?.end);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.report_problem_rounded,
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
                          'Reports',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'User-submitted reports awaiting review',
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
                  ),
                ],
              ),
            ),
            FilterDropdownBar(
              summaryText: admin.reportsStatusFilter != 'all' || admin.reportsTypeFilter != 'all'
                  ? 'Filters active'
                  : 'All reports',
              hasActiveFilter: admin.reportsStatusFilter != 'all' || admin.reportsTypeFilter != 'all',
              accentColor: const Color(0xFFD97706),
              count: admin.reports.length,
              groups: [
                FilterGroupData(
                  label: 'STATUS',
                  options: const ['all', 'pending', 'accepted', 'dismissed'],
                  labelFor: (s) => s == 'all' ? 'All' : '${s[0].toUpperCase()}${s.substring(1)}',
                  selected: admin.reportsStatusFilter,
                  onSelect: (s) => admin.loadReports(status: s, startDate: startDate, endDate: endDate),
                ),
                FilterGroupData(
                  label: 'TYPE',
                  options: const ['all', 'freelancer', 'client', 'job_post'],
                  labelFor: (t) {
                    switch (t) {
                      case 'all': return 'All';
                      case 'job_post': return 'Job Post';
                      default: return '${t[0].toUpperCase()}${t.substring(1)}';
                    }
                  },
                  selected: admin.reportsTypeFilter,
                  onSelect: (t) => admin.loadReports(reportedType: t, startDate: startDate, endDate: endDate),
                ),
              ],
            ),
            Expanded(
              child: admin.isTableLoading
                  ? const AdminSkeletonList()
                  : admin.reports.isEmpty
                      ? AdminEmptyState(
                          icon: admin.reportsStatusFilter == 'pending'
                              ? Icons.check_circle_outline_rounded
                              : Icons.inbox_outlined,
                          title: admin.reportsStatusFilter == 'pending'
                              ? 'No pending reports'
                              : 'No reports found',
                          subtitle: 'Try changing the filter above',
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF4F46E5),
                          onRefresh: () => admin.loadReports(startDate: startDate, endDate: endDate),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: admin.reports.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) => AdminFadeIn(
                              index: i,
                              child: _ReportCard(
                                report: admin.reports[i],
                                onAccept: () => _handleAction(ctx, admin, admin.reports[i], 'accept'),
                                onDismiss: () => _handleAction(ctx, admin, admin.reports[i], 'dismiss'),
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    AdminProvider admin,
    Map<String, dynamic> report,
    String action,
  ) async {
    final reportId = report['report_id'] as String;
    final label = action == 'accept' ? 'Accept' : 'Dismiss';
    final isEngagedJob = action == 'accept'
        && (report['reported_type'] as String? ?? '') == 'job_post'
        && report['is_engaged'] == true;
    final confirmed = await showAdminConfirmDialog(
      context,
      title: isEngagedJob ? 'Job Has an Active Contract' : '$label Report?',
      message: action != 'accept'
          ? 'This dismisses the report. No violation will be recorded.'
          : isEngagedJob
              ? 'This job already has an active contract or an engaged freelancer — '
                  'there is an ongoing commitment on it. Accepting this report will '
                  'close the job and end that live work. Are you sure you want to close it?'
              : 'This confirms the violation. The report will be marked as accepted.',
      icon: isEngagedJob
          ? Icons.handshake_outlined
          : action == 'accept'
              ? Icons.check_circle_outline_rounded
              : Icons.close_rounded,
      confirmLabel: label,
      confirmColor: action == 'accept' ? const Color(0xFF059669) : const Color(0xFFDC2626),
    );

    if (confirmed == true && context.mounted) {
      final success = await admin.actionReport(reportId, action);
      if (context.mounted) {
        if (success) {
          AppToast.success('Report ${action == 'accept' ? 'accepted' : 'dismissed'} successfully.');
        } else {
          AppToast.error('Failed to action report.');
        }
      }
    }
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const _ReportCard({
    required this.report,
    required this.onAccept,
    required this.onDismiss,
  });

  Color get _statusColor {
    switch (report['status'] as String? ?? 'pending') {
      case 'accepted':  return const Color(0xFF059669);
      case 'dismissed': return const Color(0xFF6B7280);
      default:          return const Color(0xFFD97706);
    }
  }

  Color get _typeColor {
    switch (report['reported_type'] as String? ?? '') {
      case 'freelancer': return const Color(0xFF059669);
      case 'client':     return const Color(0xFF0891B2);
      case 'job_post':   return const Color(0xFF7C3AED);
      default:           return const Color(0xFF9CA3AF);
    }
  }

  String get _typeLabel {
    switch (report['reported_type'] as String? ?? '') {
      case 'freelancer': return 'Freelancer';
      case 'client':     return 'Client';
      case 'job_post':   return 'Job Post';
      default:           return 'Unknown';
    }
  }

  String get _targetName {
    if (report['reported_type'] == 'job_post') {
      return report['job_post_title'] as String? ?? 'Unnamed Job';
    }
    return report['reported_email'] as String? ?? 'Unknown';
  }

  List<String> get _reasons {
    final raw = report['reasons'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) {
      final cleaned = raw.replaceAll(RegExp(r'[\[\]"]'), '');
      return cleaned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = report['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final reasons = _reasons;

    return AdminHoverLift(
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isPending
            ? Border.all(color: const Color(0xFFD97706).withOpacity(0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AdminBadge(label: _typeLabel, color: _typeColor),
                if (report['reported_type'] == 'job_post' && report['is_engaged'] == true) ...[
                  const SizedBox(width: 6),
                  const Tooltip(
                    message: 'Has an active contract / engaged freelancer',
                    child: Icon(Icons.handshake_outlined, size: 15, color: Color(0xFFD97706)),
                  ),
                ],
                const Spacer(),
                AdminBadge(
                  label: status[0].toUpperCase() + status.substring(1),
                  color: _statusColor,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Text(
                  'Reported:',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _targetName,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Text(
                  'By:',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report['reporter_email'] as String? ?? 'Unknown',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF374151),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatDate(report['created_at'] as String?),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),

            if (reasons.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: reasons.map((r) {
                  final label = toTitleCase(r);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            if ((report['custom_reason'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  '"${report['custom_reason']}"',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
            ],

            if (!isPending && (report['admin_note'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  'Admin note: ${report['admin_note']}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF166534),
                  ),
                ),
              ),
            ],

            if (isPending) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AdminActionButton(
                      label: 'Dismiss',
                      icon: Icons.close_rounded,
                      color: const Color(0xFF6B7280),
                      style: AdminActionStyle.outlined,
                      onPressed: onDismiss,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminActionButton(
                      label: 'Accept',
                      icon: Icons.check_rounded,
                      color: const Color(0xFF059669),
                      onPressed: onAccept,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

