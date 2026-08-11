import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/constants/colors.dart';
import '../core/constants/payment_config.dart';
import '../core/utils/helpers.dart';
import '../models/contract_milestone_model.dart';
import '../models/contract_model.dart';
import '../models/payment_proof_model.dart';
import '../models/payout_info_model.dart';
import '../providers/auth_provider.dart';
import '../providers/contract_provider.dart';
import '../services/payment_service.dart';
import 'app_toast.dart';

const Set<String> _kPaymentStageStatuses = {
  'pending_payment',
  'payment_review',
  'payment_rejected',
};

class PaymentProofSection extends StatefulWidget {
  final ContractModel contract;
  final String viewerRole;
  final VoidCallback onContractUpdated;

  const PaymentProofSection({
    super.key,
    required this.contract,
    required this.viewerRole,
    required this.onContractUpdated,
  });

  static bool showsFor(ContractModel contract) =>
      _kPaymentStageStatuses.contains(contract.status) ||
      (contract.status == 'completed' && contract.commissionAmount != null);

  @override
  State<PaymentProofSection> createState() => _PaymentProofSectionState();
}

class _PaymentProofSectionState extends State<PaymentProofSection> {
  final PaymentService _service = PaymentService();

  List<PaymentProofModel> _proofs = [];
  List<ContractMilestoneModel> _milestones = const [];
  PayoutInfoModel? _freelancerPayout;
  bool _isLoading = true;
  bool _isConfirming = false;

  bool get _isClient => widget.viewerRole == 'client';
  bool get _isFreelancer => widget.viewerRole == 'freelancer';

  ContractMilestoneModel? get _currentMilestone => _milestones.current;

  bool get _inCommissionStage =>
      _milestones.isNotEmpty && _currentMilestone == null;

  double get _milestoneFreelancerShare =>
      (_currentMilestone?.amount ?? 0) * (1 - kPlatformCommissionRate);

  double get _totalCommission =>
      widget.contract.agreedBudget * kPlatformCommissionRate;

  String get _currency => widget.contract.budgetCurrency;

  String? get _milestoneSubtitle {
    final milestone = _currentMilestone;
    if (milestone == null || _milestones.isEmpty) return null;
    return 'Milestone ${_milestones.currentPosition} of ${_milestones.length}'
        ' · ${milestone.title}';
  }

