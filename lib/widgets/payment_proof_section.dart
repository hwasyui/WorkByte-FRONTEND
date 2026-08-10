import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/constants/colors.dart';
import '../core/constants/payment_config.dart';
import '../models/contract_model.dart';
import '../models/payment_proof_model.dart';
import '../models/payout_info_model.dart';
import '../providers/auth_provider.dart';
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
  PayoutInfoModel? _freelancerPayout;
  bool _isLoading = true;
  bool _isConfirming = false;

  bool get _isClient => widget.viewerRole == 'client';
  bool get _isFreelancer => widget.viewerRole == 'freelancer';

  double get _freelancerShare =>
      widget.contract.agreedBudget * (1 - kPlatformCommissionRate);
  double get _commissionShare =>
      widget.contract.agreedBudget * kPlatformCommissionRate;
  String get _currency => widget.contract.budgetCurrency;

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
      final proofs = await _service.getPaymentProofs(
        token: token,
        contractId: widget.contract.contractId,
      );
      final payout = _isClient
          ? await _service.getPayoutInfo(
              token: token,
              freelancerId: widget.contract.freelancerId,
            )
          : null;
      if (!mounted) return;
      setState(() {
        _proofs = proofs;
        _freelancerPayout = payout;
      });
    } catch (e) {
      debugPrint('PaymentProofSection load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  PaymentProofModel? _proofFor(String payee) {
    for (final p in _proofs) {
      if (p.payee == payee) return p;
    }
    return null;
  }

  Future<void> _openUploadSheet(String payee) async {
    final expected = payee == 'admin' ? _commissionShare : _freelancerShare;
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
            20,
            20,
            20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payee == 'admin'
                    ? 'Upload proof — platform fee'
                    : 'Upload proof — freelancer\'s share',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
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
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
                  );
                  final path = result?.files.single.path;
                  if (path != null) setModal(() => pickedFile = File(path));
                },
                icon: const Icon(Icons.attach_file_rounded, size: 16),
                label: Text(
                  pickedFile == null
                      ? 'Choose screenshot / receipt (PDF, PNG, JPG)'
                      : pickedFile!.path.split(Platform.pathSeparator).last,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: refController,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Transaction reference (optional)',
                  labelStyle: GoogleFonts.poppins(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
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
                            AppToast.success('Proof uploaded — awaiting admin verification.');
                            await _load();
                            widget.onContractUpdated();
                          } catch (e) {
                            setModal(() => submitting = false);
                            AppToast.error('Upload failed: $e');
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Submit', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
      await _service.confirmReceipt(token: token, contractId: widget.contract.contractId);
      AppToast.success('Thanks — receipt confirmed.');
      widget.onContractUpdated();
    } catch (e) {
      AppToast.error('Failed to confirm receipt: $e');
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
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

  String _proofStatusLabel(PaymentProofModel? proof) {
    if (proof == null) return 'Not uploaded yet';
    switch (proof.status) {
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Rejected — needs re-upload';
      default:
        return 'Awaiting admin review';
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

  Widget _breakdownRow(String label, String value, {bool bold = false}) => Padding(
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
    String? bankName,
    String? accountNumber,
    String? accountHolder,
    String? missingBankWarning,
  }) {
    final proof = _proofFor(payee);
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
                  style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _proofStatusLabel(proof),
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
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          if (_isClient && bankName != null) ...[
            const SizedBox(height: 6),
            Text(
              '$bankName · $accountNumber · $accountHolder',
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF6B7280)),
            ),
          ],
          if (_isClient && missingBankWarning != null) ...[
            const SizedBox(height: 6),
            Text(
              missingBankWarning,
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFDC2626)),
            ),
          ],
          if (proof?.isRejected == true && (proof?.rejectionReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Reason: ${proof!.rejectionReason}',
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFDC2626), fontStyle: FontStyle.italic),
            ),
          ],
          if (_isClient && (proof == null || proof.isRejected) && missingBankWarning == null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openUploadSheet(payee),
                icon: const Icon(Icons.upload_file_rounded, size: 15),
                label: Text(proof == null ? 'Upload proof' : 'Re-upload proof'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!PaymentProofSection.showsFor(widget.contract)) return const SizedBox.shrink();

    final isCompleted = widget.contract.status == 'completed' &&
        widget.contract.commissionAmount != null;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                isCompleted ? 'Payment' : 'Final Payment',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            )
          else if (isCompleted)
            ..._buildCompletedSummary()
          else
            ..._buildPendingPayment(),
        ],
      ),
    );
  }

  List<Widget> _buildCompletedSummary() {
    return [
      _breakdownRow('Total budget', '$_currency ${widget.contract.agreedBudget.toStringAsFixed(2)}'),
      _breakdownRow(
        _isClient ? "Freelancer received" : "You received",
        '$_currency ${(widget.contract.payoutAmount ?? _freelancerShare).toStringAsFixed(2)}',
        bold: true,
      ),
      _breakdownRow(
        'Platform fee (${(kPlatformCommissionRate * 100).toStringAsFixed(0)}%)',
        '$_currency ${(widget.contract.commissionAmount ?? _commissionShare).toStringAsFixed(2)}',
      ),
      if (widget.contract.completedByAdminOverride)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Marked complete by admin override.',
            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFD97706), fontStyle: FontStyle.italic),
          ),
        ),
    ];
  }

  List<Widget> _buildPendingPayment() {
    final freelancerConfirmed = widget.contract.freelancerConfirmedReceiptAt != null;

    return [
      Text(
        _isClient
            ? 'All milestones are approved. Transfer each share directly and upload proof — '
                'the contract completes once the platform verifies its share and the freelancer '
                'confirms receiving theirs.'
            : 'All milestones are approved and the client is completing payment. Once you\'ve '
                'received your share directly in your bank account, confirm it below.',
        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280), height: 1.4),
      ),
      _breakdownRow('Total budget', '$_currency ${widget.contract.agreedBudget.toStringAsFixed(2)}'),
      const SizedBox(height: 6),
      _payeeBlock(
        payee: 'freelancer',
        title: "Freelancer's share (90%)",
        amount: _freelancerShare,
        bankName: _freelancerPayout?.bankName,
        accountNumber: _freelancerPayout?.accountNumber,
        accountHolder: _freelancerPayout?.accountHolderName,
        missingBankWarning: (_isClient && _freelancerPayout?.isComplete != true)
            ? 'The freelancer hasn\'t added their bank details yet — ask them to add it under '
                'Settings before you can send this share.'
            : null,
      ),
      _payeeBlock(
        payee: 'admin',
        title: "Platform fee (10%)",
        amount: _commissionShare,
        bankName: AdminPayoutInfo.bankName,
        accountNumber: AdminPayoutInfo.accountNumber,
        accountHolder: AdminPayoutInfo.accountHolderName,
      ),
      if (_isFreelancer) ...[
        const SizedBox(height: 14),
        if (freelancerConfirmed)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF059669)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You confirmed receiving your share. Waiting on the platform\'s own proof '
                    'to be verified before the contract closes.',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF065F46)),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isConfirming ? null : _confirmReceipt,
              icon: _isConfirming
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: const Text('I\'ve received my payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
      ],
    ];
  }
}
