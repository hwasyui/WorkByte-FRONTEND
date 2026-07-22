import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/admin/admin_dialog.dart';
import '../../../widgets/admin/admin_loading.dart';
import '../../../widgets/admin/admin_empty_state.dart';
import '../../../widgets/admin/admin_fade_in.dart';
import '../../../widgets/admin/admin_action_button.dart';

class AdminAppealsPage extends StatefulWidget {
  const AdminAppealsPage({super.key});

  @override
  State<AdminAppealsPage> createState() => _AdminAppealsPageState();
}

class _AdminAppealsPageState extends State<AdminAppealsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAppeals(status: 'all');
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final pending = admin.appeals
            .where((a) => a['status'] == 'pending')
            .toList();
        final resolved = admin.appeals
            .where((a) => a['status'] != 'pending')
            .toList();

        return Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: const Color(0xFF4F46E5),
                unselectedLabelColor: const Color(0xFF6B7280),
                indicatorColor: const Color(0xFF4F46E5),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
                tabs: [
                  Tab(text: 'Pending (${pending.length})'),
                  Tab(text: 'Resolved (${resolved.length})'),
                ],
              ),
            ),
            Expanded(
              child: admin.isAppealsLoading
                  ? const AdminSkeletonList()
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _AppealsList(
                          appeals: pending,
                          showActions: true,
                          emptyMessage: 'No pending appeals',
                        ),
                        _AppealsList(
                          appeals: resolved,
                          showActions: false,
                          emptyMessage: 'No resolved appeals',
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

// ── List ──────────────────────────────────────────────────────────────────────

class _AppealsList extends StatelessWidget {
  final List<Map<String, dynamic>> appeals;
  final bool showActions;
  final String emptyMessage;

  const _AppealsList({
    required this.appeals,
    required this.showActions,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (appeals.isEmpty) {
      return AdminEmptyState(
        icon: Icons.gavel_rounded,
        title: emptyMessage,
        accent: const Color(0xFF4F46E5),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AdminProvider>().loadAppeals(status: 'all'),
      color: const Color(0xFF4F46E5),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: appeals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => AdminFadeIn(
          index: i,
          child: _AppealCard(
            appeal: appeals[i],
            showActions: showActions,
          ),
        ),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _AppealCard extends StatelessWidget {
  final Map<String, dynamic> appeal;
  final bool showActions;

  const _AppealCard({required this.appeal, required this.showActions});

  @override
  Widget build(BuildContext context) {
    final isAccount = appeal['target_type'] == 'user';
    final status = appeal['status'] as String? ?? 'pending';
    final userName = appeal['user_name'] as String? ??
        appeal['user_email'] as String? ??
        'Unknown User';
    final message = appeal['message'] as String? ?? '';
    final jobTitle = appeal['job_title'] as String?;
    final createdAt = _fmtDate(appeal['created_at']?.toString());
    final actionedAt = _fmtDate(appeal['actioned_at']?.toString());
    final adminNote = appeal['admin_note'] as String?;
    final appealId = appeal['appeal_id']?.toString() ?? '';
    final appealAttempt = (appeal['appeal_attempt'] as num?)?.toInt() ?? 1;

    final statusColor = status == 'approved'
        ? const Color(0xFF059669)
        : status == 'rejected'
            ? const Color(0xFFDC2626)
            : const Color(0xFF4F46E5);
    final statusBg = status == 'approved'
        ? const Color(0xFFD1FAE5)
        : status == 'rejected'
            ? const Color(0xFFFFE4E6)
            : const Color(0xFFEEF2FF);

    return AdminHoverLift(
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isAccount
                  ? const Color(0xFFFFF7ED)
                  : const Color(0xFFF0F9FF),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isAccount
                        ? const Color(0xFFFED7AA)
                        : const Color(0xFFBAE6FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAccount
                        ? Icons.manage_accounts_rounded
                        : Icons.work_rounded,
                    size: 18,
                    color: isAccount
                        ? const Color(0xFFEA580C)
                        : const Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isAccount
                            ? 'Account Appeal'
                            : (jobTitle != null ? 'Job: $jobTitle' : 'Job Post Appeal'),
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
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Attempt $appealAttempt/2',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── message ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'USER MESSAGE',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9CA3AF),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF374151),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── admin note (resolved) ──
          if (adminNote != null && adminNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.admin_panel_settings_rounded,
                        size: 13, color: statusColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        adminNote,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: statusColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── dates ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Row(
              children: [
                Text(
                  'Submitted $createdAt',
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: const Color(0xFF9CA3AF)),
                ),
                if (actionedAt != null && actionedAt != '-') ...[
                  const SizedBox(width: 12),
                  Text(
                    '· Resolved $actionedAt',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: const Color(0xFF9CA3AF)),
                  ),
                ],
              ],
            ),
          ),

          // ── actions ──
          if (showActions && appealId.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: AdminActionButton(
                      label: 'Approve',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF059669),
                      style: AdminActionStyle.outlined,
                      onPressed: () => _showResolveDialog(
                        context,
                        appealId: appealId,
                        action: 'approve',
                        userName: userName,
                        isAccount: isAccount,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AdminActionButton(
                      label: 'Reject',
                      icon: Icons.cancel_rounded,
                      color: const Color(0xFFDC2626),
                      style: AdminActionStyle.outlined,
                      onPressed: () => _showResolveDialog(
                        context,
                        appealId: appealId,
                        action: 'reject',
                        userName: userName,
                        isAccount: isAccount,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 14),
        ],
      ),
      ),
    );
  }

  Future<void> _showResolveDialog(
    BuildContext context, {
    required String appealId,
    required String action,
    required String userName,
    required bool isAccount,
  }) async {
    final noteCtrl = TextEditingController();
    final isApprove = action == 'approve';

    final confirmed = await showAdminConfirmDialog(
      context,
      title: isApprove ? 'Approve Appeal?' : 'Reject Appeal?',
      message: isApprove
          ? isAccount
              ? 'Approving will restore $userName\'s account.'
              : 'Approving will reopen the job post.'
          : isAccount
              ? 'Rejecting will keep $userName\'s account closed.'
              : 'Rejecting will keep the job post closed.',
      icon: isApprove ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
      confirmLabel: isApprove ? 'Approve' : 'Reject',
      confirmColor: isApprove ? const Color(0xFF059669) : const Color(0xFFDC2626),
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Note to user (optional)',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: noteCtrl,
            maxLines: 3,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Explain your decision...',
              hintStyle: GoogleFonts.poppins(
                  fontSize: 12, color: const Color(0xFF9CA3AF)),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF4F46E5)),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok = await context.read<AdminProvider>().resolveAppeal(
          appealId,
          action,
          adminNote: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        );

    if (context.mounted) {
      if (ok) {
        AppToast.success('Appeal ${isApprove ? 'approved' : 'rejected'} successfully');
      } else {
        AppToast.error('Failed to process appeal');
      }
    }
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '-';
    try {
      final dt = DateTime.parse(d);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '-';
    }
  }
}

