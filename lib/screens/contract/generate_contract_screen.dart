import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/contract_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/contract_message_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class GenerateContractScreen extends StatefulWidget {
  final String contractId;
  final ContractModel? initialContract;

  const GenerateContractScreen({
    super.key,
    required this.contractId,
    this.initialContract,
  });

  @override
  State<GenerateContractScreen> createState() => _GenerateContractScreenState();
}

class _GenerateContractScreenState extends State<GenerateContractScreen> {
  static const Color _primary = AppColors.primary;

  ContractModel? _contract;
  bool _loading = true;
  bool _generating = false;
  bool _sending = false;
  String? _error;

  // Form fields
  late TextEditingController _contractTitleController;
  late TextEditingController _roleTitleController;
  late TextEditingController _agreedBudgetController;
  late TextEditingController _endDateController;
  late TextEditingController _agreedDurationController;
  late TextEditingController _confidentialityTextController;
  late TextEditingController _additionalClausesController;
  late TextEditingController _paymentScheduleController;
  late TextEditingController _revisionRoundsController;

  String _selectedBudgetCurrency = 'IDR';
  String _selectedPaymentStructure = 'full_payment';
  String? _selectedTerminationNotice = '30';
  String? _selectedDisputeResolution = 'negotiation';
  bool _confidentiality = false;
  bool _latepaymentPenalty = false;
  int? _revisionRounds = 2;

  @override
  void initState() {
    super.initState();
    _contractTitleController = TextEditingController();
    _roleTitleController = TextEditingController();
    _agreedBudgetController = TextEditingController();
    _endDateController = TextEditingController();
    _agreedDurationController = TextEditingController();
    _confidentialityTextController = TextEditingController();
    _additionalClausesController = TextEditingController();
    _paymentScheduleController = TextEditingController();
    _revisionRoundsController = TextEditingController(
      text: _revisionRounds.toString(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContract();
    });
  }

  @override
  void dispose() {
    _contractTitleController.dispose();
    _roleTitleController.dispose();
    _agreedBudgetController.dispose();
    _endDateController.dispose();
    _agreedDurationController.dispose();
    _confidentialityTextController.dispose();
    _additionalClausesController.dispose();
    _paymentScheduleController.dispose();
    _revisionRoundsController.dispose();
    super.dispose();
  }

