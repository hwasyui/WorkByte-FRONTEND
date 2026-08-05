import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/admin_colors.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/admin/admin_action_button.dart';
import '../../../widgets/admin/admin_badge.dart';
import '../../../widgets/admin/admin_dialog.dart';
import '../../../widgets/admin/admin_empty_state.dart';
import '../../../widgets/admin/admin_fade_in.dart';
import '../../../widgets/admin/admin_loading.dart';
import '../../../widgets/admin/date_range_filter_button.dart';

class AdminDisputesPage extends StatefulWidget {
  const AdminDisputesPage({super.key});

  @override
  State<AdminDisputesPage> createState() => _AdminDisputesPageState();
}

class _AdminDisputesPageState extends State<AdminDisputesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDisputedContracts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AdminColors.primaryBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.balance_rounded,
                      color: AdminColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disputes',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'Contract disputes raised for admin review',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DateRangeFilterButton(
                    range: admin.disputesDateRange,
                    onChanged: admin.setDisputesDateRange,
                  ),
                ],
              ),
            ),
            Expanded(
              child: admin.isDisputesLoading && admin.disputedContracts.isEmpty
                  ? const AdminSkeletonList()
                  : admin.disputedContracts.isEmpty
                      ? const AdminEmptyState(
                          icon: Icons.balance_rounded,
                          title: 'No disputed contracts',
                          subtitle: 'Contracts raised for admin review will show up here.',
                          accent: AdminColors.primary,
                        )
                      : RefreshIndicator(
                          onRefresh: () => admin.loadDisputedContracts(),
                          color: AdminColors.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: admin.disputedContracts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) => AdminFadeIn(
                              index: i,
                              child: _DisputeCard(contract: admin.disputedContracts[i]),
                            ),
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _DisputeCard extends StatelessWidget {
  final Map<String, dynamic> contract;

  const _DisputeCard({required this.contract});

  @override
  Widget build(BuildContext context) {
    final contractId = contract['contract_id']?.toString() ?? '';
    final title = contract['contract_title'] as String? ?? 'Untitled Contract';
    final clientName = contract['client_name'] as String? ??
        contract['client_email'] as String? ??
        'Unknown Client';
    final freelancerName = contract['freelancer_name'] as String? ??
        contract['freelancer_email'] as String? ??
        'Unknown Freelancer';
    final reason = contract['dispute_reason'] as String?;
    final budget = (contract['agreed_budget'] as num?)?.toDouble() ?? 0;
    final currency = contract['budget_currency'] as String? ?? 'USD';
    final raisedAt = _fmtDate(contract['dispute_raised_at']?.toString());

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: AdminColors.redBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AdminColors.red.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.gavel_rounded,
                      size: 18,
                      color: AdminColors.red,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AdminColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$currency ${budget.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AdminColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const AdminBadge(label: 'Disputed', color: AdminColors.red),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _PartyChip(label: 'Client', name: clientName),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PartyChip(label: 'Freelancer', name: freelancerName),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DISPUTE REASON',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.faint,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (reason == null || reason.isEmpty)
                        ? 'No reason recorded.'
                        : reason,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AdminColors.body,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Text(
                'Raised $raisedAt',
                style: GoogleFonts.poppins(fontSize: 10, color: AdminColors.faint),
              ),
            ),
            if (contractId.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: AdminActionButton(
                        label: 'Approve',
                        icon: Icons.check_circle_rounded,
                        color: AdminColors.green,
                        style: AdminActionStyle.outlined,
                        onPressed: () => _showResolveDialog(
                          context,
                          contractId: contractId,
                          outcome: 'approve',
                          title: title,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AdminActionButton(
                        label: 'Revise',
                        icon: Icons.edit_calendar_rounded,
                        color: AdminColors.amber,
                        style: AdminActionStyle.outlined,
                        onPressed: () => _showResolveDialog(
                          context,
                          contractId: contractId,
                          outcome: 'revise',
                          title: title,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AdminActionButton(
                        label: 'Cancel',
                        icon: Icons.cancel_rounded,
                        color: AdminColors.red,
                        style: AdminActionStyle.outlined,
                        onPressed: () => _showResolveDialog(
                          context,
                          contractId: contractId,
                          outcome: 'cancel',
                          title: title,
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
    required String contractId,
    required String outcome,
    required String title,
  }) async {
    final noteCtrl = TextEditingController();
    final deadlineNotifier = ValueNotifier<DateTime?>(null);
    final labelMap = {
      'approve': 'Force-Complete',
      'cancel': 'Force-Cancel',
      'revise': 'Request Revision',
    };
    final colorMap = {
      'approve': AdminColors.green,
      'cancel': AdminColors.red,
      'revise': AdminColors.amber,
    };
    final iconMap = {
      'approve': Icons.check_circle_outline_rounded,
      'cancel': Icons.cancel_outlined,
      'revise': Icons.edit_calendar_outlined,
    };
    final descMap = {
      'approve': 'Marks the contract as completed, as if the client approved it.',
      'cancel': 'Cancels the contract. This cannot be undone.',
      'revise': 'Sends the latest submission back for revision with a new deadline.',
    };

    final confirmed = await showAdminConfirmDialog(
      context,
      title: '${labelMap[outcome]}?',
      message: '$title — ${descMap[outcome]}',
      icon: iconMap[outcome]!,
      confirmLabel: labelMap[outcome]!,
      confirmColor: colorMap[outcome]!,
      extra: _ResolveDisputeExtra(
        outcome: outcome,
        noteController: noteCtrl,
        deadlineNotifier: deadlineNotifier,
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final deadline = outcome == 'revise'
        ? (deadlineNotifier.value ?? DateTime.now().add(const Duration(days: 7)))
        : null;

    final ok = await context.read<AdminProvider>().arbitrateDispute(
          contractId,
          outcome: outcome,
          note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
          newDeadline: deadline == null
              ? null
              : '${deadline.year.toString().padLeft(4, '0')}-'
                  '${deadline.month.toString().padLeft(2, '0')}-'
                  '${deadline.day.toString().padLeft(2, '0')}',
        );

    if (context.mounted) {
      if (ok) {
        AppToast.success('Dispute resolved (${labelMap[outcome]}).');
      } else {
        AppToast.error('Failed to resolve dispute.');
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

class _ResolveDisputeExtra extends StatefulWidget {
  final String outcome;
  final TextEditingController noteController;
  final ValueNotifier<DateTime?> deadlineNotifier;

  const _ResolveDisputeExtra({
    required this.outcome,
    required this.noteController,
    required this.deadlineNotifier,
  });

  @override
  State<_ResolveDisputeExtra> createState() => _ResolveDisputeExtraState();
}

class _ResolveDisputeExtraState extends State<_ResolveDisputeExtra> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.outcome == 'revise') ...[
          Text(
            'New deadline',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AdminColors.body,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: widget.deadlineNotifier.value ??
                    DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => widget.deadlineNotifier.value = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AdminColors.surfaceSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AdminColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 14, color: AdminColors.muted),
                  const SizedBox(width: 8),
                  Text(
                    _fmt(widget.deadlineNotifier.value ??
                        DateTime.now().add(const Duration(days: 7))),
                    style: GoogleFonts.poppins(fontSize: 13, color: AdminColors.body),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          'Note (visible to both parties, optional)',
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.body),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.noteController,
          maxLines: 3,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Explain the decision...',
            hintStyle: GoogleFonts.poppins(fontSize: 12, color: AdminColors.faint),
            filled: true,
            fillColor: AdminColors.surfaceSoft,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AdminColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AdminColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AdminColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _PartyChip extends StatelessWidget {
  final String label;
  final String name;

  const _PartyChip({required this.label, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AdminColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: AdminColors.faint,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AdminColors.body,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
