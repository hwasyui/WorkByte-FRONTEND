import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../core/utils/app_snackbar.dart';

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
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4F46E5),
                      ),
                    )
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.gavel_rounded,
                size: 30,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              emptyMessage,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AdminProvider>().loadAppeals(status: 'all'),
      color: const Color(0xFF4F46E5),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: appeals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _AppealCard(
          appeal: appeals[i],
          showActions: showActions,
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

    return Container(
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
                    child: _ActionButton(
                      label: 'Approve',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF059669),
                      bgColor: const Color(0xFFD1FAE5),
                      onTap: () => _showResolveDialog(
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
                    child: _ActionButton(
                      label: 'Reject',
                      icon: Icons.cancel_rounded,
                      color: const Color(0xFFDC2626),
                      bgColor: const Color(0xFFFFE4E6),
                      onTap: () => _showResolveDialog(
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isApprove ? 'Approve Appeal?' : 'Reject Appeal?',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApprove
                  ? isAccount
                      ? 'Approving will restore $userName\'s account.'
                      : 'Approving will reopen the job post.'
                  : isAccount
                      ? 'Rejecting will keep $userName\'s account closed.'
                      : 'Rejecting will keep the job post closed.',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 14),
            Text(
              'Note to user (optional)',
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: const Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isApprove ? 'Approve' : 'Reject',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600),
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
      AppSnackBar.show(
        context,
        ok ? 'Appeal ${isApprove ? 'approved' : 'rejected'} successfully' : 'Failed to process appeal',
        type: ok ? SnackBarType.success : SnackBarType.error,
      );
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

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
