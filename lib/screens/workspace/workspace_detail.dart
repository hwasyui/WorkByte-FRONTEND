import 'dart:convert';
import 'dart:io';

import 'package:workbyte_app/models/dm_model.dart';
import 'package:workbyte_app/providers/dm_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/contract_model.dart';
import '../../models/contract_submission_model.dart';
import '../../models/proposal_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contract_submission_provider.dart';
import '../../providers/contract_provider.dart';
import '../../services/proposal_service.dart';
import '../reviews/review_form.dart';
import '../reviews/client_review_form.dart';
import '../dm/dm_chat_screen.dart';
import '../contract/generate_contract_screen.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/harmful_block_dialog.dart';

class WorkspaceDetailScreen extends StatefulWidget {
  final ContractModel contract;
  final String viewerRole; // 'client' | 'freelancer'

  const WorkspaceDetailScreen({
    super.key,
    required this.contract,
    required this.viewerRole,
  });

  @override
  State<WorkspaceDetailScreen> createState() => _WorkspaceDetailScreenState();
}

class _WorkspaceDetailScreenState extends State<WorkspaceDetailScreen> {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  late ContractModel _contract;
  bool _isActioning = false;

  ProposalModel? _proposalDetail;
  bool _isLoadingProposal = false;
  final ProposalService _proposalService = ProposalService();

  static const int _autoApproveDays = 7;