  bool get _freelancerConfirmed =>
      _currentMilestone?.freelancerConfirmedReceiptAt != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PaymentProofSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contract.status != widget.contract.status) _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final contractProvider = context.read<ContractProvider>();
      final results = await Future.wait([
        _service.getPaymentProofs(
          token: token,
          contractId: widget.contract.contractId,
        ),
        contractProvider.fetchMilestones(token, widget.contract.contractId),
      ]);
      final proofs = results[0] as List<PaymentProofModel>;
      final milestones = results[1] as List<ContractMilestoneModel>;

      final payout = _isClient
          ? await _service.getPayoutInfo(
              token: token,
              freelancerId: widget.contract.freelancerId,
            )
          : null;
      if (!mounted) return;
      setState(() {
        _proofs = proofs;
        _milestones = milestones;
        _freelancerPayout = payout;
      });
    } catch (e) {
      debugPrint('PaymentProofSection load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  PaymentProofModel? _freelancerProofForCurrentMilestone() {
    final milestoneId = _currentMilestone?.milestoneId;

    final matches = _proofs.where((p) {
      if (p.payee != 'freelancer') return false;
      if (milestoneId == null) return true;
      return p.milestoneId == null || p.milestoneId == milestoneId;
    }).toList();

    if (matches.isEmpty) return null;
    matches.sort(
      (a, b) =>
          (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)),
    );
    return matches.last;
  }

  PaymentProofModel? _adminProof() {
    final matches = _proofs
        .where((p) => p.payee == 'admin' && p.milestoneId == null)
        .toList();
    if (matches.isEmpty) return null;
    matches.sort(
      (a, b) =>
          (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)),
    );
    return matches.last;
  }

  IconData _fileIconFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    return Icons.image_rounded;
  }

  Future<void> _openUploadSheet({
    required String payee,
    required double expected,
    required String title,
  }) async {
    File? pickedFile;
    final refController = TextEditingController();
    bool submitting = false;

    await showModalBottomSheet(
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
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Amount to transfer: $_currency ${expected.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
                  );
                  final path = result?.files.single.path;
                  if (path != null) setModal(() => pickedFile = File(path));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: pickedFile == null ? null : const Color(0xFFF5F6FF),
                    border: Border.all(
                      color: pickedFile == null
                          ? const Color(0xFFD1D5DB)
                          : AppColors.primary,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        pickedFile == null
                            ? Icons.upload_file_rounded
                            : Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pickedFile == null
                            ? 'Tap to add a screenshot or receipt'
                            : 'File selected, tap to change',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PDF, PNG, or JPG',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (pickedFile != null) ...[
                const SizedBox(height: 10),
                Chip(
                  avatar: Icon(
                    _fileIconFor(pickedFile!.path),
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    pickedFile!.path.split(Platform.pathSeparator).last,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  backgroundColor: const Color(0xFFEEF2FF),
                  side: BorderSide.none,
                  deleteIcon: const Icon(Icons.close_rounded, size: 14),
                  onDeleted: () => setModal(() => pickedFile = null),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: refController,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Transaction reference (optional)',
                  labelStyle: GoogleFonts.poppins(fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.all(14),
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
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (pickedFile == null || submitting)
                      ? null
                      : () async {
                          setModal(() => submitting = true);
                          try {
                            final token = context.read<AuthProvider>().token!;
                            await _service.uploadPaymentProof(
                              token: token,
                              contractId: widget.contract.contractId,
                              payee: payee,
                              amount: expected,
                              referenceNumber: refController.text,
                              file: pickedFile!,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            AppToast.success(
                              payee == 'admin'
                                  ? 'Proof uploaded, awaiting admin verification.'
                                  : 'Proof uploaded, waiting for the freelancer to confirm.',
                            );
                            await _load();
                            widget.onContractUpdated();
                          } catch (e) {
                            setModal(() => submitting = false);
                            AppToast.error('Upload failed: $e');
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: submitting
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
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
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

  Future<void> _confirmReceipt() async {
    setState(() => _isConfirming = true);
    try {
      final token = context.read<AuthProvider>().token!;
      await _service.confirmReceipt(
        token: token,
        contractId: widget.contract.contractId,
      );
      AppToast.success('Thanks. Receipt confirmed.');
      await _load();
      widget.onContractUpdated();
    } catch (e) {
      AppToast.error('Failed to confirm receipt: $e');
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  Future<void> _openProofFile(String url) async {
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

  Color _proofStatusColor(String? status) {
    switch (status) {
      case 'verified':
        return const Color(0xFF059669);
      case 'rejected':
        return const Color(0xFFDC2626);
      case 'pending_review':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _proofStatusLabel(
    PaymentProofModel? proof, {
    required bool needsAdminReview,
  }) {
    if (proof == null) return 'Not uploaded yet';
    switch (proof.status) {
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Rejected - needs re-upload';
      default:
        return needsAdminReview
            ? 'Awaiting admin review'
            : 'Uploaded - waiting on freelancer';
    }
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF0F0F1)),
    ),
    child: child,
  );

  Widget _breakdownRow(String label, String value, {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF6B7280),
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: bold ? AppColors.primary : const Color(0xFF111827),
              ),
            ),
          ],
        ),
      );

  Widget _payeeBlock({
    required String payee,
    required String title,
    required double amount,
    required PaymentProofModel? proof,
    required bool needsAdminReview,
    String? bankName,
    String? accountNumber,
    String? accountHolder,
    String? missingBankWarning,
  }) {
    final statusColor = _proofStatusColor(proof?.status);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _proofStatusLabel(proof, needsAdminReview: needsAdminReview),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$_currency ${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          if (proof != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _openProofFile(proof.fileUrl),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'View uploaded proof',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if ((proof.referenceNumber ?? '').trim().isNotEmpty) ...[
                      Text(
                        'Ref: ${proof.referenceNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_isClient && bankName != null) ...[
            const SizedBox(height: 6),
            Text(
              '$bankName · $accountNumber · $accountHolder',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
          if (_isClient && missingBankWarning != null) ...[
            const SizedBox(height: 6),
            Text(
              missingBankWarning,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
          if (proof?.isRejected == true &&
              (proof?.rejectionReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Reason: ${proof!.rejectionReason}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFFDC2626),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (_isClient &&
              (proof == null || proof.isRejected) &&
              missingBankWarning == null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openUploadSheet(
                  payee: payee,
                  expected: amount,
                  title: title,
                ),
                icon: const Icon(Icons.upload_file_rounded, size: 15),
                label: Text(proof == null ? 'Upload proof' : 'Re-upload proof'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!PaymentProofSection.showsFor(widget.contract))
      return const SizedBox.shrink();

    final isCompleted =
        widget.contract.status == 'completed' &&
        widget.contract.commissionAmount != null;

    final title = isCompleted
        ? 'Payment'
        : (_inCommissionStage ? 'Platform Fee' : 'Milestone Payment');

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.payments_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (!isCompleted &&
              !_inCommissionStage &&
              _milestoneSubtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              _milestoneSubtitle!,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else if (isCompleted)
            ..._buildCompletedSummary()
          else if (_inCommissionStage)
            ..._buildCommissionStage()
          else
            ..._buildMilestonePaymentStage(),
        ],
      ),
    );
  }

  List<Widget> _buildCompletedSummary() {
    return [
      _breakdownRow(
        'Total budget',
        '$_currency ${widget.contract.agreedBudget.toStringAsFixed(2)}',
      ),
      _breakdownRow(
        _isClient ? "Freelancer received (total)" : "You received (total)",
        '$_currency ${(widget.contract.payoutAmount ?? (widget.contract.agreedBudget - _totalCommission)).toStringAsFixed(2)}',
        bold: true,
      ),
      _breakdownRow(
        'Platform fee (${(kPlatformCommissionRate * 100).toStringAsFixed(0)}% of total)',
        '$_currency ${(widget.contract.commissionAmount ?? _totalCommission).toStringAsFixed(2)}',
      ),
      if (widget.contract.completedByAdminOverride)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Marked complete by admin override.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFFD97706),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildMilestonePaymentStage() {
    final milestone = _currentMilestone;
    final proof = _freelancerProofForCurrentMilestone();

    return [
      Text(
        _isClient
            ? milestone == null
                  ? 'This milestone is approved. Transfer the freelancer\'s share directly and upload proof.'
                  : 'The work for "${milestone.title}" is approved. Transfer the freelancer\'s share directly '
                        'and upload proof. The next milestone unlocks once they confirm receiving it.'
            : 'The client is paying you for this milestone. Once you\'ve received your share directly in '
                  'your bank account, confirm it below.',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF6B7280),
          height: 1.4,
        ),
      ),
      if (milestone != null)
        _breakdownRow(
          'Milestone amount',
          '$_currency ${milestone.amount.toStringAsFixed(2)}',
        ),
      const SizedBox(height: 6),
      _payeeBlock(
        payee: 'freelancer',
        title: "Freelancer's share (90%)",
        amount: _milestoneFreelancerShare,
        proof: proof,
        needsAdminReview: false,
        bankName: _freelancerPayout?.bankName,
        accountNumber: _freelancerPayout?.accountNumber,
        accountHolder: _freelancerPayout?.accountHolderName,
        missingBankWarning: (_isClient && _freelancerPayout?.isComplete != true)
            ? 'The freelancer hasn\'t added their bank details yet - ask them to add it under '
                  'Settings before you can send this share.'
            : null,
      ),
      if (_isFreelancer) ...[
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_isConfirming || _freelancerConfirmed)
                ? null
                : _confirmReceipt,
            icon: _isConfirming
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _freelancerConfirmed
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 16,
                  ),
            label: Text(
              _freelancerConfirmed
                  ? 'Payment Confirmed'
                  : 'I\'ve received my payment',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE5E7EB),
              disabledForegroundColor: const Color(0xFF6B7280),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildCommissionStage() {
    final proof = _adminProof();

    return [
      Text(
        _isClient
            ? 'All milestones are paid. Transfer the platform fee directly and upload proof - '
                  'the contract completes once the admin verifies it.'
            : 'You\'ve been paid in full for every milestone. The client is now settling the platform '
                  'fee with WorkByte directly - nothing left for you to do here.',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF6B7280),
          height: 1.4,
        ),
      ),
      _breakdownRow(
        'Total contract budget',
        '$_currency ${widget.contract.agreedBudget.toStringAsFixed(2)}',
      ),
      _breakdownRow(
        _isClient ? "Freelancer received (total)" : "You received (total)",
        '$_currency ${(widget.contract.agreedBudget - _totalCommission).toStringAsFixed(2)}',
        bold: true,
      ),
      const SizedBox(height: 6),
      if (_isClient)
        _payeeBlock(
          payee: 'admin',
          title:
              "Platform fee (${(kPlatformCommissionRate * 100).toStringAsFixed(0)}% of total)",
          amount: _totalCommission,
          proof: proof,
          needsAdminReview: true,
          bankName: AdminPayoutInfo.bankName,
          accountNumber: AdminPayoutInfo.accountNumber,
          accountHolder: AdminPayoutInfo.accountHolderName,
        )
      else
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                size: 16,
                color: Color(0xFF4F46E5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Waiting on the client to pay WorkByte\'s platform fee and an admin to verify it. '
                  'The contract will show as completed once that\'s done.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF3730A3),
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }
}