  Future<void> _loadContract() async {
    final token = context.read<AuthProvider>().token!;
    final contractProvider = context.read<ContractProvider>();

    try {
      setState(() => _loading = true);
      await contractProvider.fetchContractById(token, widget.contractId);

      if (mounted) {
        _contract = contractProvider.currentContract;
        if (_contract != null) {
          _contractTitleController.text = _contract!.contractTitle;
          _roleTitleController.text = _contract!.roleTitle;
          _agreedBudgetController.text = _contract!.agreedBudget
              .toStringAsFixed(0);
          _selectedBudgetCurrency = _contract!.budgetCurrency.isNotEmpty
              ? _contract!.budgetCurrency
              : 'IDR';
          _selectedPaymentStructure = _contract!.paymentStructure.isNotEmpty
              ? _contract!.paymentStructure
              : 'full_payment';
          _endDateController.text = _contract!.endDate ?? '';
          _agreedDurationController.text = _contract!.agreedDuration ?? '';
        }
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      _endDateController.text = picked.toString().split(' ')[0];
    }
  }

  Future<bool> _saveContractDetails() async {
    if (_contract == null) return false;

    final token = context.read<AuthProvider>().token!;
    final contractProvider = context.read<ContractProvider>();
    final agreedBudget = double.tryParse(
      _agreedBudgetController.text.replaceAll(',', ''),
    );

    if (agreedBudget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid budget amount',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final updateData = {
      'contract_title': _contractTitleController.text,
      'role_title': _roleTitleController.text,
      'agreed_budget': agreedBudget,
      'budget_currency': _selectedBudgetCurrency,
      'payment_structure': _selectedPaymentStructure,
    };

    return await contractProvider.updateContract(
      token,
      widget.contractId,
      updateData,
    );
  }

  Future<void> _generateContract() async {
    if (_endDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please set an end date', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final token = context.read<AuthProvider>().token!;
    final contractProvider = context.read<ContractProvider>();

    setState(() => _generating = true);

    try {
      final saveSuccess = await _saveContractDetails();
      if (!saveSuccess) {
        setState(() => _generating = false);
        return;
      }

      final generationData = {
        'end_date': _endDateController.text,
        'agreed_duration': _agreedDurationController.text,
        'termination_notice':
            int.tryParse(_selectedTerminationNotice ?? '30') ?? 30,
        'governing_law': 'Indonesian Law',
        'confidentiality': _confidentiality,
        'confidentiality_text': _confidentialityTextController.text,
        'late_payment_penalty': _latepaymentPenalty,
        'dispute_resolution': _selectedDisputeResolution ?? 'mediation',
        'revision_rounds': int.tryParse(_revisionRoundsController.text) ?? 2,
        'additional_clauses': _additionalClausesController.text,
        'payment_schedule': _paymentScheduleController.text,
      };

      final success = await contractProvider.generateContractPdf(
        token,
        widget.contractId,
        generationData,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Contract generated successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: _primary,
          ),
        );

        await contractProvider.fetchContractById(token, widget.contractId);
        if (mounted) {
          setState(() {
            _contract = contractProvider.currentContract;
            _generating = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = contractProvider.error ?? 'Failed to generate contract';
            _generating = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _generating = false;
        });
      }
    }
  }

  Future<void> _openContractPdf() async {
    if (_contract?.contractPdfUrl == null ||
        _contract!.contractPdfUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No PDF available', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final token = context.read<AuthProvider>().token!;
    final contractProvider = context.read<ContractProvider>();

    try {
      final pdfUrl = await contractProvider.fetchPdfUrl(
        token,
        widget.contractId,
      );

      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'contract_${widget.contractId}.pdf';
        final filePath = '${directory.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF downloaded successfully to $filePath',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to download PDF: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendToFreelancer() async {
    if (_contract == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Contract data not available',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_contract!.contractPdfUrl == null ||
        _contract!.contractPdfUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Contract PDF must be generated first',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final token = context.read<AuthProvider>().token!;
    final messageProvider = context.read<ContractMessageProvider>();

    setState(() => _sending = true);

    try {
      final sent = await messageProvider.sendMessage(
        token: token,
        contractId: widget.contractId,
        messageText: 'Your contract PDF is ready. Please review it.',
      );

      if (!mounted) return;

      setState(() => _sending = false);

      if (sent != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Contract sent to freelancer successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              messageProvider.error ?? 'Failed to send contract',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send contract: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Generate Contract',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_contract != null) ...[
                      _buildSection('Agreement Details', [
                        _buildTextField(
                          'Contract Title',
                          _contractTitleController,
                          'e.g. Website Development Agreement',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          'Role Title',
                          _roleTitleController,
                          'e.g. Frontend Developer',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          'Agreed Budget',
                          _agreedBudgetController,
                          'e.g. 5000000',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          'Budget Currency',
                          _selectedBudgetCurrency,
                          ['IDR', 'USD'],
                          (value) => setState(
                            () => _selectedBudgetCurrency = value ?? 'IDR',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          'Payment Structure',
                          _selectedPaymentStructure,
                          ['full_payment', 'milestone_based'],
                          (value) => setState(
                            () => _selectedPaymentStructure =
                                value ?? 'full_payment',
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection('Contract Terms', [
                        _buildTextField(
                          'End Date',
                          _endDateController,
                          'YYYY-MM-DD',
                          onTap: _selectDate,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          'Duration (e.g., "3 months")',
                          _agreedDurationController,
                          'e.g., 3 months',
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          'Termination Notice (days)',
                          _selectedTerminationNotice,
                          ['7', '14', '30'],
                          (value) => setState(
                            () => _selectedTerminationNotice = value,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          'Dispute Resolution',
                          _selectedDisputeResolution,
                          ['negotiation', 'mediation', 'arbitration'],
                          (value) => setState(
                            () => _selectedDisputeResolution = value,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection('Additional Terms', [
                        _buildTextField(
                          'Payment Schedule / Milestones',
                          _paymentScheduleController,
                          'e.g. 50% upfront, 50% on completion',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        _buildCheckbox(
                          'Confidentiality Clause',
                          _confidentiality,
                          (value) =>
                              setState(() => _confidentiality = value ?? false),
                        ),
                        if (_confidentiality) ...[
                          const SizedBox(height: 12),
                          _buildTextField(
                            'Confidentiality Details',
                            _confidentialityTextController,
                            'Enter any confidentiality terms...',
                            maxLines: 3,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildCheckbox(
                          'Late Payment Penalty',
                          _latepaymentPenalty,
                          (value) => setState(
                            () => _latepaymentPenalty = value ?? false,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          'Revision Rounds',
                          _revisionRoundsController,
                          '0',
                          onChanged: (value) {
                            _revisionRounds = int.tryParse(value);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          'Additional Clauses',
                          _additionalClausesController,
                          'Add any additional terms...',
                          maxLines: 3,
                        ),
                      ]),
                      const SizedBox(height: 24),
                      if (_contract?.contractPdfUrl != null) ...[
                        ElevatedButton.icon(
                          onPressed: _openContractPdf,
                          icon: const Icon(Icons.download),
                          label: Text(
                            'Download Generated PDF',
                            style: GoogleFonts.poppins(),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      ElevatedButton(
                        onPressed: _generating ? null : _generateContract,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          minimumSize: const Size(double.infinity, 48),
                          disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                        ),
                        child: _generating
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              )
                            : Text(
                                'Generate Contract PDF',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      if (_contract?.contractPdfUrl != null &&
                          _contract!.contractPdfUrl!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _sending ? null : _sendToFreelancer,
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            'Send to Freelancer',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 48),
                            disabledBackgroundColor: Colors.grey.withOpacity(
                              0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF7D7D7D),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    VoidCallback? onTap,
    Function(String)? onChanged,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onTap: onTap,
          onChanged: onChanged,
          keyboardType: keyboardType,
          readOnly: onTap != null,
          style: GoogleFonts.poppins(fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFFB5B4B4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFF0F0F1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFF0F0F1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?)? onChanged) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged, activeColor: _primary),
        Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }
}
