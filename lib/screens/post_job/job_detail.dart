import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/job_post_provider.dart';
import '../dashboard/dashboard.dart';
import 'job_roles.dart';
import 'job_drafts_screen.dart';

class PostNewJobJobDetail extends StatefulWidget {
  const PostNewJobJobDetail({super.key, this.restoreFromExistingDraft = true});

  final bool restoreFromExistingDraft;

  @override
  State<PostNewJobJobDetail> createState() => _PostNewJobJobDetailState();
}

class _PostNewJobJobDetailState extends State<PostNewJobJobDetail> {
  static const Color _primary = AppColors.primary;
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF16A34A);
  static const Color _warning = Color(0xFFF59E0B);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(
    text: '7',
  );

  String _experienceLevel = 'entry';
  String _durationUnit = 'days';
  DateTime? _deadline;
  bool _submitted = false;
  bool _savingDraft = false;
  bool _isHydratingDraft = false;
  bool _didBootstrapEmptyDraft = false;
  Timer? _autosaveTimer;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_scheduleAutosave);
    _descController.addListener(_scheduleAutosave);
    _durationController.addListener(_scheduleAutosave);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareDraftSession();
    });
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  bool get _hasDraftTriggerFields =>
      _titleController.text.trim().isNotEmpty ||
      _descController.text.trim().isNotEmpty;

  bool get _hasAnyDraftContent =>
      _titleController.text.trim().isNotEmpty ||
      _descController.text.trim().isNotEmpty ||
      _durationController.text.trim().isNotEmpty ||
      _deadline != null ||
      _experienceLevel != 'entry' ||
      _durationUnit != 'days';

  Future<void> _prepareDraftSession() async {
    if (widget.restoreFromExistingDraft) {
      await _restoreDraftIfAvailable();
      return;
    }

    _resetForm(notifyProvider: false);
  }

  Future<void> _bootstrapNewDraftShell(JobPostProvider provider) async {
    _didBootstrapEmptyDraft = true;
  }

  Future<void> _restoreDraftIfAvailable() async {
    final provider = context.read<JobPostProvider>();
    final draft = provider.draftJobData;
    final shouldRestore =
        (draft != null && draft.isNotEmpty) || provider.hasPersistedDraft;
    if (!shouldRestore) {
      await _bootstrapNewDraftShell(provider);
      return;
    }

    _isHydratingDraft = true;
    final Map<String, dynamic> data = (draft ?? <String, dynamic>{})
        .cast<String, dynamic>();
    final String title = (data['job_title'] ?? '').toString();
    final String description = (data['job_description'] ?? '').toString();
    final String experienceLevel = (data['experience_level'] ?? 'entry')
        .toString();
    final String estimatedDuration = (data['estimated_duration'] ?? '')
        .toString();
    final String? deadlineRaw = data['deadline']?.toString();

    int? parsedDurationValue;
    String parsedDurationUnit = 'days';
    if (estimatedDuration.isNotEmpty) {
      final parts = estimatedDuration.split(' ');
      if (parts.isNotEmpty) parsedDurationValue = int.tryParse(parts.first);
      if (parts.length > 1) parsedDurationUnit = parts[1].toLowerCase();
    } else if (data['working_days'] != null) {
      parsedDurationValue = int.tryParse('${data['working_days']}');
      parsedDurationUnit = 'days';
    }

    DateTime? parsedDeadline;
    if (deadlineRaw != null && deadlineRaw.isNotEmpty) {
      parsedDeadline = DateTime.tryParse(deadlineRaw);
    }

    if (!mounted) return;
    setState(() {
      _titleController.text = title;
      _descController.text = description;
      _experienceLevel =
          ['entry', 'intermediate', 'expert'].contains(experienceLevel)
          ? experienceLevel
          : 'entry';
      _durationController.text =
          parsedDurationValue?.toString() ?? _durationController.text;
      _durationUnit = ['days', 'weeks', 'months'].contains(parsedDurationUnit)
          ? parsedDurationUnit
          : 'days';
      _deadline = parsedDeadline;
    });
    _isHydratingDraft = false;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
      _scheduleAutosave();
    }
  }

  void _scheduleAutosave() {
    if (_isHydratingDraft) return;

    // Don't start autosaving until the user has entered
    // at least a title or description.
    if (!_hasDraftTriggerFields) return;

    _autosaveTimer?.cancel();

    _syncDraftToProvider();

    _autosaveTimer = Timer(const Duration(milliseconds: 1000), () async {
      await _saveDraftSilently();
    });
  }

  void _syncDraftToProvider({bool notify = false}) {
    final durationValue = int.tryParse(_durationController.text.trim());
    String? estimatedDuration;
    int? workingDays;

    if (durationValue != null && durationValue > 0) {
      estimatedDuration = '$durationValue $_durationUnit';
      switch (_durationUnit) {
        case 'weeks':
          workingDays = durationValue * 7;
          break;
        case 'months':
          workingDays = durationValue * 30;
          break;
        default:
          workingDays = durationValue;
      }
    }

    context.read<JobPostProvider>().setDraftJobData({
      'job_title': _titleController.text.trim(),
      'job_description': _descController.text.trim(),
      'estimated_duration': estimatedDuration,
      'working_days': workingDays,
      'experience_level': _experienceLevel,
      'deadline': _deadline == null
          ? null
          : '${_deadline!.year}-${_deadline!.month.toString().padLeft(2, '0')}-${_deadline!.day.toString().padLeft(2, '0')}',
      'status': 'draft',
      'draft_step': 'job_detail',
      'attachments_completed': false,
    }, notify: notify);
  }

  Future<void> _saveDraftSilently() async {
    if (_isHydratingDraft || !mounted) return;

    // Prevent creating/saving empty drafts.
    if (!_hasDraftTriggerFields) return;

    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;

    _syncDraftToProvider();
    await context.read<JobPostProvider>().saveDraftJob(token);
  }

  void _resetForm({bool notifyProvider = true}) {
    setState(() {
      _titleController.clear();
      _descController.clear();
      _durationController.text = '7';
      _experienceLevel = 'entry';
      _durationUnit = 'days';
      _deadline = null;
      _submitted = false;
    });
    if (notifyProvider) _syncDraftToProvider();
  }

  String get _deadlineDisplay {
    if (_deadline == null) return 'Select project deadline';
    return '${_deadline!.day.toString().padLeft(2, '0')}/${_deadline!.month.toString().padLeft(2, '0')}/${_deadline!.year}';
  }

  String _draftStatusTitle(JobPostProvider provider) {
    if (_savingDraft || provider.isDraftSaving) return 'Saving your draft';
    if (provider.lastDraftSavedAt != null) return 'Draft saved';
    return 'Draft in progress';
  }

  String _draftStatusSubtitle(JobPostProvider provider) {
    if (_savingDraft || provider.isDraftSaving) {
      return 'Your latest changes are being saved securely.';
    }
    if (provider.currentDraftJobPostId != null) {
      return 'This draft belongs to one job post record. You can continue later from Drafts.';
    }
    return 'Start filling the form and we will keep it as a draft for you.';
  }

  IconData _draftStatusIcon(JobPostProvider provider) {
    if (_savingDraft || provider.isDraftSaving) return Icons.sync_rounded;
    if (provider.lastDraftSavedAt != null) return Icons.check_circle_rounded;
    if (_hasAnyDraftContent) return Icons.edit_note_rounded;
    return Icons.description_outlined;
  }

  Color _draftStatusAccent(JobPostProvider provider) {
    if (_savingDraft || provider.isDraftSaving) return _warning;
    if (provider.lastDraftSavedAt != null) return _success;
    return _primary;
  }

  String? _validate() {
    if (_titleController.text.trim().isEmpty) return 'Title is required';
    if (_descController.text.trim().isEmpty) return 'Description is required';
    final descWordCount = _descController.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    if (descWordCount < 50)
      return 'Description must be at least 50 words (currently $descWordCount)';
    if (_durationController.text.trim().isEmpty)
      return 'Estimation duration is required';
    if (int.tryParse(_durationController.text.trim()) == null)
      return 'Estimation duration must be a number';
    if (_deadline == null) return 'Project deadline is required';
    return null;
  }

  Future<void> _deleteCurrentDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete this draft?'),
        content: const Text(
          'This removes only the currently opened draft. Other drafts stay available in the Drafts screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete draft'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _autosaveTimer?.cancel();
    final provider = context.read<JobPostProvider>();
    final token = context.read<AuthProvider>().token;
    final draftId = provider.currentDraftJobPostId;
    if (token != null &&
        token.isNotEmpty &&
        draftId != null &&
        draftId.isNotEmpty) {
      await provider.deleteDraftJob(token, draftId);
    } else {
      provider.clearDraft();
    }

    _resetForm(notifyProvider: false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Draft deleted successfully'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const JobDraftsScreen()),
    );
  }

  Future<void> _onNext() async {
    setState(() => _submitted = true);
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    _autosaveTimer?.cancel();
    setState(() => _savingDraft = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null || token.isEmpty) throw Exception('Missing auth token');
      _syncDraftToProvider();
      final saved = await context.read<JobPostProvider>().saveDraftJob(token);
      if (saved == null) {
        throw Exception(
          context.read<JobPostProvider>().error ?? 'Failed to save draft',
        );
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostNewJobRoles()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save draft: $e')));
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobPostProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepProgress(),
                  _buildDraftStatusCard(provider),
                  _buildSectionLabel('Title'),
                  _buildTextField(
                    controller: _titleController,
                    hint: 'e.g. Create a logo for my company',
                    prefixIcon: Icons.work_outline,
                  ),
                  _buildSectionLabel('Description'),
                  _buildTextField(
                    controller: _descController,
                    hint: 'Describe what you need...',
                    maxLines: 5,
                    prefixIcon: Icons.description_outlined,
                  ),
                  _buildSectionLabel('Experience Level'),
                  _buildDropdown<String>(
                    value: _experienceLevel,
                    items: const ['entry', 'intermediate', 'expert'],
                    labels: const ['Entry', 'Intermediate', 'Expert'],
                    prefixIcon: Icons.bar_chart_outlined,
                    onChanged: (v) {
                      setState(() => _experienceLevel = v!);
                      _scheduleAutosave();
                    },
                  ),
                  _buildSectionLabel('Estimation Duration'),
                  _buildEstimationDurationField(),
                  _buildInfoBanner(
                    'Estimated duration starts when a freelancer is hired',
                  ),
                  const SizedBox(height: 4),
                  _buildSectionLabel('Project Deadline'),
                  _buildDeadlinePicker(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _savingDraft ? null : _onNext,
                        icon: _savingDraft
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: Text(
                          _savingDraft ? 'Saving draft...' : 'Next: Roles',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgress() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: const [
          _StepPill(
            index: 1,
            label: 'Job detail',
            active: true,
            completed: false,
          ),
          SizedBox(width: 8),
          Expanded(child: Divider(color: _border, thickness: 1)),
          SizedBox(width: 8),
          _StepPill(index: 2, label: 'Role', active: false, completed: false),
          SizedBox(width: 8),
          Expanded(child: Divider(color: _border, thickness: 1)),
          SizedBox(width: 8),
          _StepPill(
            index: 3,
            label: 'Attachment',
            active: false,
            completed: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDraftStatusCard(JobPostProvider provider) {
    final accent = _draftStatusAccent(provider);
    final hasDraft =
        provider.currentDraftJobPostId != null ||
        provider.hasPersistedDraft ||
        (provider.draftJobData != null && provider.draftJobData!.isNotEmpty);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: (_savingDraft || provider.isDraftSaving)
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  )
                : Icon(_draftStatusIcon(provider), color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _draftStatusTitle(provider),
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _draftStatusSubtitle(provider),
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                if (hasDraft) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSoftChip(
                        icon: Icons.description_outlined,
                        label: provider.currentDraftJobPostId != null
                            ? 'Draft ready'
                            : 'Unsynced local draft',
                      ),
                      _buildSoftChip(
                        icon: Icons.layers_outlined,
                        label: 'Step 1 of 3',
                      ),
                      _buildSoftChip(
                        icon: Icons.save_outlined,
                        label: provider.lastDraftSavedAt != null
                            ? 'Auto-save enabled'
                            : 'Ready to save',
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const JobDraftsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      label: const Text('Open drafts'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: BorderSide(color: _primary.withOpacity(0.18)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: hasDraft || _hasAnyDraftContent
                          ? _deleteCurrentDraft
                          : null,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE11D48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text(
                        'Delete this draft',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoftChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _textDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _primary,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            top: -20,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(right: 24, top: 52, child: _buildDotGrid()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      'Post new job',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      'Job Detail',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotGrid() {
    return Column(
      children: List.generate(
        4,
        (row) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: List.generate(
              3,
              (col) => Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: _primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8, top: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: _textDark,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: _textDark, fontSize: 13.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: _primary, size: 20)
              : null,
          contentPadding: prefixIcon != null
              ? const EdgeInsets.symmetric(vertical: 17)
              : const EdgeInsets.all(16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required List<String> labels,
    required void Function(T?) onChanged,
    IconData? prefixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (prefixIcon != null)
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Icon(prefixIcon, color: _primary, size: 20),
            ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _primary,
                ),
                style: const TextStyle(color: _textDark, fontSize: 13.5),
                padding: EdgeInsets.only(
                  left: prefixIcon != null ? 10 : 16,
                  right: 6,
                ),
                items: items
                    .asMap()
                    .entries
                    .map(
                      (e) => DropdownMenuItem<T>(
                        value: e.value,
                        child: Text(labels[e.key]),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimationDurationField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Icon(Icons.schedule_outlined, color: _primary, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: _textDark, fontSize: 13.5),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
                hintText: '0',
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _durationUnit,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _primary,
                ),
                style: const TextStyle(
                  color: _primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                items: const [
                  DropdownMenuItem(value: 'days', child: Text('Days')),
                  DropdownMenuItem(value: 'weeks', child: Text('Weeks')),
                  DropdownMenuItem(value: 'months', child: Text('Months')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _durationUnit = value);
                    _scheduleAutosave();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlinePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4, left: 20, right: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: _submitted && _deadline == null
                ? const Color(0xFFFF5C5C)
                : _border,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Icon(
                Icons.calendar_today_outlined,
                color: _primary,
                size: 20,
              ),
            ),
            Expanded(
              child: Text(
                _deadlineDisplay,
                style: TextStyle(
                  color: _deadline == null
                      ? const Color(0xFF9CA3AF)
                      : _textDark,
                  fontSize: 13.5,
                  fontWeight: _deadline == null
                      ? FontWeight.w400
                      : FontWeight.w500,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Icon(
                Icons.chevron_right_rounded,
                color: _primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.index,
    required this.label,
    required this.active,
    required this.completed,
  });

  final int index;
  final String label;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    const primary = AppColors.primary;
    final Color bg = completed
        ? const Color(0xFFEAF8EE)
        : active
        ? primary.withOpacity(0.10)
        : const Color(0xFFF3F4F6);
    final Color fg = completed
        ? const Color(0xFF16A34A)
        : active
        ? primary
        : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
