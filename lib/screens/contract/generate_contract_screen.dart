import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../models/contract_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contract_provider.dart';
import '../../services/contract_service.dart';
import '../../widgets/app_toast.dart';
import '../workspace/workspace_detail.dart';

class GenerateContractScreen extends StatefulWidget {
  final String? contractId;
  final ContractModel? initialContract;

  /// Payload used to create the contract. Only set when [contractId] is null
  /// (no contract row exists yet).
  final Map<String, dynamic>? draftContractData;

  const GenerateContractScreen({
    super.key,
    required this.contractId,
    this.initialContract,
  }) : draftContractData = null;

  /// Opens the screen before any contract exists. Nothing is persisted until
  /// the client presses "Generate Contract PDF", which creates the contract,
  /// its terms and its PDF in a single request.
  const GenerateContractScreen.draft({
    super.key,
    required this.draftContractData,
  }) : contractId = null,
       initialContract = null;

  @override
  State<GenerateContractScreen> createState() => _GenerateContractScreenState();
}

class _GenerateContractScreenState extends State<GenerateContractScreen> {
  static const Color _primary = AppColors.primary;

  static const EdgeInsets _fieldPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 14,
  );

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

  /// Null until the contract row actually exists on the backend, which only
  /// happens once the client generates the contract.
  String? _contractId;

  /// Everything printed on the PDF is frozen once the contract exists, and the
  /// PDF is never re-rendered, so the form is create-only.
  bool get _isCreated => _contractId != null;

  bool _loading = true;
  bool _generating = false;
  bool _sending = false;
  String? _error;

  late TextEditingController _contractTitleController;
  late TextEditingController _roleTitleController;
  late TextEditingController _agreedBudgetController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _confidentialityTextController;
  late TextEditingController _additionalClausesController;
  late TextEditingController _revisionRoundsController;
  late TextEditingController _latePaymentPenaltyController;

  final TextEditingController _durationValueController =
      TextEditingController();
  final TextEditingController _customFullPaymentController =
      TextEditingController();

  /// Locked to the job role's currency — the proposal has no currency of its
  /// own, so letting the client pick one could turn a 5,000,000 IDR bid into a
  /// 5,000,000 USD contract.
  String _budgetCurrency = 'IDR';

  /// The date the contract starts, carried from the accepted bid before the
  /// contract exists and read off the contract afterwards. Frozen either way,
  /// so the derived end date never drifts.
  String? _startDate;

  /// A freelancer may bid without proposing a duration. Only when they did is
  /// the client held to it.
  bool _durationLockedByProposal = false;

  /// The duration exactly as the proposal (or the contract) spells it. The
  /// backend compares it to `proposed_duration` as a literal string, and the
  /// bid form writes "1 month" but "2 months", so rebuilding the text from the
  /// parsed number and unit would submit "1 months" and be rejected as a
  /// locked-field mismatch.
  String? _lockedDurationText;

  /// The budget exactly as the proposal carried it. proposed_budget is
  /// numeric(12,2) and the bid form accepts two decimals, so re-parsing the
  /// rounded text shown in the field would submit 5000001 for a 5000000.50 bid
  /// and be rejected as a locked-field mismatch.
  double? _lockedBudget;

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
    _contractId = widget.contractId;
    _contractTitleController = TextEditingController();
    _roleTitleController = TextEditingController();
    _agreedBudgetController = TextEditingController();
    _startDateController = TextEditingController();
    _endDateController = TextEditingController();
    _confidentialityTextController = TextEditingController();
    _additionalClausesController = TextEditingController();
    _revisionRoundsController = TextEditingController(
      text: _revisionRounds.toString(),
    );
    _latePaymentPenaltyController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContract();
    });
  }

  @override
  void dispose() {
    _contractTitleController.dispose();
    _roleTitleController.dispose();
    _agreedBudgetController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _confidentialityTextController.dispose();
    _additionalClausesController.dispose();
    _revisionRoundsController.dispose();
    _latePaymentPenaltyController.dispose();
    _durationValueController.dispose();
    _customFullPaymentController.dispose();

    for (final m in _milestones) {
      m.dispose();
    }

    super.dispose();
  }

  Future<void> _loadContract() async {
    if (_contractId == null) {
      _prefillFromDraft();
      setState(() => _loading = false);
      return;
    }

    final token = context.read<AuthProvider>().token!;
    final contractProvider = context.read<ContractProvider>();

    try {
      setState(() => _loading = true);
      await contractProvider.fetchContractById(token, _contractId!);

      if (!mounted) return;

      final loaded = contractProvider.currentContract;
      if (loaded != null) {
        await _populateFromContract(token, loaded);
      }

      if (!mounted) return;
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

  /// Fills the form from a contract that already exists. Everything shown is
  /// frozen at this point, so this is a display of the agreement rather than
  /// an editable starting point.
  Future<void> _populateFromContract(String token, ContractModel contract) async {
    _contract = contract;
    _contractId = contract.contractId;

    _contractTitleController.text = contract.contractTitle;
    _roleTitleController.text = contract.roleTitle;
    _lockedBudget = contract.agreedBudget;
    _agreedBudgetController.text = _formatBudget(contract.agreedBudget);

    _budgetCurrency = contract.budgetCurrency.isNotEmpty
        ? contract.budgetCurrency
        : 'IDR';

    _selectedPaymentStructure = contract.paymentStructure.isNotEmpty
        ? contract.paymentStructure
        : 'full_payment';

    _startDate = contract.startDate;

    _lockedDurationText = contract.agreedDuration;
    _hydrateDuration(contract.agreedDuration ?? '');

    // The stored end date can legitimately differ from the derived one: an
    // arbitration extension moves it while the PDF keeps the deadline
    // originally agreed. Show what the contract actually says.
    _endDateController.text = contract.endDate ?? '';

    await _hydrateContractTerms(token);
  }

  void _prefillFromDraft() {
    final draft = widget.draftContractData ?? const <String, dynamic>{};

    _contractTitleController.text = draft['contract_title'] as String? ?? '';
    _roleTitleController.text = draft['role_title'] as String? ?? '';

    final budget = (draft['agreed_budget'] as num?)?.toDouble();
    _lockedBudget = budget;
    _agreedBudgetController.text = budget == null ? '' : _formatBudget(budget);

    final currency = draft['budget_currency'] as String?;
    if (currency != null && currency.isNotEmpty) {
      _budgetCurrency = currency;
    }

    final paymentStructure = draft['payment_structure'] as String?;
    if (paymentStructure != null && paymentStructure.isNotEmpty) {
      _selectedPaymentStructure = paymentStructure;
    }

    _startDate = draft['start_date'] as String?;

    final proposedDuration = (draft['proposed_duration'] as String?)?.trim();
    _durationLockedByProposal =
        proposedDuration != null && proposedDuration.isNotEmpty;
    if (_durationLockedByProposal) {
      _lockedDurationText = proposedDuration;
      _hydrateDuration(proposedDuration!);
    }

    _recomputeEndDate();
  }

  /// The end date follows from the start date and the agreed duration, so it is
  /// shown rather than asked for. The duration is fixed by the accepted
  /// proposal, and choosing an end date separately let a contract read
  /// "3 weeks" beside a date three months out - both of which are printed on
  /// the PDF.
  ///
  /// Mirrors _derive_end_date on the backend, which is what actually gets
  /// saved; this only keeps the field honest while the form is open. Months are
  /// added calendrically, so 31 Aug + 1 month is 30 Sep rather than slipping
  /// into October.
  void _recomputeEndDate() {
    final start = DateTime.tryParse(_startDate ?? '');
    final amount = int.tryParse(_durationValueController.text.trim());

    if (start == null || amount == null || amount <= 0) {
      _endDateController.text = '';
      return;
    }

    final DateTime end;
    switch (_selectedDurationUnit) {
      case 'days':
        end = start.add(Duration(days: amount));
        break;
      case 'weeks':
        end = start.add(Duration(days: amount * 7));
        break;
      default:
        final rawMonth = start.month + amount;
        final year = start.year + ((rawMonth - 1) ~/ 12);
        final month = ((rawMonth - 1) % 12) + 1;
        final lastDayOfMonth = DateTime(year, month + 1, 0).day;
        end = DateTime(
          year,
          month,
          start.day < lastDayOfMonth ? start.day : lastDayOfMonth,
        );
    }

    _endDateController.text = end.toIso8601String().split('T').first;
  }

  Future<void> _hydrateContractTerms(String token) async {
    try {
      final data = await context.read<ContractProvider>().fetchGenerationData(
        token,
        _contractId!,
      );
      final terms =
          (data['contract_terms'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      if (terms.isEmpty || !mounted) return;

      final terminationNotice = terms['termination_notice'];
      if (terminationNotice != null) {
        _selectedTerminationNotice = terminationNotice.toString();
      }

      final disputeResolution = terms['dispute_resolution'] as String?;
      if (disputeResolution != null && disputeResolution.isNotEmpty) {
        _selectedDisputeResolution = disputeResolution;
      }

      _confidentiality = terms['confidentiality'] as bool? ?? false;
      _confidentialityTextController.text =
          terms['confidentiality_text'] as String? ?? '';

      final penalty = (terms['late_payment_penalty'] as num?)?.toDouble();
      _latepaymentPenalty = penalty != null && penalty > 0;
      if (_latepaymentPenalty) {
        _latePaymentPenaltyController.text = penalty!.toStringAsFixed(
          penalty % 1 == 0 ? 0 : 2,
        );
      }

      final revisionRounds = terms['revision_rounds'];
      if (revisionRounds != null) {
        _revisionRounds = (revisionRounds as num).toInt();
        _revisionRoundsController.text = _revisionRounds.toString();
      }

      _additionalClausesController.text =
          terms['additional_clauses'] as String? ?? '';

      _hydratePaymentSchedule(terms['payment_schedule'] as String? ?? '');
    } catch (e) {
      debugPrint('Failed to hydrate contract terms: $e');
    }
  }

  void _hydratePaymentSchedule(String scheduleText) {
    if (scheduleText.trim().isEmpty) return;

    if (_selectedPaymentStructure == 'milestone_based') {
      final lines = scheduleText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.isEmpty) return;

      // The note is the trailing parenthesised run, not everything between the
      // first '(' and the last one: a greedy group swallows a title like
      // "Wireframes (v2)" along with the percentage that follows it.
      final lineRegex = RegExp(
        r'^Milestone\s+\d+\s*:\s*(.+?)(?:\s*-\s*([\d.]+)%\s*payment)?(?:\s*\(([^()]*)\))?$',
      );
      final parsed = <_MilestoneItem>[];
      for (final line in lines) {
        final match = lineRegex.firstMatch(line);
        final item = _MilestoneItem();
        if (match != null) {
          final title = match.group(1)?.trim() ?? '';
          item.titleController.text = title == 'Unnamed milestone'
              ? ''
              : title;
          item.percentageController.text = match.group(2)?.trim() ?? '';
          item.noteController.text = match.group(3)?.trim() ?? '';
        } else {
          item.titleController.text = line;
        }
        parsed.add(item);
      }

      for (final m in _milestones) {
        m.dispose();
      }
      _milestones
        ..clear()
        ..addAll(parsed);
      return;
    }

    final trimmed = scheduleText.trim();
    final matchedEntry = _fullPaymentTimingLabels.entries
        .where((e) => e.key != 'custom' && e.value == trimmed)
        .toList();

    if (matchedEntry.isNotEmpty) {
      _selectedFullPaymentTiming = matchedEntry.first.key;
    } else {
      _selectedFullPaymentTiming = 'custom';
      _customFullPaymentController.text = trimmed;
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

  /// Shows the two decimals the column actually stores, without printing ".00"
  /// on the whole amounts that make up almost every bid.
  String _formatBudget(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  String _buildDurationString() {
    // Locked durations go back verbatim: the number and unit are only parsed
    // out of them to drive the end-date display, and reassembling them would
    // change "1 month" into "1 months".
    final locked = _lockedDurationText?.trim();
    if (locked != null && locked.isNotEmpty) return locked;

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

    if ((total - 100.0).abs() > 0.01) {
      _showError('Milestone payment percentages must add up to 100%');
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
    AppToast.error(message);
  }

  /// The `terms` half of the create payload. `end_date` is omitted because the
  /// backend derives it from the start date and the duration, and delivery
  /// options are omitted because sending is its own endpoint now.
  Map<String, dynamic> _buildTermsData() {
    return {
      'agreed_duration': _buildDurationString(),
      'termination_notice':
          int.tryParse(_selectedTerminationNotice ?? '30') ?? 30,
      'governing_law': 'Indonesian Law',
      'confidentiality': _confidentiality,
      'confidentiality_text': _confidentialityTextController.text.trim(),
      if (_latepaymentPenalty)
        'late_payment_penalty':
            double.tryParse(_latePaymentPenaltyController.text.trim()),
      'dispute_resolution': _selectedDisputeResolution ?? 'negotiation',
      'revision_rounds': int.tryParse(_revisionRoundsController.text) ?? 2,
      'additional_clauses': _additionalClausesController.text.trim(),
      'payment_schedule': _buildPaymentScheduleString(),
    };
  }

  bool _validateBeforeGenerate() {
    if ((_startDate ?? '').isEmpty) {
      _showError('Please pick a start date');
      return false;
    }

    if (_durationValueController.text.trim().isEmpty) {
      _showError('Please enter the agreed duration');
      return false;
    }

    if (_selectedPaymentStructure == 'full_payment' &&
        _selectedFullPaymentTiming == 'custom' &&
        _customFullPaymentController.text.trim().isEmpty) {
      _showError('Please describe the full payment schedule');
      return false;
    }

    if (_latepaymentPenalty) {
      final penalty = double.tryParse(
        _latePaymentPenaltyController.text.trim(),
      );
      if (penalty == null || penalty <= 0) {
        _showError('Please enter a valid late payment penalty percentage');
        return false;
      }
    }

    return _validateMilestones();
  }

  /// Creates the contract, its terms and its PDF in a single request. A failure
  /// persists nothing, so the form is left untouched for the client to correct
  /// and submit again.
  Future<void> _generateContract() async {
    if (_isCreated || widget.draftContractData == null) return;
    if (!_validateBeforeGenerate()) return;

    // Prefer the proposal's own number over the text in the field: the field is
    // a rounded display of it, and the backend compares the two to two decimals.
    final agreedBudget =
        _lockedBudget ??
        double.tryParse(_agreedBudgetController.text.replaceAll(',', ''));
    if (agreedBudget == null) {
      _showError('Please enter a valid budget amount');
      return;
    }

    final token = context.read<AuthProvider>().token!;
    final contractProvider = context.read<ContractProvider>();
    final draft = widget.draftContractData!;

    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final created = await contractProvider.createContract(token, {
        'job_post_id': draft['job_post_id'],
        'job_role_id': draft['job_role_id'],
        'proposal_id': draft['proposal_id'],
        'freelancer_id': draft['freelancer_id'],
        'client_id': draft['client_id'],
        'contract_title': _contractTitleController.text.trim(),
        'role_title': _roleTitleController.text.trim(),
        'agreed_budget': agreedBudget,
        'budget_currency': _budgetCurrency,
        'payment_structure': _selectedPaymentStructure,
        if (_startDate != null) 'start_date': _startDate,
        'terms': _buildTermsData(),
      });

      if (!mounted) return;

      setState(() {
        _contract = created;
        _contractId = created.contractId;
        _endDateController.text = created.endDate ?? _endDateController.text;
        _generating = false;
      });

      AppToast.success('Contract generated successfully!');
    } on ContractServiceException catch (e) {
      if (!mounted) return;

      // The unique constraint on contract.proposal_id is the authoritative
      // duplicate check, and it closes the cross-device race a client-side
      // lookup cannot.
      if (e.isDuplicate) {
        await _adoptExistingContract(token, draft['proposal_id'] as String?);
        return;
      }

      setState(() {
        _error = _createErrorMessage(e);
        _generating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _generating = false;
      });
    }
  }

  String _createErrorMessage(ContractServiceException e) {
    if (e.blockedBy == 'locked_field' && e.field != null) {
      final expected = e.expected;
      return expected == null
          ? e.message
          : '${e.message} (${e.field} must be $expected)';
    }
    return e.message;
  }

  /// A 409 means another session already contracted this bid. There is no
  /// partial state to resume, so switch the screen over to the contract that
  /// won.
  Future<void> _adoptExistingContract(String token, String? proposalId) async {
    final contractProvider = context.read<ContractProvider>();

    final existing = proposalId == null
        ? null
        : await contractProvider.fetchContractByProposal(token, proposalId);

    if (!mounted) return;

    if (existing == null) {
      setState(() {
        _error = 'A contract already exists for this bid.';
        _generating = false;
      });
      return;
    }

    // Show the terms that were actually agreed, not the ones typed into this
    // form and rejected.
    await _populateFromContract(token, existing);

    if (!mounted) return;
    setState(() => _generating = false);

    AppToast.info('This bid already has a contract.');
  }

  Future<void> _openContractPdf() async {
    if (_contractId == null ||
        _contract?.contractPdfUrl == null ||
        _contract!.contractPdfUrl!.isEmpty) {
      AppToast.error('No PDF available');
      return;
    }

    final token = context.read<AuthProvider>().token!;
    final contractProvider = context.read<ContractProvider>();

    try {
      final pdfUrl = await contractProvider.fetchPdfUrl(token, _contractId!);

      final response = await http.get(
        Uri.parse(pdfUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF');
      }

      final fileName = 'contract_$_contractId.pdf';

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Contract PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: response.bodyBytes,
      );

      if (!mounted) return;

      if (savedPath == null) return;

      AppToast.success('Contract saved successfully');
    } catch (e) {
      AppToast.error('Failed to download PDF: $e');
    }
  }

  /// Delivery only — the stored PDF is attached to a DM as-is, so this can be
  /// repeated to send the same document again.
  Future<void> _sendToFreelancer() async {
    if (_contractId == null || _contract == null) {
      _showError('Contract data not available');
      return;
    }

    final token = context.read<AuthProvider>().token!;
    final contractProvider = context.read<ContractProvider>();

    setState(() => _sending = true);

    final sent = await contractProvider.sendContract(token, _contractId!);

    if (!mounted) return;

    setState(() {
      _sending = false;
      if (sent != null) _contract = sent;
    });

    if (sent == null) {
      AppToast.error(contractProvider.error ?? 'Failed to send contract');
      return;
    }

    AppToast.success('Contract sent to freelancer successfully!');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            WorkspaceDetailScreen(contract: sent, viewerRole: 'client'),
      ),
    );
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
                  if (_contract != null || _contractId == null) ...[
                    _buildSectionCard(
                      title: 'Agreement Details',
                      subtitle: 'Basic information for the contract agreement.',
                      icon: Icons.handshake_outlined,
                      children: [
                        _buildTextField(
                          'Contract Title',
                          _contractTitleController,
                          'e.g. Website Development Agreement',
                          readOnly: _isCreated,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          'Role Title',
                          _roleTitleController,
                          'e.g. Frontend Developer',
                          readOnly: true,
                          helper: 'Set by the job role this bid was made on.',
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                'Agreed Budget',
                                _agreedBudgetController,
                                'e.g. 5000000',
                                readOnly: true,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                helper: 'Matches the accepted bid.',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: _buildCurrencyLabel()),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildDropdownField(
                          label: 'Payment Structure',
                          value: _selectedPaymentStructure,
                          items: const ['full_payment', 'milestone_based'],
                          labelBuilder: (value) =>
                              _displayLabel(_paymentStructureLabels, value),
                          onChanged: _isCreated
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedPaymentStructure =
                                        value ?? 'full_payment';
                                  });
                                },
                          prefixIcon: Icons.account_balance_wallet_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Contract Terms',
                      subtitle:
                          'Set the duration and legal handling terms. The end '
                          'date follows from them.',
                      icon: Icons.rule_folder_outlined,
                      children: [
                        _buildStartDateField(),
                        const SizedBox(height: 14),
                        _buildDurationField(),
                        const SizedBox(height: 14),
                        _buildEndDateField(),
                        const SizedBox(height: 14),
                        _buildDropdownField(
                          label: 'Termination Notice',
                          value: _selectedTerminationNotice,
                          items: const ['7', '14', '30'],
                          labelBuilder: (value) => '$value days',
                          onChanged: _isCreated
                              ? null
                              : (value) {
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
                          onChanged: _isCreated
                              ? null
                              : (value) {
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
                          _isCreated
                              ? null
                              : (value) => setState(
                                  () => _confidentiality = value ?? false,
                                ),
                        ),
                        if (_confidentiality) ...[
                          const SizedBox(height: 12),
                          _buildTextField(
                            'Confidentiality Details',
                            _confidentialityTextController,
                            'Describe what information must remain confidential...',
                            maxLines: 3,
                            readOnly: _isCreated,
                            prefixIcon: Icons.lock_outline_rounded,
                          ),
                        ],
                        const SizedBox(height: 14),
                        _buildCheckboxTile(
                          'Apply late payment penalty',
                          _latepaymentPenalty,
                          _isCreated
                              ? null
                              : (value) => setState(
                                  () => _latepaymentPenalty = value ?? false,
                                ),
                        ),
                        if (_latepaymentPenalty) ...[
                          const SizedBox(height: 12),
                          _buildTextField(
                            'Penalty Percentage',
                            _latePaymentPenaltyController,
                            'e.g. 5 (as % of the agreed budget per late period)',
                            readOnly: _isCreated,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            prefixIcon: Icons.percent_rounded,
                          ),
                        ],
                        const SizedBox(height: 14),
                        _buildTextField(
                          'Revision Rounds',
                          _revisionRoundsController,
                          'e.g. 2',
                          readOnly: _isCreated,
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
                          readOnly: _isCreated,
                          prefixIcon: Icons.notes_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (_isCreated) ...[
                      _buildActionButton(
                        onPressed: _openContractPdf,
                        icon: Icons.download_outlined,
                        label: 'Download Generated PDF',
                        backgroundColor: const Color(0xFFEEF6FF),
                        foregroundColor: const Color(0xFF2563EB),
                        borderColor: const Color(0xFFD9E8FF),
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        onPressed: _sending ? null : _sendToFreelancer,
                        icon: _sending ? null : Icons.send_outlined,
                        label: 'Send to Freelancer',
                        loading: _sending,
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                      ),
                    ] else
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
                  _isCreated ? 'Contract issued' : 'Set up contract terms',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isCreated
                      ? 'The PDF has been generated and these terms are now fixed. To agree different terms, cancel this contract and create a new one.'
                      : 'Nothing is saved yet — the contract, its terms and its PDF are created together once you press "Generate Contract PDF".',
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
    bool readOnly = false,
    bool? locked,
    Widget? suffixIcon,
    String? helper,
    Function(String)? onChanged,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    // `readOnly` only says the keyboard cannot edit the field. A field filled by
    // a picker is still the client's to change, so the greyed-out padlock
    // treatment follows `locked` — which defaults to `readOnly` because most
    // read-only fields here really are fixed by the bid.
    final isLocked = locked ?? readOnly;

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
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isLocked ? const Color(0xFF475467) : const Color(0xFF101828),
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
            suffixIcon:
                suffixIcon ??
                (isLocked
                    ? const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF98A2B3),
                        size: 18,
                      )
                    : null),
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
              borderSide: BorderSide(
                color: isLocked ? const Color(0xFFE4E7EC) : _primary,
                width: isLocked ? 1 : 1.5,
              ),
            ),
            contentPadding: _fieldPadding,
            filled: true,
            fillColor: isLocked
                ? const Color(0xFFF2F4F7)
                : const Color(0xFFFCFCFD),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: const Color(0xFF8A8F98),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  /// Currency is fixed by the job role — the proposal has no currency of its
  /// own — so it is shown rather than picked.
  Widget _buildCurrencyLabel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currency',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF344054),
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 50,
          alignment: Alignment.centerLeft,
          padding: _fieldPadding.copyWith(top: 0, bottom: 0),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E7EC)),
          ),
          child: Text(
            _budgetCurrency,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475467),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "The role's currency.",
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            color: const Color(0xFF8A8F98),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// The one date the client actually picks. Everything else on the timeline
  /// (the end date, and the backend's own _derive_end_date) hangs off it.
  Widget _buildStartDateField() {
    _startDateController.text = _startDate ?? '';

    return GestureDetector(
      onTap: _isCreated ? null : _pickStartDate,
      child: AbsorbPointer(
        child: _buildTextField(
          'Start Date',
          _startDateController,
          'Pick when the work begins',
          // Read-only against the keyboard, but the picker still owns it —
          // only a created contract actually freezes the date.
          readOnly: true,
          locked: _isCreated,
          suffixIcon: _isCreated
              ? null
              : const Icon(
                  Icons.edit_calendar_outlined,
                  color: _primary,
                  size: 20,
                ),
          helper: _isCreated
              ? null
              : 'Tap to choose. The end date updates automatically.',
          prefixIcon: Icons.event_available_outlined,
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(_startDate ?? '');
    final firstDate = DateTime(now.year - 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;

    setState(() {
      _startDate = picked.toIso8601String().split('T').first;
      _startDateController.text = _startDate!;
      _recomputeEndDate();
    });
  }

  /// Derived from the start date and the duration rather than collected, so
  /// the contract can never print a duration that disagrees with its deadline.
  Widget _buildEndDateField() {
    final duration = _buildDurationString();
    final caption = _startDate == null
        ? 'Derived from the start date and the agreed duration.'
        : duration.isEmpty
        ? 'Starts $_startDate. Set a duration to see the end date.'
        : 'Starts $_startDate + $duration.';

    return _buildTextField(
      'End Date',
      _endDateController,
      'Set a duration to see the end date',
      readOnly: true,
      helper: caption,
      prefixIcon: Icons.calendar_today_outlined,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String Function(String) labelBuilder,
    required Function(String?)? onChanged,
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
          borderRadius: BorderRadius.circular(14),
          dropdownColor: Colors.white,
          elevation: 3,
          menuMaxHeight: 320,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF101828),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    labelBuilder(item),
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
              borderSide: BorderSide(
                color: onChanged == null ? const Color(0xFFE4E7EC) : _primary,
                width: onChanged == null ? 1 : 1.5,
              ),
            ),
            contentPadding: _fieldPadding,
            filled: true,
            fillColor: onChanged == null
                ? const Color(0xFFF2F4F7)
                : const Color(0xFFFCFCFD),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationField() {
    // Locked to the accepted proposal whenever the freelancer bid one, and
    // always locked once the contract exists.
    final locked = _durationLockedByProposal || _isCreated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                'Duration',
                _durationValueController,
                'e.g. 3',
                readOnly: locked,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.timelapse_rounded,
                onChanged: (_) => setState(_recomputeEndDate),
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
                onChanged: locked
                    ? null
                    : (value) {
                        setState(() {
                          _selectedDurationUnit = value ?? 'months';
                          _recomputeEndDate();
                        });
                      },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          locked
              ? 'Agreed in the accepted bid: '
                    '${_buildDurationString().isEmpty ? '-' : _buildDurationString()}'
              : 'This will be saved as: '
                    '${_buildDurationString().isEmpty ? '-' : _buildDurationString()}',
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
            onChanged: _isCreated
                ? null
                : (value) {
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
              readOnly: _isCreated,
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
                    if (_milestones.length > 1 && !_isCreated)
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
                  readOnly: _isCreated,
                  prefixIcon: Icons.flag_outlined,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  'Payment Percentage',
                  milestone.percentageController,
                  'e.g. 30',
                  readOnly: _isCreated,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  prefixIcon: Icons.percent_rounded,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  'Notes (Optional)',
                  milestone.noteController,
                  'e.g. Paid after client approval',
                  maxLines: 2,
                  readOnly: _isCreated,
                  prefixIcon: Icons.notes_outlined,
                ),
              ],
            ),
          );
        }),
        if (!_isCreated)
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
    Function(bool?)? onChanged,
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
