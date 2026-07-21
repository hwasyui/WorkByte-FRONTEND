import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/admin/filter_dropdown_bar.dart';
import '../../../widgets/app_toast.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return Column(
          children: [
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
                  onSelect: (s) => admin.loadReports(status: s),
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
                  onSelect: (t) => admin.loadReports(reportedType: t),
                ),
              ],
            ),
            Expanded(
              child: admin.isTableLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                    )
                  : admin.reports.isEmpty
                      ? _EmptyState(
                          statusFilter: admin.reportsStatusFilter,
                          typeFilter: admin.reportsTypeFilter,
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF4F46E5),
                          onRefresh: () => admin.loadReports(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: admin.reports.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) => _ReportCard(
                              report: admin.reports[i],
                              onAccept: () => _handleAction(ctx, admin, admin.reports[i]['report_id'] as String, 'accept'),
                              onDismiss: () => _handleAction(ctx, admin, admin.reports[i]['report_id'] as String, 'dismiss'),
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
    String reportId,
    String action,
  ) async {
    final label = action == 'accept' ? 'Accept' : 'Dismiss';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$label Report?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        content: Text(
          action == 'accept'
              ? 'This confirms the violation. The report will be marked as accepted.'
              : 'This dismisses the report. No violation will be recorded.',
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'accept'
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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

    return Container(
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
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _typeLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _typeColor,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Reported target
            Row(
              children: [
                const Icon(Icons.flag_rounded, size: 14, color: Color(0xFFDC2626)),
                const SizedBox(width: 6),
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

            // Reporter
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

            // Reasons
            if (reasons.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: reasons.map((r) {
                  final label = r.replaceAll('_', ' ');
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

            // Custom reason
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

            // Admin note (if actioned)
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

            // Action buttons (pending only)
            if (isPending) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(
                        'Dismiss',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(
                        'Accept',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String statusFilter;
  final String typeFilter;
  const _EmptyState({required this.statusFilter, required this.typeFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            statusFilter == 'pending'
                ? Icons.check_circle_outline_rounded
                : Icons.inbox_outlined,
            size: 56,
            color: const Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 14),
          Text(
            statusFilter == 'pending' ? 'No pending reports' : 'No reports found',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try changing the filter above',
            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFD1D5DB)),
          ),
        ],
      ),
    );
  }
}
