import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/admin_provider.dart';
import '../../../widgets/admin/admin_empty_state.dart';
import '../../../widgets/admin/admin_fade_in.dart';
import '../../../widgets/admin/admin_loading.dart';
import '../../../widgets/admin/admin_badge.dart';
import '../../../widgets/admin/admin_reason_dialog.dart';
import '../../../widgets/admin/date_range_filter_button.dart';
import '../../../widgets/admin/admin_stat_card.dart';
import '../../../widgets/pagination_bar.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/file_viewer.dart';

class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.loadPaymentsOverview();
      admin.loadPendingPayments();
      admin.loadContractsCommissionList();
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: Color(0xFF059669),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payments',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            Text(
                              'Platform commission and payment proof verification',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DateRangeFilterButton(
                        range: admin.paymentsDateRange,
                        onChanged: admin.setPaymentsDateRange,
                        accentColor: const Color(0xFF059669),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, c) {
                      final narrow = c.maxWidth < 360;
                      return TabBar(
                        controller: _tab,
                        isScrollable: narrow,
                        tabAlignment: narrow ? TabAlignment.start : TabAlignment.fill,
                        labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
                        labelColor: const Color(0xFF059669),
                        unselectedLabelColor: const Color(0xFF6B7280),
                        indicatorColor: const Color(0xFF059669),
                        indicatorWeight: 2.5,
                        tabs: [
                          const Tab(text: 'Overview'),
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Verification Queue'),
                                if (admin.pendingPaymentsCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      admin.pendingPaymentsCount > 99
                                          ? '99+'
                                          : '${admin.pendingPaymentsCount}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _PaymentsOverviewTab(),
                  _VerificationQueueTab(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PaymentsOverviewTab extends StatelessWidget {
  const _PaymentsOverviewTab();

  String _money(num? v, String currency) {
    final amount = (v ?? 0).toDouble();
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final data = admin.paymentsOverview;
        final currency = (data['currency'] as String?) ?? 'USD';

        if (admin.isPaymentsOverviewLoading && data.isEmpty) {
          return const AdminLoadingIndicator();
        }

        return RefreshIndicator(
          color: const Color(0xFF059669),
          onRefresh: () => admin.loadPaymentsOverview(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth > 700;
                final cards = [
                  AdminStatCard(
                    title: 'Realized Commission',
                    value: _money(data['realized_commission'] as num?, currency),
                    icon: Icons.savings_rounded,
                    color: const Color(0xFF059669),
                    subtitle: 'Platform\'s 10% cut, completed contracts only',
                  ),
                  AdminStatCard(
                    title: 'Total GMV',
                    value: _money(data['gmv'] as num?, currency),
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFF4F46E5),
                    subtitle: 'Combined value of all contracts',
                  ),
                  AdminStatCard(
                    title: 'Awaiting Verification',
                    value: '${(data['pending_verification'] as num?)?.toInt() ?? 0}',
                    icon: Icons.hourglass_top_rounded,
                    color: const Color(0xFFD97706),
                    subtitle: 'Contracts waiting on your review',
                  ),
                  AdminStatCard(
                    title: 'Commission At Risk',
                    value: '${(data['commission_at_risk'] as num?)?.toInt() ?? 0}',
                    icon: Icons.report_problem_rounded,
                    color: const Color(0xFFDC2626),
                    subtitle: 'Freelancer confirmed, admin proof still missing',
                  ),
                ];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((data['commission_at_risk'] as num?)?.toInt() != null &&
                        ((data['commission_at_risk'] as num).toInt() > 0))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${(data['commission_at_risk'] as num).toInt()} contract(s) have a freelancer '
                                  'who already confirmed receiving their share, but the platform\'s own 10% '
                                  'proof still hasn\'t been verified. Check the Verification Queue - this is '
                                  'the signal that a client may be skipping the platform fee.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF7F1D1D),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    wide
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 16),
                                Expanded(child: cards[1]),
                              ],
                            ),
                          )
                        : Column(children: [cards[0], const SizedBox(height: 16), cards[1]]),
                    const SizedBox(height: 16),
                    wide
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: cards[2]),
                                const SizedBox(width: 16),
                                Expanded(child: cards[3]),
                              ],
                            ),
                          )
                        : Column(children: [cards[2], const SizedBox(height: 16), cards[3]]),
                    const SizedBox(height: 24),
                    const _ContractsCommissionSection(),
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

