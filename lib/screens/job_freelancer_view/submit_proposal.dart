import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/job_post_model.dart';
import '../../models/job_role_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/proposal_service.dart';

class SubmitProposalScreen extends StatefulWidget {
  final JobPostModel job;
  final JobRoleModel role;

  const SubmitProposalScreen({
    super.key,
    required this.job,
    required this.role,
  });

  @override
  State<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  final _budgetController = TextEditingController();
  final _durationController = TextEditingController();

  List<PlatformFile> _attachedFiles = [];
  bool _isSubmitting = false;
  
  String _durationNumber = '1';
  String _durationUnit = 'day';

  // ── Helpers ──────────────────────────────────────────────────────────────

  String get _currency => widget.role.budgetCurrency;

  /// True if the client locked the budget (budget_type = 'fixed')
  bool get _isFixedBudget => widget.role.budgetType == 'fixed';

  String get _roleBudgetHint {
    if (_isFixedBudget && widget.role.roleBudget != null) {
      return 'Budget fixed by client: $_currency ${widget.role.roleBudget!.toStringAsFixed(0)}';
    }
    return 'Client\'s budget: Negotiable — enter your rate';
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill and lock budget field if fixed
    if (_isFixedBudget && widget.role.roleBudget != null) {
      _budgetController.text = widget.role.roleBudget!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    _budgetController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // ── File picker ──────────────────────────────────────────────────────────
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
    );
    if (result != null) {
      setState(() {
        final existing = _attachedFiles.map((f) => f.name).toSet();
        final newFiles = result.files
            .where((f) => !existing.contains(f.name))
            .toList();
        _attachedFiles.addAll(newFiles);
      });
    }
  }

  void _removeFile(int index) {
    setState(() => _attachedFiles.removeAt(index));
  }

  // ── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final token = context.read<AuthProvider>().token!;
      final freelancerId = context
          .read<ProfileProvider>()
          .freelancerProfile
          ?.freelancerId;

      if (freelancerId == null) {
        _showError('Freelancer profile not found.');
        return;
      }

      // If fixed budget, always use role's budget — ignore whatever is in the field
      final double proposedBudget =
          _isFixedBudget && widget.role.roleBudget != null
          ? widget.role.roleBudget!
          : double.parse(_budgetController.text.trim());

      final proposedDuration = '$_durationNumber $_durationUnit${_durationNumber != '1' ? 's' : ''}';
      
      await ProposalService().submitProposal(
        token: token,
        jobPostId: widget.job.jobPostId,
        jobRoleId: widget.role.jobRoleId,
        freelancerId: freelancerId,
        coverLetter: _coverLetterController.text.trim(),
        proposedBudget: proposedBudget,
        proposedDuration: proposedDuration,
        files: _attachedFiles,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Proposal submitted successfully!',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to submit proposal. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
        title: Text(
          'Submit Proposal',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF333333),
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            children: [
              _buildJobContext(),
              const SizedBox(height: 24),
              _buildLabel('Cover Letter *'),
              const SizedBox(height: 8),
              _buildCoverLetterField(),
              const SizedBox(height: 20),
              _buildLabel('Proposed Budget *'),
              const SizedBox(height: 8),
              _buildBudgetSection(), // ← replaces bare _buildBudgetField()
              const SizedBox(height: 20),
              _buildLabel('Estimated Duration'),
              const SizedBox(height: 8),
              _buildDurationField(),
              const SizedBox(height: 20),
              _buildLabel('Attachments'),
              const SizedBox(height: 8),
              _buildAttachments(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────

  Widget _buildJobContext() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.job.jobTitle,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildTag(widget.role.roleTitle),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
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
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF333333),
      ),
    );
  }

  Widget _buildCoverLetterField() {
    return ValueListenableBuilder(
      valueListenable: _coverLetterController,
      builder: (_, value, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextFormField(
              controller: _coverLetterController,
              maxLines: 6,
              maxLength: 1000,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF333333),
              ),
              decoration: _inputDecoration(
                hint:
                    'Introduce yourself, explain why you\'re a good fit, and describe your approach...',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Cover letter is required';
                }
                if (v.trim().length < 50) {
                  return 'Cover letter must be at least 50 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 4),
            Text(
              '${value.text.length} / 1000',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: value.text.length >= 1000
                    ? Colors.redAccent
                    : const Color(0xFF7D7D7D),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Shows a locked info banner for fixed budget,
  /// or an editable field for negotiable budget.
  Widget _buildBudgetSection() {
    if (_isFixedBudget) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Locked info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$_currency ${widget.role.roleBudget!.toStringAsFixed(0)} — fixed by client',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The client has set a fixed budget for this role.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF7D7D7D),
            ),
          ),
        ],
      );
    }

    // Negotiable — show editable field
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _budgetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF333333),
          ),
          decoration: _inputDecoration(hint: '0').copyWith(
            suffixText: _currency,
            suffixStyle: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Proposed budget is required';
            }
            final val = double.tryParse(v.trim());
            if (val == null || val <= 0) {
              return 'Enter a valid budget greater than 0';
            }
            return null;
          },
        ),
        const SizedBox(height: 6),
        Text(
          _roleBudgetHint,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF7D7D7D),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationField() {
    return Row(
      children: [
        // Number dropdown (1-31)
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _durationNumber,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 18),
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF333333)),
                isExpanded: true,
                items: List.generate(31, (i) {
                  final num = (i + 1).toString();
                  return DropdownMenuItem(value: num, child: Text(num));
                }).toList(),
                onChanged: (v) => setState(() => _durationNumber = v!),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Unit dropdown (day, week, month)
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _durationUnit,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 18),
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF333333)),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'day', child: Text('Day')),
                  DropdownMenuItem(value: 'week', child: Text('Week')),
                  DropdownMenuItem(value: 'month', child: Text('Month')),
                ],
                onChanged: (v) => setState(() => _durationUnit = v!),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_attachedFiles.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_attachedFiles.length, (i) {
              final file = _attachedFiles[i];
              return Chip(
                backgroundColor: AppColors.secondary,
                label: Text(
                  file.name,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
                deleteIcon: const Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.primary,
                ),
                onDeleted: () => _removeFile(i),
                side: BorderSide.none,
              );
            }),
          ),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          onTap: _pickFiles,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.attach_file,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Files',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Supported: PDF, DOC, DOCX, PNG, JPG (optional)',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF7D7D7D),
          ),
        ),
        // Soft nudge — only shown when no files attached
        if (_attachedFiles.isEmpty) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 13,
                color: Color(0xFF7D7D7D),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Adding a portfolio sample increases your chances of getting hired.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF7D7D7D),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
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
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Submit Proposal',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: const Color(0xFFB5B4B4),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF0F0F1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF0F0F1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
