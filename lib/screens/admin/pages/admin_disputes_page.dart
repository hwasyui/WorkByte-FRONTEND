import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';

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
        if (admin.isDisputesLoading && admin.disputedContracts.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
          );
        }

        if (admin.disputedContracts.isEmpty) {
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
                    Icons.balance_rounded,
                    size: 30,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'No disputed contracts',
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
          onRefresh: () => admin.loadDisputedContracts(),
          color: const Color(0xFF4F46E5),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: admin.disputedContracts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _DisputeCard(contract: admin.disputedContracts[i]),
          ),
        );
      },
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1F2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFECDD3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.gavel_rounded,
                    size: 18,
                    color: Color(0xFFE11D48),
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
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$currency ${budget.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFECDD3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Disputed',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE11D48),
                    ),
                  ),
                ),
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
                    color: const Color(0xFF9CA3AF),
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
                    color: const Color(0xFF374151),
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
              style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF9CA3AF)),
            ),
          ),
          if (contractId.isNotEmpty) ...[
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
                        contractId: contractId,
                        outcome: 'approve',
                        title: title,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: 'Revise',
                      icon: Icons.edit_calendar_rounded,
                      color: const Color(0xFFEA580C),
                      bgColor: const Color(0xFFFFEDD5),
                      onTap: () => _showResolveDialog(
                        context,
                        contractId: contractId,
                        outcome: 'revise',
                        title: title,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: 'Cancel',
                      icon: Icons.cancel_rounded,
                      color: const Color(0xFFDC2626),
                      bgColor: const Color(0xFFFFE4E6),
                      onTap: () => _showResolveDialog(
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
    );
  }

  Future<void> _showResolveDialog(
    BuildContext context, {
    required String contractId,
    required String outcome,
    required String title,
  }) async {
    final noteCtrl = TextEditingController();
    DateTime? newDeadline;
    final labelMap = {
      'approve': 'Force-Complete',
      'cancel': 'Force-Cancel',
      'revise': 'Request Revision',
    };
    final colorMap = {
      'approve': const Color(0xFF059669),
      'cancel': const Color(0xFFDC2626),
      'revise': const Color(0xFFEA580C),
    };
    final descMap = {
      'approve': 'Marks the contract as completed, as if the client approved it.',
      'cancel': 'Cancels the contract. This cannot be undone.',
      'revise': 'Sends the latest submission back for revision with a new deadline.',
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '${labelMap[outcome]}?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$title — ${descMap[outcome]}',
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 14),
              if (outcome == 'revise') ...[
                Text(
                  'New deadline',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => newDeadline = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF6B7280)),
                        const SizedBox(width: 8),
                        Text(
                          newDeadline == null
                              ? 'Select a date'
                              : '${newDeadline!.day}/${newDeadline!.month}/${newDeadline!.year}',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                'Note (visible to both parties, optional)',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Explain the decision...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorMap[outcome],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: (outcome == 'revise' && newDeadline == null)
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: Text(
                'Confirm',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok = await context.read<AdminProvider>().arbitrateDispute(
          contractId,
          outcome: outcome,
          note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
          newDeadline: newDeadline == null
              ? null
              : '${newDeadline!.year.toString().padLeft(4, '0')}-'
                  '${newDeadline!.month.toString().padLeft(2, '0')}-'
                  '${newDeadline!.day.toString().padLeft(2, '0')}',
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          ok ? 'Dispute resolved (${labelMap[outcome]}).' : 'Failed to resolve dispute.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: ok ? colorMap[outcome] : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
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

class _PartyChip extends StatelessWidget {
  final String label;
  final String name;

  const _PartyChip({required this.label, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
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
              color: const Color(0xFF9CA3AF),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
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
