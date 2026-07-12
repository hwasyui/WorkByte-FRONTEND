import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:workbyte_app/providers/dm_provider.dart';

import '../../core/constants/colors.dart';
import '../../core/utils/harmful_block_dialog.dart';
import '../../models/contract_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contract_provider.dart';

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

  static const Map<String, String> _paymentStructureLabels = {
    'full_payment': 'Full Payment',
    'milestone_based': 'Milestone Based',
  };

  static const Map<String, String> _disputeResolutionLabels = {
    'negotiation': 'Negotiation',
    'mediation': 'Mediation',
    'arbitration': 'Arbitration',
  };

  static const Map<String, String> _fullPaymentTimingLabels = {
    'upfront': '100% upfront',
    'on_completion': '100% on completion',
    '50_50': '50% upfront, 50% on completion',
    'custom': 'Custom arrangement',
  };

  ContractModel? _contract;
  bool _loading = true;
  bool _generating = false;
  bool _sending = false;
  String? _error;

  late TextEditingController _contractTitleController;
  late TextEditingController _roleTitleController;
  late TextEditingController _agreedBudgetController;
  late TextEditingController _endDateController;
  late TextEditingController _confidentialityTextController;
  late TextEditingController _additionalClausesController;
  late TextEditingController _paymentScheduleController;
  late TextEditingController _revisionRoundsController;

  final TextEditingController _durationValueController =
      TextEditingController();
  final TextEditingController _customFullPaymentController =
      TextEditingController();

  String _selectedBudgetCurrency = 'IDR';
  String _selectedPaymentStructure = 'full_payment';
  String? _selectedTerminationNotice = '30';
  String? _selectedDisputeResolution = 'negotiation';
  bool _confidentiality = false;
  bool _latepaymentPenalty = false;
  int? _revisionRounds = 2;

  String _selectedDurationUnit = 'months';
  String _selectedFullPaymentTiming = 'upfront';

  final List<_MilestoneItem> _milestones = [_MilestoneItem()];

  @override
  void initState() {
    super.initState();
    _contractTitleController = TextEditingController();
    _roleTitleController = TextEditingController();
    _agreedBudgetController = TextEditingController();
    _endDateController = TextEditingController();
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
    _confidentialityTextController.dispose();
    _additionalClausesController.dispose();
    _paymentScheduleController.dispose();
    _revisionRoundsController.dispose();
    _durationValueController.dispose();
    _customFullPaymentController.dispose();

    for (final m in _milestones) {
      m.dispose();
    }

    super.dispose();
  }

  Future<void> _loadContract() async {
    final token = context.read<AuthProvider>().token!;
    final contractProvider = context.read<ContractProvider>();

    try {
      setState(() => _loading = true);
      await contractProvider.fetchContractById(token, widget.contractId);

      if (!mounted) return;

      _contract = contractProvider.currentContract;
      if (_contract != null) {
        _contractTitleController.text = _contract!.contractTitle;
        _roleTitleController.text = _contract!.roleTitle;
        _agreedBudgetController.text = _contract!.agreedBudget.toStringAsFixed(
          0,
        );

        _selectedBudgetCurrency = _contract!.budgetCurrency.isNotEmpty
            ? _contract!.budgetCurrency
            : 'IDR';

        _selectedPaymentStructure = _contract!.paymentStructure.isNotEmpty
            ? _contract!.paymentStructure
            : 'full_payment';

        _endDateController.text = _contract!.endDate ?? '';

        _hydrateDuration(_contract!.agreedDuration ?? '');
      }

      setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _hydrateDuration(String value) {
    if (value.trim().isEmpty) return;

    final raw = value.trim().toLowerCase();
    final regex = RegExp(r'^(\d+)\s+(day|days|week|weeks|month|months)$');
    final match = regex.firstMatch(raw);

    if (match != null) {
      _durationValueController.text = match.group(1) ?? '';
      final unit = match.group(2) ?? 'months';
      if (unit.startsWith('day')) {
        _selectedDurationUnit = 'days';
      } else if (unit.startsWith('week')) {
        _selectedDurationUnit = 'weeks';
      } else {
        _selectedDurationUnit = 'months';
      }
    } else {
      _durationValueController.text = '';
      _selectedDurationUnit = 'months';
    }
  }

  String _displayLabel(Map<String, String> map, String key) {
    return map[key] ?? key;
  }

  String _buildDurationString() {
    final value = _durationValueController.text.trim();
    if (value.isEmpty) return '';
    return '$value $_selectedDurationUnit';
  }

  String _buildPaymentScheduleString() {
    if (_selectedPaymentStructure == 'full_payment') {
      if (_selectedFullPaymentTiming == 'custom') {
        return _customFullPaymentController.text.trim();
      }

      return _fullPaymentTimingLabels[_selectedFullPaymentTiming] ?? '';
    }

    final lines = <String>[];
    for (int i = 0; i < _milestones.length; i++) {
      final m = _milestones[i];
      final title = m.titleController.text.trim();
      final percentage = m.percentageController.text.trim();
      final note = m.noteController.text.trim();

      if (title.isEmpty && percentage.isEmpty && note.isEmpty) continue;

      final buffer = StringBuffer();
      buffer.write('Milestone ${i + 1}: ');
      buffer.write(title.isEmpty ? 'Unnamed milestone' : title);

      if (percentage.isNotEmpty) {
        buffer.write(' - $percentage% payment');
      }

      if (note.isNotEmpty) {
        buffer.write(' ($note)');
      }

      lines.add(buffer.toString());
    }

    return lines.join('\n');
  }

  bool _validateMilestones() {
    if (_selectedPaymentStructure != 'milestone_based') return true;

    final filled = _milestones.where((m) {
      return m.titleController.text.trim().isNotEmpty ||
          m.percentageController.text.trim().isNotEmpty ||
          m.noteController.text.trim().isNotEmpty;
    }).toList();

    if (filled.isEmpty) {
      _showError('Please add at least one milestone');
      return false;
    }

    double total = 0;
    for (final m in filled) {
      final title = m.titleController.text.trim();
      final percentage = double.tryParse(m.percentageController.text.trim());

      if (title.isEmpty) {
        _showError('Each milestone must have a title');
        return false;
      }

      if (percentage == null || percentage <= 0) {
        _showError('Each milestone must have a valid payment percentage');
        return false;
      }

      total += percentage;
    }

    if (total > 100.0) {
      _showError('Total milestone percentage cannot exceed 100%');
      return false;
    }

    return true;
  }

  void _addMilestone() {
    setState(() {
      _milestones.add(_MilestoneItem());
    });
  }

  void _removeMilestone(int index) {
    if (_milestones.length == 1) return;

    setState(() {
      final item = _milestones.removeAt(index);
      item.dispose();
    });
  }

  void _showError(String message) {
    showErrorFeedback(context, message: message);
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
      _showError('Please enter a valid budget amount');
      return false;
    }

    final updateData = {
      'contract_title': _contractTitleController.text.trim(),
      'role_title': _roleTitleController.text.trim(),
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

  Map<String, dynamic> _buildGenerationData({required bool sendNotification}) {
    final paymentSchedule = _buildPaymentScheduleString();

    return {
      'end_date': _endDateController.text,
      'agreed_duration': _buildDurationString(),
      'termination_notice':
          int.tryParse(_selectedTerminationNotice ?? '30') ?? 30,
      'governing_law': 'Indonesian Law',
      'confidentiality': _confidentiality,
      'confidentiality_text': _confidentialityTextController.text.trim(),
      'late_payment_penalty': _latepaymentPenalty,
      'dispute_resolution': _selectedDisputeResolution ?? 'negotiation',
      'revision_rounds': int.tryParse(_revisionRoundsController.text) ?? 2,
      'additional_clauses': _additionalClausesController.text.trim(),
      'payment_schedule': paymentSchedule,
      'send_notification': sendNotification,
    };
  }

  Future<void> _generateContract() async {
    if (_endDateController.text.isEmpty) {
      _showError('Please set an end date');
      return;
    }

    if (_durationValueController.text.trim().isEmpty) {
      _showError('Please enter the agreed duration');
      return;
    }

    if (_selectedPaymentStructure == 'full_payment' &&
        _selectedFullPaymentTiming == 'custom' &&
        _customFullPaymentController.text.trim().isEmpty) {
      _showError('Please describe the full payment schedule');
      return;
    }

    if (!_validateMilestones()) {
      return;
    }

    final token = context.read<AuthProvider>().token!;
    final contractProvider = context.read<ContractProvider>();

    setState(() => _generating = true);

    try {
      final saveSuccess = await _saveContractDetails();
      if (!saveSuccess) {
        setState(() => _generating = false);
        if (mounted) {
          _showError(
            context.read<ContractProvider>().error ??
                'Failed to save contract details',
          );
        }
        return;
      }

      final paymentSchedule = _buildPaymentScheduleString();
      _paymentScheduleController.text = paymentSchedule;

      final generationData = _buildGenerationData(sendNotification: false);

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

      final response = await http.get(
        Uri.parse(pdfUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
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
      _showError('Contract data not available');
      return;
    }

    if (!_validateMilestones()) return;

    final token = context.read<AuthProvider>().token!;
    final contractProvider = context.read<ContractProvider>();

    setState(() => _sending = true);

    try {
      final saveSuccess = await _saveContractDetails();
      if (!saveSuccess) {
        setState(() => _sending = false);
        if (mounted) {
          _showError(
            context.read<ContractProvider>().error ??
                'Failed to save contract details',
          );
        }
        return;
      }

      final generationData = _buildGenerationData(sendNotification: true);

      final success = await contractProvider.generateContractPdf(
        token,
        widget.contractId,
        generationData,
      );

      if (!mounted) return;

      setState(() => _sending = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Contract sent to freelancer successfully!'
                : contractProvider.error ?? 'Failed to send contract',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: success ? AppColors.primary : Colors.red,
        ),
      );

      if (success) {
        await contractProvider.fetchContractById(token, widget.contractId);
        if (mounted) {
          setState(() => _contract = contractProvider.currentContract);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _showError('Failed to send contract: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(
          'Generate Contract',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFF6F8FB),
        foregroundColor: const Color(0xFF1F2937),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    _buildErrorBanner(_error!),
                    const SizedBox(height: 16),
                  ],
                  if (_contract != null) ...[
                    _buildSectionCard(
                      title: 'Agreement Details',
                      subtitle: 'Basic information for the contract agreement.',
                      icon: Icons.handshake_outlined,
                      children: [
                        _buildTextField(
                          'Contract Title',
                          _contractTitleController,
                          'e.g. Website Development Agreement',
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          'Role Title',
                          _roleTitleController,
                          'e.g. Frontend Developer',
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                'Agreed Budget',
                                _agreedBudgetController,
                                'e.g. 5000000',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Currency',
                                value: _selectedBudgetCurrency,
                                items: const ['IDR', 'USD'],
                                labelBuilder: (v) => v,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedBudgetCurrency = value ?? 'IDR';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildDropdownField(
                          label: 'Payment Structure',
                          value: _selectedPaymentStructure,
                          items: const ['full_payment', 'milestone_based'],
                          labelBuilder: (value) =>
                              _displayLabel(_paymentStructureLabels, value),
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentStructure =
                                  value ?? 'full_payment';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Contract Terms',
                      subtitle:
                          'Set the duration, end date, and legal handling terms.',
                      icon: Icons.rule_folder_outlined,
                      children: [
                        _buildTextField(
                          'End Date',
                          _endDateController,
                          'YYYY-MM-DD',
                          onTap: _selectDate,
                          prefixIcon: Icons.calendar_today_outlined,
                        ),
                        const SizedBox(height: 14),
                        _buildDurationField(),
                        const SizedBox(height: 14),
                        _buildDropdownField(
                          label: 'Termination Notice',
                          value: _selectedTerminationNotice,
                          items: const ['7', '14', '30'],
                          labelBuilder: (value) => '$value days',
                          onChanged: (value) {
                            setState(() {
                              _selectedTerminationNotice = value;
                            });
                          },
                          prefixIcon: Icons.schedule_outlined,
                        ),
                        const SizedBox(height: 14),
                        _buildDropdownField(
                          label: 'Dispute Resolution',
                          value: _selectedDisputeResolution,
                          items: const [
                            'negotiation',
                            'mediation',
                            'arbitration',
                          ],
                          labelBuilder: (value) =>
                              _displayLabel(_disputeResolutionLabels, value),
                          onChanged: (value) {
                            setState(() {
                              _selectedDisputeResolution = value;
                            });
                          },
                          prefixIcon: Icons.gavel_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Payment & Additional Terms',
                      subtitle:
                          'Tailor the payment arrangement and optional clauses.',
                      icon: Icons.description_outlined,
                      children: [
                        _buildPaymentStructureEditor(),
                        const SizedBox(height: 14),
                        _buildCheckboxTile(
                          'Include confidentiality clause',
                          _confidentiality,
                          (value) =>
                              setState(() => _confidentiality = value ?? false),
                        ),
                        if (_confidentiality) ...[
                          const SizedBox(height: 12),
                          _buildTextField(
                            'Confidentiality Details',
                            _confidentialityTextController,
                            'Describe what information must remain confidential...',
                            maxLines: 3,
                            prefixIcon: Icons.lock_outline_rounded,
                          ),
                        ],
                        const SizedBox(height: 14),
                        _buildCheckboxTile(
                          'Apply late payment penalty',
                          _latepaymentPenalty,
                          (value) => setState(
                            () => _latepaymentPenalty = value ?? false,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          'Revision Rounds',
                          _revisionRoundsController,
                          'e.g. 2',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.sync_outlined,
                          onChanged: (value) {
                            _revisionRounds = int.tryParse(value);
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          'Additional Clauses',
                          _additionalClausesController,
                          'Add any extra terms, limitations, or conditions...',
                          maxLines: 4,
                          prefixIcon: Icons.notes_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (_contract?.contractPdfUrl != null) ...[
                      _buildActionButton(
                        onPressed: _openContractPdf,
                        icon: Icons.download_outlined,
                        label: 'Download Generated PDF',
                        backgroundColor: const Color(0xFFEEF6FF),
                        foregroundColor: const Color(0xFF2563EB),
                        borderColor: const Color(0xFFD9E8FF),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_contract?.contractPdfUrl == null ||
                        _contract!.contractPdfUrl!.isEmpty) ...[
                      _buildActionButton(
                        onPressed: _generating ? null : _generateContract,
                        icon: _generating
                            ? null
                            : Icons.picture_as_pdf_outlined,
                        label: 'Generate Contract PDF',
                        loading: _generating,
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                      ),
                    ] else ...[
                      _buildActionButton(
                        onPressed: _sending ? null : _sendToFreelancer,
                        icon: _sending ? null : Icons.send_outlined,
                        label: 'Send to Freelancer',
                        loading: _sending,
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary.withValues(alpha: 0.10), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: _primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set up contract terms',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use structured fields so the final contract is clearer, more consistent, and easier to review.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF667085),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: const Color(0xFFB42318),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF8A8F98),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
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
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF344054),
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onTap: onTap,
          onChanged: onChanged,
          keyboardType: keyboardType,
          readOnly: onTap != null,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF101828),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF98A2B3),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: _primary, size: 20)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            contentPadding: prefixIcon != null
                ? const EdgeInsets.symmetric(vertical: 15)
                : const EdgeInsets.all(14),
            filled: true,
            fillColor: const Color(0xFFFCFCFD),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String Function(String) labelBuilder,
    required Function(String?) onChanged,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF344054),
          ),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primary),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    labelBuilder(item),
                    style: GoogleFonts.poppins(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: _primary, size: 20)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            contentPadding: prefixIcon != null
                ? const EdgeInsets.symmetric(vertical: 15)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: const Color(0xFFFCFCFD),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agreed Duration',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF344054),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _durationValueController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. 3',
                  prefixIcon: const Icon(
                    Icons.timelapse_rounded,
                    color: _primary,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFCFCFD),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdownField(
                label: 'Unit',
                value: _selectedDurationUnit,
                items: const ['days', 'weeks', 'months'],
                labelBuilder: (value) =>
                    value[0].toUpperCase() + value.substring(1),
                onChanged: (value) {
                  setState(() {
                    _selectedDurationUnit = value ?? 'months';
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'This will be saved as: ${_buildDurationString().isEmpty ? '-' : _buildDurationString()}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF8A8F98),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStructureEditor() {
    if (_selectedPaymentStructure == 'full_payment') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdownField(
            label: 'Payment Timing',
            value: _selectedFullPaymentTiming,
            items: const ['upfront', 'on_completion', '50_50', 'custom'],
            labelBuilder: (value) =>
                _displayLabel(_fullPaymentTimingLabels, value),
            onChanged: (value) {
              setState(() {
                _selectedFullPaymentTiming = value ?? 'upfront';
              });
            },
            prefixIcon: Icons.payments_outlined,
          ),
          if (_selectedFullPaymentTiming == 'custom') ...[
            const SizedBox(height: 12),
            _buildTextField(
              'Custom Payment Arrangement',
              _customFullPaymentController,
              'e.g. 30% upfront, 70% after final delivery',
              maxLines: 3,
              prefixIcon: Icons.edit_note_rounded,
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Milestones',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF344054),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Break the project into milestones and assign payment percentages.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF8A8F98),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_milestones.length, (index) {
          final milestone = _milestones[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7ECF2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Milestone ${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF344054),
                      ),
                    ),
                    const Spacer(),
                    if (_milestones.length > 1)
                      IconButton(
                        onPressed: () => _removeMilestone(index),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                        splashRadius: 18,
                      ),
                  ],
                ),
                _buildTextField(
                  'Work Milestone',
                  milestone.titleController,
                  'e.g. Wireframes approved',
                  prefixIcon: Icons.flag_outlined,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  'Payment Percentage',
                  milestone.percentageController,
                  'e.g. 30',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.percent_rounded,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  'Notes (Optional)',
                  milestone.noteController,
                  'e.g. Paid after client approval',
                  maxLines: 2,
                  prefixIcon: Icons.notes_outlined,
                ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: _addMilestone,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'Add Milestone',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _primary,
            side: BorderSide(color: _primary.withValues(alpha: 0.25)),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(
    String label,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE7ECF2)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: _primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF344054),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
    IconData? icon,
    bool loading = false,
  }) {
    final isGhost =
        backgroundColor != _primary &&
        backgroundColor != const Color(0xFF16A34A);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Icon(icon, size: 20),
        label: Text(
          label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        style:
            ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
              disabledForegroundColor: foregroundColor.withValues(alpha: 0.9),
              side: borderColor != null ? BorderSide(color: borderColor) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ).copyWith(
              overlayColor: WidgetStateProperty.all(
                isGhost
                    ? _primary.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
      ),
    );
  }
}

class _MilestoneItem {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController percentageController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  void dispose() {
    titleController.dispose();
    percentageController.dispose();
    noteController.dispose();
  }
}
