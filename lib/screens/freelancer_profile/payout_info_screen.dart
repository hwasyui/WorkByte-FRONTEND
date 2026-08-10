import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/payment_service.dart';
import '../../widgets/app_toast.dart';

class PayoutInfoScreen extends StatefulWidget {
  const PayoutInfoScreen({super.key});

  @override
  State<PayoutInfoScreen> createState() => _PayoutInfoScreenState();
}

class _PayoutInfoScreenState extends State<PayoutInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _service = PaymentService();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final token = context.read<AuthProvider>().token;
    final freelancerId =
        context.read<ProfileProvider>().freelancerProfile?.freelancerId;
    if (token != null && freelancerId != null) {
      final existing = await _service.getPayoutInfo(
        token: token,
        freelancerId: freelancerId,
      );
      if (existing != null && mounted) {
        _bankNameController.text = existing.bankName ?? '';
        _accountNumberController.text = existing.accountNumber ?? '';
        _accountHolderController.text = existing.accountHolderName ?? '';
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final token = context.read<AuthProvider>().token;
    final freelancerId =
        context.read<ProfileProvider>().freelancerProfile?.freelancerId;
    if (token == null || freelancerId == null) {
      AppToast.error('Could not identify your freelancer profile.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.updatePayoutInfo(
        token: token,
        freelancerId: freelancerId,
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        accountHolderName: _accountHolderController.text.trim(),
      );
      if (!mounted) return;
      AppToast.success('Payout details saved.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppToast.error('Failed to save payout details: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _decoration(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280)),
    hintStyle: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFB0B0B0)),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF333333),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payout Bank Details',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF333333),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'When a client completes payment, they transfer your share (90% of '
                            'the agreed budget) directly to this account. WorkByte never holds '
                            'or forwards it. Keep this accurate before accepting contracts.',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: const Color(0xFF3730A3),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _bankNameController,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: _decoration('Bank name', 'e.g. Bank Central Asia'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Bank name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: _decoration('Account number', 'e.g. 1234567890'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Account number is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _accountHolderController,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: _decoration('Account holder name', 'Name as it appears on the account'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Account holder name is required'
                        : null,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Save',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