  @override
  void initState() {
    super.initState();
    _contract = widget.contract;
    _fetchProposalDetail();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSubmissions();
      _maybeShowContractIncompletePrompt();
    });
  }

  bool get _isClient => widget.viewerRole == 'client';
  bool get _isFreelancer => widget.viewerRole == 'freelancer';

  bool get _hasContractPdf =>
      (_contract.contractPdfUrl ?? '').trim().isNotEmpty;

  bool get _isOverdue {
    const activeStatuses = {'active', 'under_review', 'revision_requested'};
    if (!activeStatuses.contains(_contract.status)) return false;
    final endDate = _contract.endDate;
    if (endDate == null) return false;
    final parsed = DateTime.tryParse(endDate);
    if (parsed == null) return false;
    final today = DateTime.now();
    final endDay = DateTime(parsed.year, parsed.month, parsed.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return endDay.isBefore(todayDay);
  }

  bool get _canRaiseDispute =>
      _contract.status == 'under_review' ||
      _contract.status == 'revision_requested';

  Future<void> _fetchProposalDetail() async {
    if (_contract.proposalId == null) return;
    setState(() => _isLoadingProposal = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final proposal = await _proposalService.getProposalById(
        token,
        _contract.proposalId!,
      );
      if (mounted) {
        setState(() => _proposalDetail = proposal);
      }
    } catch (e) {
      debugPrint('Failed to fetch proposal detail: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingProposal = false);
      }
    }
  }

  Future<void> _fetchSubmissions() async {
    try {
      final token = context.read<AuthProvider>().token!;
      await context.read<ContractSubmissionProvider>().fetchSubmissions(
        token: token,
        contractId: _contract.contractId,
      );
    } catch (e) {
      debugPrint('Failed to fetch submissions: $e');
    }
  }

  /// Manual refresh - the day-3/6/7 reminder/auto-approve sweep
  /// (contract_autoapprove_worker.py) can change contract/submission status
  /// in the background at any time with no live push to this screen, so
  /// there's no other way to see that update without navigating away and back.
  /// Wired to the app bar's refresh button - the single refresh path for this
  /// screen (previously duplicated by a pull-to-refresh that called an
  /// overlapping, since-removed set of helpers).
  Future<void> _refreshWorkspace() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await context.read<ContractProvider>().fetchContractById(
      token,
      _contract.contractId,
    );
    if (mounted) {
      final latest = context.read<ContractProvider>().currentContract;
      if (latest != null && latest.contractId == _contract.contractId) {
        setState(() => _contract = latest);
      }
    }
    await Future.wait([_fetchProposalDetail(), _fetchSubmissions()]);
  }

  void _maybeShowContractIncompletePrompt() {
    if (_hasContractPdf) return;
    // No point nagging once the contract is done or dead
    if (_contract.status == 'completed' || _contract.status == 'cancelled') {
      return;
    }
    if (!mounted) return;
    _showContractIncompleteSheet();
  }

  void _goToGenerateContract() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenerateContractScreen(
          contractId: _contract.contractId,
          initialContract: _contract,
        ),
      ),
    ).then((_) => _refreshWorkspace());
  }

  void _showContractIncompleteSheet() {
    showModalBottomSheet(
      context: context,
      // Client should have to make a decision; freelancer can just dismiss.
      isDismissible: _isFreelancer,
      enableDrag: _isFreelancer,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _buildContractIncompleteSheetContent(ctx),
    );
  }

  Widget _buildContractIncompleteSheetContent(BuildContext ctx) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        28,
        24,
        MediaQuery.of(ctx).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isClient
                  ? Icons.description_outlined
                  : Icons.hourglass_top_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isClient
                ? 'Finish setting up the contract'
                : 'Contract in progress',
            style: AppText.h2,
          ),
          const SizedBox(height: 6),
          Text(
            _isClient
                ? 'You need to generate and send the contract PDF before work can begin on this project.'
                : 'The client is still finalizing the contract terms. You\'ll be notified as soon as it\'s ready to work on.',
            style: AppText.body.copyWith(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          if (_isClient)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _goToGenerateContract();
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  'Complete Contract',
                  style: AppText.bodySemiBold.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text('Got it', style: AppText.bodySemiBold),
              ),
            ),
        ],
      ),
    );
  }

  Future<bool> _updateStatus(String status, {String? note}) async {
    try {
      final token = context.read<AuthProvider>().token!;
      final body = <String, dynamic>{'status': status};
      if (note != null && note.trim().isNotEmpty) {
        body['revision_note'] = note.trim();
      }

      final res = await http.put(
        Uri.parse('$_baseUrl/contracts/${_contract.contractId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final updated = data['details'] ?? data['data'] ?? data;
        if (mounted) {
          setState(() {
            _contract = ContractModel.fromJson(updated as Map<String, dynamic>);
          });
        }
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _submitWork(List<File> files, String note) async {
    setState(() => _isActioning = true);

    try {
      final token = context.read<AuthProvider>().token!;
      final provider = context.read<ContractSubmissionProvider>();

      final submissionSuccess = await provider.createSubmission(
        token: token,
        contractId: _contract.contractId,
        files: files,
        note: note,
      );

      if (!mounted) return false;

      if (!submissionSuccess) {
        showErrorFeedback(
          context,
          message: provider.errorMessage ?? 'Failed to submit work.',
        );
        return false;
      }

      final contractSuccess = await _updateStatus('under_review');

      await _fetchSubmissions();

      if (!mounted) return true;

      if (contractSuccess) {
        _showSnack('Work submitted successfully!', isError: false);
      } else {
        _showSnack(
          'Work submitted, but failed to update contract status.',
          isError: true,
        );
      }
      return true;
    } catch (e) {
      if (mounted) _showSnack('Something went wrong.', isError: true);
      return false;
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  Future<bool> _requestRevision(String note) async {
    setState(() => _isActioning = true);

    try {
      final token = context.read<AuthProvider>().token!;
      final provider = context.read<ContractSubmissionProvider>();

      final success = await provider.requestRevisionForLatestSubmission(
        token: token,
        contractId: _contract.contractId,
        note: note, // ← pass note
      );

      if (!mounted) return false;

      if (!success) {
        showErrorFeedback(
          context,
          message: provider.errorMessage ?? 'Failed to request revision.',
        );
        return false;
      }

      await _fetchSubmissions();

      if (!mounted) return true;
      _showSnack('Revision request sent to freelancer', isError: false);
      return true;
    } catch (e) {
      if (mounted) _showSnack('Something went wrong.', isError: true);
      return false;
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  Future<void> _approveLatestSubmission() async {
    setState(() => _isActioning = true);

    try {
      final token = context.read<AuthProvider>().token!;
      final provider = context.read<ContractSubmissionProvider>();

      final submissionSuccess = await provider.approveLatestSubmission(
        token: token,
        contractId: _contract.contractId,
      );

      if (!mounted) return;

      if (!submissionSuccess) {
        _showSnack(
          provider.errorMessage ?? 'Failed to approve submission.',
          isError: true,
        );
        return;
      }

      final contractSuccess = await _updateStatus('completed');

      await _fetchSubmissions();

      if (!mounted) return;

      if (contractSuccess) {
        _showSnack('Contract marked as completed!', isError: false);
        // ── Navigate to review form ───────────────────────────────
        await Future.delayed(
          const Duration(milliseconds: 600),
        ); // let snack show briefly
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewFormScreen(
              contractId: _contract.contractId,
              freelancerName: _contract.freelancerName ?? 'Freelancer',
              projectTitle: _contract.contractTitle,
            ),
          ),
        );
      } else {
        _showSnack(
          'Submission approved, but failed to update contract status.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnack('Something went wrong.', isError: true);
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final token = context.read<AuthProvider>().token;
    await openDocumentFromUrl(
      context,
      url,
      token: token,
      onRefreshToken: () async {
        final ok = await context.read<AuthProvider>().tryRefresh();
        return ok ? context.read<AuthProvider>().token : null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final submissionProvider = context.watch<ContractSubmissionProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _buildStatusBanner(),
          const SizedBox(height: 16),
          if (_isOverdue) ...[
            _buildOverdueBanner(),
            const SizedBox(height: 16),
          ],
          if (_isFreelancer && _contract.status == 'under_review')
            _buildAutoApproveCountdown(submissionProvider),
          _buildContractInfo(),
          const SizedBox(height: 16),
          _buildPartiesCard(),
          const SizedBox(height: 16),
          _buildProposalSummary(),
          const SizedBox(height: 16),
          _buildSubmittedWorkSection(submissionProvider),
          const SizedBox(height: 16),
          _buildMessagesButton(),
          if (_canRaiseDispute) ...[
            const SizedBox(height: 16),
            _buildDisputeSection(),
          ],
          const SizedBox(height: 16),
          if (_isFreelancer && _contract.status == 'revision_requested')
            _buildRevisionNote(),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(submissionProvider),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: Color(0xFF333333),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Working Space', style: AppText.h3),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.refresh_rounded,
            size: 22,
            color: Color(0xFF333333),
          ),
          tooltip: 'Refresh',
          onPressed: _refreshWorkspace,
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    final color = _statusColor(_contract.status);
    final label = _statusLabel(_contract.status);
    final hint = _statusHint(_contract.status, widget.viewerRole);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.captionSemiBold.copyWith(color: color),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: AppText.caption.copyWith(
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_busy_rounded,
            color: Color(0xFFC62828),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Past Deadline',
                  style: AppText.captionSemiBold.copyWith(
                    color: const Color(0xFFC62828),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This contract passed its end date (${_formatDate(_contract.endDate)}) '
                  'and the work isn\'t marked complete yet. Coordinate with the other '
                  'party or raise a dispute if you can\'t agree.',
                  style: AppText.caption.copyWith(
                    color: const Color(0xFFC62828).withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoApproveCountdown(ContractSubmissionProvider provider) {
    final latest = provider.latestSubmission;
    if (latest == null ||
        latest.status != 'submitted' ||
        latest.submittedAt == null) {
      return const SizedBox.shrink();
    }
    final daysElapsed = DateTime.now().difference(latest.submittedAt!).inDays;
    final daysRemaining = _autoApproveDays - daysElapsed;
    if (daysRemaining > 3) {
      // Not close enough to auto-approve yet - no need to nag the freelancer.
      return const SizedBox.shrink();
    }
    final isUrgent = daysRemaining <= 1;
    final color = isUrgent ? const Color(0xFFC62828) : const Color(0xFFEF6C00);
    final bg = isUrgent ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.timer_outlined, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    daysRemaining <= 0
                        ? 'Auto-Approving Soon'
                        : 'Auto-Approves in $daysRemaining day${daysRemaining == 1 ? '' : 's'}',
                    style: AppText.captionSemiBold.copyWith(color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'The client hasn\'t reviewed your submission yet. If they stay silent, '
                    'this contract will be automatically approved and marked complete.',
                    style: AppText.caption.copyWith(
                      color: color.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractInfo() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_contract.contractTitle, style: AppText.h2),
          const SizedBox(height: 8),
          if (_contract.roleTitle.isNotEmpty) ...[
            _buildTag(_contract.roleTitle),
            const SizedBox(height: 12),
          ],
          _buildInfoRow(
            Icons.attach_money_rounded,
            'Agreed Budget',
            '${_contract.budgetCurrency} ${_contract.agreedBudget.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Start Date',
            _formatDate(_contract.startDate),
          ),
          if (_contract.endDate != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.event_outlined,
              'End Date',
              _formatDate(_contract.endDate),
            ),
          ],
          if (_contract.agreedDuration != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.timelapse_outlined,
              'Duration',
              _contract.agreedDuration!,
            ),
          ],
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.payment_outlined,
            'Payment',
            _contract.paymentStructure == 'milestone_based'
                ? 'Milestone Based'
                : 'Full Payment',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.account_balance_wallet_outlined,
            'Total Paid',
            '${_contract.budgetCurrency} ${(_contract.totalPaid ?? 0).toStringAsFixed(0)} '
                'of ${_contract.agreedBudget.toStringAsFixed(0)}',
          ),
          if (_isClient && _contract.status != 'cancelled') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: _showRecordPaymentDialog,
                icon: const Icon(
                  Icons.add_card_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Record a Payment',
                  style: AppText.captionSemiBold.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartiesCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Parties', style: AppText.h3),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildPartyChip('Client', Icons.business_outlined, _isClient),
              const SizedBox(width: 16),
              const Icon(
                Icons.swap_horiz_rounded,
                color: Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 16),
              _buildPartyChip(
                'Freelancer',
                Icons.person_outline_rounded,
                _isFreelancer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartyChip(String label, IconData icon, bool isYou) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isYou
              ? AppColors.primary.withOpacity(0.08)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isYou
                ? AppColors.primary.withOpacity(0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isYou ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppText.captionSemiBold.copyWith(
                color: isYou ? AppColors.primary : Colors.grey.shade600,
              ),
            ),
            if (isYou)
              Text(
                'You',
                style: AppText.overline.copyWith(
                  color: AppColors.primary.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProposalSummary() {
    return Column(
      children: [
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.description_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text('Contract Document', style: AppText.h3),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _buildContractDocumentTile(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildExpandable(
          title: 'Original Proposal',
          icon: Icons.article_outlined,
          child: _isLoadingProposal
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : _proposalDetail == null
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Proposal details unavailable.',
                    style: AppText.caption.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            Icons.attach_money_rounded,
                            'Bid',
                            '${_contract.budgetCurrency} ${_proposalDetail!.proposedBudget.toStringAsFixed(0)}',
                          ),
                        ),
                        if (_proposalDetail!.proposedDuration != null)
                          Expanded(
                            child: _buildInfoRow(
                              Icons.timelapse_outlined,
                              'Timeline',
                              _proposalDetail!.proposedDuration!,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_proposalDetail!.submittedAt != null)
                      _buildInfoRow(
                        Icons.calendar_today_outlined,
                        'Submitted',
                        _formatDate(_proposalDetail!.submittedAt),
                      ),
                    const SizedBox(height: 12),
                    if (_proposalDetail!.isAiGenerated)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: Colors.purple.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'AI Generated Proposal',
                              style: AppText.overline.copyWith(
                                color: Colors.purple.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      'Cover Letter',
                      style: AppText.captionSemiBold.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _proposalDetail!.coverLetter,
                      style: AppText.body.copyWith(
                        color: const Color(0xFF444444),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildContractDocumentTile() {
    if (_hasContractPdf) {
      return GestureDetector(
        onTap: () async {
          try {
            final auth = context.read<AuthProvider>();
            final contractProvider = context.read<ContractProvider>();
            final token = auth.token;

            if (token == null || token.isEmpty) {
              _showSnack('Missing auth token.', isError: true);
              return;
            }

            final pdfUrl = await contractProvider.fetchPdfUrl(
              token,
              _contract.contractId,
            );

            debugPrint('signedPdfUrl = $pdfUrl');

            final uri = Uri.tryParse(pdfUrl);
            if (uri == null ||
                !(uri.scheme == 'http' || uri.scheme == 'https')) {
              _showSnack('Invalid contract URL.', isError: true);
              return;
            }

            if (!mounted) return;
            await openDocumentFromUrl(
              context,
              pdfUrl,
              token: token,
              fileName: 'contract_${_contract.contractId}.pdf',
              onRefreshToken: () async {
                final ok = await context.read<AuthProvider>().tryRefresh();
                return ok ? context.read<AuthProvider>().token : null;
              },
            );
          } catch (e) {
            debugPrint('open contract pdf error: $e');
            _showSnack('Could not open contract file.', isError: true);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View Contract PDF',
                      style: AppText.bodySemiBold.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Tap to open in document viewer',
                      style: AppText.caption.copyWith(
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                color: AppColors.primary.withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            color: Color(0xFFFF9800),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contract not finalized',
                  style: AppText.captionSemiBold.copyWith(
                    color: const Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isClient
                      ? 'Generate and send the contract PDF to get started.'
                      : 'Waiting for the client to finalize the contract.',
                  style: AppText.caption.copyWith(
                    color: const Color(0xFF795548),
                  ),
                ),
                if (_isClient) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _goToGenerateContract,
                    child: Text(
                      'Complete Contract →',
                      style: AppText.captionSemiBold.copyWith(
                        color: const Color(0xFFFF9800),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedWorkSection(ContractSubmissionProvider provider) {
    return _buildExpandable(
      title: 'Submitted Work',
      icon: Icons.upload_file_rounded,
      child: provider.isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            )
          : provider.submissions.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _isFreelancer
                    ? 'You have not submitted any work yet.'
                    : 'No work has been submitted yet.',
                style: AppText.caption.copyWith(color: Colors.grey.shade500),
              ),
            )
          : Column(
              children: provider.submissions
                  .map((submission) => _buildSubmissionCard(submission))
                  .toList(),
            ),
    );
  }

  Widget _buildSubmissionCard(ContractSubmissionModel submission) {
    final provider = context.read<ContractSubmissionProvider>();
    final latest = provider.latestSubmission;
    final isLatest = latest?.submissionId == submission.submissionId;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLatest ? const Color(0xFFF7FCFC) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLatest
              ? _submissionStatusColor(submission.status).withOpacity(0.35)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildMiniStatusChip(
                isLatest
                    ? 'Latest • ${_submissionStatusLabel(submission.status)}'
                    : _submissionStatusLabel(submission.status),
                color: _submissionStatusColor(submission.status),
              ),
              const Spacer(),
              Text(
                _formatDateTime(submission.submittedAt),
                style: AppText.overline.copyWith(color: Colors.grey.shade500),
              ),
            ],
          ),
          if (submission.note != null &&
              submission.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Note',
              style: AppText.captionSemiBold.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              submission.note!,
              style: AppText.caption.copyWith(
                color: const Color(0xFF444444),
                height: 1.5,
              ),
            ),
          ],
          if (submission.files.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Files',
              style: AppText.captionSemiBold.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            ...submission.files.map(_buildSubmissionFileTile),
          ],
          if (submission.revisionNote != null &&
              submission.revisionNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF9800).withOpacity(0.3),
                ),
              ),
              child: Text(
                submission.revisionNote!,
                style: AppText.caption.copyWith(color: const Color(0xFF795548)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmissionFileTile(ContractSubmissionFileModel file) {
    return InkWell(
      onTap: () => _openUrl(file.fileUrl),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(_fileIcon(file.fileName), color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.captionSemiBold.copyWith(
                      color: const Color(0xFF333333),
                    ),
                  ),
                  if (file.fileSizeBytes != null)
                    Text(
                      _formatFileSize(file.fileSizeBytes!),
                      style: AppText.overline.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatusChip(String label, {Color? color}) {
    final chipColor = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: AppText.overline.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMessagesButton() {
    return GestureDetector(
      onTap: () async {
        final auth = context.read<AuthProvider>();
        final dmProvider = context.read<DMProvider>();
        final token = auth.token;
        final currentUserId = auth.currentUser?.userId ?? '';

        if (currentUserId.isEmpty || token == null) {
          _showSnack('Unable to open messages. User not found.', isError: true);
          return;
        }

        await dmProvider.fetchThreads(token);

        final thread = dmProvider.threads.cast<DMThreadModel?>().firstWhere(
          (t) => t?.contractId == _contract.contractId,
          orElse: () => null,
        );

        if (thread == null) {
          _showSnack('Chat thread not found.', isError: true);
          return;
        }

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DMChatScreen(thread: thread)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Messages', style: AppText.bodySemiBold),
                  Text(
                    'Chat with the other party',
                    style: AppText.caption.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildDisputeSection() {
    return GestureDetector(
      onTap: _showRaiseDisputeDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gavel_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Raise a Dispute',
                    style: AppText.bodySemiBold.copyWith(
                      color: Colors.redAccent,
                    ),
                  ),
                  Text(
                    'Can\'t resolve this with the other party? Ask an admin to step in.',
                    style: AppText.caption.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showRaiseDisputeDialog() {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Raise a Dispute', style: AppText.h2),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'An admin will review this contract and decide the outcome. '
                  'Explain what went wrong.',
                  style: AppText.caption.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonCtrl,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Describe the issue in detail...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 20) {
                      return 'Please provide at least 20 characters';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: AppText.bodySemiBold.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => isSubmitting = true);
                      final token = context.read<AuthProvider>().token!;
                      final success = await context
                          .read<ContractProvider>()
                          .raiseDispute(
                            token,
                            _contract.contractId,
                            reasonCtrl.text.trim(),
                          );
                      if (!mounted) return;
                      if (success) {
                        Navigator.pop(ctx);
                        setState(
                          () => _contract = _contract.copyWith(
                            status: 'disputed',
                          ),
                        );
                        _showSnack(
                          'Dispute raised. An admin will review it.',
                          isError: false,
                        );
                      } else {
                        setDialogState(() => isSubmitting = false);
                        showErrorFeedback(
                          context,
                          message:
                              context.read<ContractProvider>().error ??
                              'Failed to raise dispute.',
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Submit',
                      style: AppText.bodySemiBold.copyWith(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevisionNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFFF9800),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revision Requested',
                  style: AppText.captionSemiBold.copyWith(
                    color: const Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The client has requested changes. Please review the feedback in Messages and resubmit your work.',
                  style: AppText.caption.copyWith(
                    color: const Color(0xFF795548),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(ContractSubmissionProvider provider) {
    final status = _contract.status;

    if (status == 'completed' || status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'completed'
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: status == 'completed'
                      ? const Color(0xFF4CAF50)
                      : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  status == 'completed'
                      ? 'Contract Completed'
                      : 'Contract Cancelled',
                  style: AppText.bodySemiBold.copyWith(
                    color: status == 'completed'
                        ? const Color(0xFF4CAF50)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            // Freelancers don't take the action that completes a contract
            // (the client approves, or auto-approve/dispute-arbitration does),
            // so unlike the client's immediate post-approve navigation to
            // ReviewFormScreen, this button is how a freelancer reaches their
            // "rate this client" form whenever they next open the workspace.
            if (_isFreelancer && status == 'completed') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClientReviewFormScreen(
                        contractId: _contract.contractId,
                        clientName: _contract.clientName ?? 'Client',
                        projectTitle: _contract.contractTitle,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.rate_review_outlined, size: 16),
                  label: Text(
                    'Rate This Client',
                    style: AppText.bodySemiBold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            // Symmetric counterpart for the client: they get auto-navigated to
            // ReviewFormScreen right after approving (_approveLatestSubmission),
            // but that's a one-shot push - if they back out without submitting,
            // this is the only way back into that form.
            if (_isClient && status == 'completed') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewFormScreen(
                        contractId: _contract.contractId,
                        freelancerName: _contract.freelancerName ?? 'Freelancer',
                        projectTitle: _contract.contractTitle,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.rate_review_outlined, size: 16),
                  label: Text(
                    'Rate This Freelancer',
                    style: AppText.bodySemiBold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_isActioning || provider.isUploading) {
      return Container(
        height: 80,
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    // client + active needs more height for 2 stacked widgets
    final isClientActive = _isClient && status == 'active';
    // freelancer sees an extra "contract pending" banner in place of the button
    final isFreelancerBlockedByContract =
        _isFreelancer &&
        !_hasContractPdf &&
        (status == 'active' || status == 'revision_requested');

    return Container(
      height: isClientActive || isFreelancerBlockedByContract ? 140 : 80,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Center(child: _buildActionButtons(status)),
    );
  }

  Widget _buildActionButtons(String status) {
    if (_isFreelancer) {
      if (status == 'active' || status == 'revision_requested') {
        if (!_hasContractPdf) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.hourglass_top_rounded,
                      color: Color(0xFFFF9800),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Waiting for the client to finalize the contract before you can submit work.',
                        textAlign: TextAlign.center,
                        style: AppText.captionSemiBold.copyWith(
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _showSubmitWorkSheet,
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: Text(
              status == 'revision_requested' ? 'Resubmit Work' : 'Submit Work',
              style: AppText.bodySemiBold.copyWith(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        );
      }

      if (status == 'under_review') {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                color: Color(0xFF2196F3),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Waiting for client review...',
                style: AppText.bodySemiBold.copyWith(
                  color: const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
        );
      }
    }

    if (_isClient) {
      if (status == 'active') {
        return Column(
          children: [
            // existing "waiting" banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Waiting for freelancer to submit...',
                    style: AppText.bodySemiBold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // ✅ New cancel button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _showCancelDialog,
                icon: const Icon(
                  Icons.cancel_outlined,
                  size: 16,
                  color: Colors.redAccent,
                ),
                label: Text(
                  'Cancel Contract',
                  style: AppText.bodySemiBold.copyWith(color: Colors.redAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        );
      }

      if (status == 'under_review') {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showRevisionSheet,
                icon: const Icon(
                  Icons.replay_rounded,
                  size: 16,
                  color: Color(0xFFFF9800),
                ),
                label: Text(
                  'Revision',
                  style: AppText.bodySemiBold.copyWith(
                    color: const Color(0xFFFF9800),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF9800)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _showApproveDialog,
                icon: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  'Approve',
                  style: AppText.bodySemiBold.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        );
      }
    }

    return const SizedBox.shrink();
  }

  void _showSubmitWorkSheet() {
    final noteController = TextEditingController();
    List<PlatformFile> pickedFiles = [];
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Submit Work', style: AppText.h2),
              const SizedBox(height: 4),
              Text(
                'Upload your deliverables and add a note for the client.',
                style: AppText.caption.copyWith(color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                    type: FileType.custom,
                    allowedExtensions: [
                      'pdf',
                      'doc',
                      'docx',
                      'png',
                      'jpg',
                      'jpeg',
                      'zip',
                    ],
                  );
                  if (result != null) {
                    setModal(() {
                      final existingPaths = pickedFiles
                          .map((e) => e.path)
                          .toSet();
                      final newFiles = result.files.where(
                        (f) => !existingPaths.contains(f.path),
                      );
                      pickedFiles = [...pickedFiles, ...newFiles];
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.upload_file_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pickedFiles.isEmpty
                            ? 'Tap to add files'
                            : '${pickedFiles.length} file(s) selected',
                        style: AppText.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (pickedFiles.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: pickedFiles
                      .map(
                        (f) => Chip(
                          label: Text(
                            f.name,
                            style: AppText.caption.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          backgroundColor: AppColors.secondary,
                          side: BorderSide.none,
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () =>
                              setModal(() => pickedFiles.remove(f)),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                enabled: !isSubmitting,
                maxLines: 3,
                style: AppText.body,
                decoration: InputDecoration(
                  hintText: 'Add a note for the client (optional)...',
                  hintStyle: AppText.caption.copyWith(
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (pickedFiles.isEmpty || isSubmitting)
                      ? null
                      : () async {
                          setModal(() => isSubmitting = true);
                          final dartFiles = pickedFiles
                              .where((f) => f.path != null)
                              .map((f) => File(f.path!))
                              .toList();
                          final success = await _submitWork(
                            dartFiles,
                            noteController.text.trim(),
                          );
                          if (!mounted) return;
                          if (success) {
                            Navigator.pop(ctx);
                          } else {
                            setModal(() => isSubmitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Submit',
                          style: AppText.bodySemiBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRevisionSheet() {
    final noteController = TextEditingController();
    bool isSubmitting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Request Revision', style: AppText.h2),
              const SizedBox(height: 4),
              Text(
                'Describe what changes you need from the freelancer.',
                style: AppText.caption.copyWith(color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: noteController,
                enabled: !isSubmitting,
                maxLines: 4,
                style: AppText.body,
                decoration: InputDecoration(
                  hintText: 'e.g. Please update the color scheme and add...',
                  hintStyle: AppText.caption.copyWith(
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF9800)),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (noteController.text.trim().isEmpty) return;
                          setModal(() => isSubmitting = true);
                          final success = await _requestRevision(
                            noteController.text.trim(),
                          );
                          if (!mounted) return;
                          if (success) {
                            Navigator.pop(ctx);
                          } else {
                            setModal(() => isSubmitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    disabledBackgroundColor: const Color(
                      0xFFFF9800,
                    ).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Send Revision Request',
                          style: AppText.bodySemiBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApproveDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Approve Work', style: AppText.h2),
        content: Text(
          'Are you sure you want to approve this submission? This will mark the contract as completed.',
          style: AppText.body.copyWith(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppText.bodySemiBold.copyWith(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _approveLatestSubmission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Approve',
              style: AppText.bodySemiBold.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildExpandable({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(icon, color: AppColors.primary, size: 20),
          title: Text(title, style: AppText.h3),
          children: [child],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppText.caption.copyWith(color: Colors.grey.shade500),
        ),
        Expanded(
          child: Text(
            value,
            style: AppText.captionSemiBold.copyWith(
              color: const Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.primary;
      case 'under_review':
        return const Color(0xFF2196F3);
      case 'revision_requested':
        return const Color(0xFFFF9800);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return Colors.grey;
      case 'disputed':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'under_review':
        return 'Under Review';
      case 'revision_requested':
        return 'Revision Requested';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'disputed':
        return 'Disputed';
      default:
        return status;
    }
  }

  String? _statusHint(String status, String role) {
    if (role == 'freelancer') {
      switch (status) {
        case 'active':
          return 'Work on your deliverables and submit when ready';
        case 'under_review':
          return 'Your submission is being reviewed by the client';
        case 'revision_requested':
          return 'The client requested changes — resubmit when done';
        case 'completed':
          return 'This contract has been completed';
        default:
          return null;
      }
    } else {
      switch (status) {
        case 'active':
          return 'Waiting for the freelancer to submit work';
        case 'under_review':
          return 'Freelancer submitted work — review and take action';
        case 'revision_requested':
          return 'Waiting for the freelancer to resubmit';
        case 'completed':
          return 'You approved the work — contract completed';
        default:
          return null;
      }
    }
  }

  String _submissionStatusLabel(String status) {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'revision_requested':
        return 'Revision Requested';
      case 'approved':
        return 'Approved';
      case 'superseded':
        return 'Superseded';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  Color _submissionStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return const Color(0xFF2196F3);
      case 'revision_requested':
        return const Color(0xFFFF9800);
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'superseded':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '—';
    try {
      final d = DateTime.parse(date);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return date;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '—';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} • '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _fileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'zip':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: AppText.caption.copyWith(color: Colors.white),
          ),
          backgroundColor: isError ? Colors.redAccent : const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  void _showRecordPaymentDialog() {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Record a Payment', style: AppText.h2),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log a payment you made to the freelancer outside the app '
                  '(e.g. bank transfer). This updates the total paid on this contract.',
                  style: AppText.caption.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (${_contract.budgetCurrency})',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    final val = double.tryParse(v?.trim() ?? '');
                    if (val == null || val <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: AppText.bodySemiBold.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => isSubmitting = true);
                      final token = context.read<AuthProvider>().token!;
                      final amount = double.parse(amountCtrl.text.trim());
                      final success = await context
                          .read<ContractProvider>()
                          .reportPayment(
                            token,
                            _contract.contractId,
                            amount,
                            note: noteCtrl.text.trim().isEmpty
                                ? null
                                : noteCtrl.text.trim(),
                          );
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      if (success) {
                        final updated = context
                            .read<ContractProvider>()
                            .currentContract;
                        if (updated != null &&
                            updated.contractId == _contract.contractId) {
                          setState(() => _contract = updated);
                        }
                        _showSnack('Payment recorded.', isError: false);
                      } else {
                        _showSnack(
                          context.read<ContractProvider>().error ??
                              'Failed to record payment.',
                          isError: true,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save',
                      style: AppText.bodySemiBold.copyWith(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel Contract', style: AppText.h2),
        content: Text(
          'Are you sure you want to cancel this contract? This action cannot be undone.',
          style: AppText.body.copyWith(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Keep Contract',
              style: AppText.bodySemiBold.copyWith(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isActioning = true);
              final token = context.read<AuthProvider>().token!;
              final success = await context
                  .read<ContractProvider>()
                  .cancelContract(token, _contract.contractId);
              if (mounted) {
                setState(() => _isActioning = false);
                if (success) {
                  setState(
                    () => _contract = _contract.copyWith(status: 'cancelled'),
                  );
                  _showSnack('Contract cancelled.', isError: false);
                  await Future.delayed(const Duration(milliseconds: 800));
                  if (mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                } else {
                  _showSnack(
                    context.read<ContractProvider>().error ??
                        'Failed to cancel contract.',
                    isError: true,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Cancel Contract',
              style: AppText.bodySemiBold.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