class _ContractsCommissionSection extends StatefulWidget {
  const _ContractsCommissionSection();

  @override
  State<_ContractsCommissionSection> createState() => _ContractsCommissionSectionState();
}

class _ContractsCommissionSectionState extends State<_ContractsCommissionSection> {
  int _page = 1;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF059669);
      case 'pending_payment':
      case 'payment_review':
        return const Color(0xFF0891B2);
      case 'payment_rejected':
      case 'disputed':
        return const Color(0xFFDC2626);
      case 'cancelled':
        return const Color(0xFF9CA3AF);
      default:
        return const Color(0xFF4F46E5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final items = admin.contractsCommissionList;
        final pagination = admin.contractsCommissionPagination;
        final totalPages = (pagination['total_pages'] as num?)?.toInt() ?? 1;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Per-Job Commission Breakdown',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'What you\'ll earn from each job - confirmed once a contract completes, '
                'estimated while it\'s still in progress.',
                style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onSubmitted: (v) {
                  setState(() => _page = 1);
                  admin.loadContractsCommissionList(page: 1, search: v);
                },
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by job title, client, or freelancer',
                  hintStyle: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              if (admin.isContractsCommissionLoading && items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: AdminLoadingIndicator()),
                )
              else if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: AdminEmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No contracts yet',
                    subtitle: 'Jobs with a signed contract will show up here with their commission breakdown.',
                    accent: Color(0xFF4F46E5),
                  ),
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < items.length; i++)
                      AdminFadeIn(
                        index: i,
                        child: _ContractCommissionRow(
                          item: items[i],
                          statusColor: _statusColor(items[i]['status'] as String? ?? ''),
                        ),
                      ),
                  ],
                ),
              if (totalPages > 1) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _page > 1
                          ? () {
                              setState(() => _page -= 1);
                              admin.loadContractsCommissionList(
                                page: _page,
                                search: _searchController.text,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Text('Page $_page of $totalPages', style: GoogleFonts.poppins(fontSize: 12)),
                    IconButton(
                      onPressed: _page < totalPages
                          ? () {
                              setState(() => _page += 1);
                              admin.loadContractsCommissionList(
                                page: _page,
                                search: _searchController.text,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ContractCommissionRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color statusColor;

  const _ContractCommissionRow({required this.item, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final currency = (item['budget_currency'] as String?) ?? 'USD';
    final budget = (item['agreed_budget'] as num?)?.toDouble() ?? 0;
    final rate = (item['commission_rate'] as num?)?.toDouble() ?? 0.10;
    final lockedCommission = (item['commission_amount'] as num?)?.toDouble();
    final isConfirmed = lockedCommission != null;
    final commission = lockedCommission ?? (budget * rate);
    final status = (item['status'] as String?) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (item['contract_title'] as String?) ?? 'Untitled contract',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${item['client_name'] ?? 'Unknown client'} → ${item['freelancer_name'] ?? 'Unknown freelancer'}',
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF6B7280)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.replaceAll('_', ' '),
                    style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currency ${budget.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 3),
              Text(
                '$currency ${commission.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF4F46E5)),
              ),
              Text(
                isConfirmed ? 'confirmed' : 'estimated',
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: isConfirmed ? const Color(0xFF059669) : const Color(0xFFD97706),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerificationQueueTab extends StatefulWidget {
  const _VerificationQueueTab();

  @override
  State<_VerificationQueueTab> createState() => _VerificationQueueTabState();
}

class _VerificationQueueTabState extends State<_VerificationQueueTab> {
  int _page = 1;

  Future<void> _viewProof(BuildContext context, Map<String, dynamic> item) async {
    final url = item['file_url'] as String?;
    if (url == null || url.isEmpty) {
      AppToast.error('No file attached to this proof.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FileViewerScreen(
          filePath: url,
          fileName: '${item['payee']}_payment_proof',
        ),
      ),
    );
  }

  Future<void> _verify(BuildContext context, Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => AlertDialog(
        title: const Text('Verify this payment proof?'),
        content: Text(
          'This confirms the ${item['payee']}\'s share (${item['budget_currency'] ?? 'USD'} '
          '${item['amount']}) was received. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Verify')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final admin = context.read<AdminProvider>();
    final outcome = await admin.verifyPayment(item['proof_id'] as String);
    if (outcome.success) {
      AppToast.success('Payment proof verified.');
    } else {
      AppToast.error(outcome.errorMessage ?? 'Failed to verify payment proof.');
    }
  }

  Future<void> _reject(BuildContext context, Map<String, dynamic> item) async {
    final admin = context.read<AdminProvider>();
    final outcome = await showAdminReasonDialog(
      context,
      title: 'Reject payment proof',
      submitLabel: 'Reject',
      accentColor: const Color(0xFFDC2626),
      icon: Icons.close_rounded,
      warningText: 'The uploader will be notified and asked to re-upload a valid proof.',
      hintText: 'Why is this proof being rejected? (e.g. amount mismatch, unreadable file)',
      onSubmit: (reason) => admin.rejectPayment(item['proof_id'] as String, reason),
    );
    if (outcome != null && outcome.success) {
      AppToast.success('Payment proof rejected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final items = admin.pendingPayments;
        final pagination = admin.paymentsPagination;
        final totalPages = (pagination['total_pages'] as num?)?.toInt() ?? 1;

        Widget body;
        if (admin.isPendingPaymentsLoading && items.isEmpty) {
          body = const AdminLoadingIndicator();
        } else if (items.isEmpty) {
          body = const AdminEmptyState(
            icon: Icons.task_alt_rounded,
            title: 'Nothing to verify',
            subtitle: 'No payment proofs are waiting on you right now.',
            accent: Color(0xFF059669),
          );
        } else {
          body = RefreshIndicator(
            color: const Color(0xFF059669),
            onRefresh: () => admin.loadPendingPayments(page: _page),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = items[i];
                final isAdminPayee = item['payee'] == 'admin';
                return AdminFadeIn(
                  index: i,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                (item['contract_title'] as String?) ?? 'Untitled contract',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AdminBadge(
                              label: isAdminPayee ? "Platform's 10%" : "Freelancer's share",
                              color: isAdminPayee ? const Color(0xFF059669) : const Color(0xFF4F46E5),
                            ),
                          ],
                        ),
                        if ((item['milestone_title'] as String?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Milestone ${item['milestone_sequence_order'] ?? '?'} · ${item['milestone_title']}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4F46E5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '${item['budget_currency'] ?? 'USD'} ${item['amount']} platform fee'
                          '${(item['reference_number'] as String?)?.isNotEmpty == true ? ' · Ref: ${item['reference_number']}' : ''}',
                          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => _viewProof(context, item),
                              icon: const Icon(Icons.visibility_rounded, size: 16),
                              label: const Text('View proof'),
                              style: TextButton.styleFrom(foregroundColor: const Color(0xFF4F46E5)),
                            ),
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () => _reject(context, item),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(color: Color(0xFFFCA5A5)),
                              ),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => _verify(context, item),
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                              child: const Text('Verify'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }

        return Column(
          children: [
            Expanded(child: body),
            if (totalPages > 1)
              PaginationBar(
                currentPage: _page,
                totalPages: totalPages,
                onPrev: _page > 1
                    ? () {
                        setState(() => _page -= 1);
                        admin.loadPendingPayments(page: _page);
                      }
                    : null,
                onNext: _page < totalPages
                    ? () {
                        setState(() => _page += 1);
                        admin.loadPendingPayments(page: _page);
                      }
                    : null,
              ),
          ],
        );
      },
    );
  }
}
