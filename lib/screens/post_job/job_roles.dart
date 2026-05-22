import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/job_post_provider.dart';
import '../../../../providers/skill_provider.dart';
import '../../../../models/skill_model.dart';
import 'job_files.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Currency helpers (module-level cache so it's shared across card instances)
// ─────────────────────────────────────────────────────────────────────────────
List<Map<String, String>>? _currencyCache;

Future<List<Map<String, String>>> _loadCurrencies() async {
  if (_currencyCache != null) return _currencyCache!;
  final res = await http.get(
    Uri.parse('https://restcountries.com/v3.1/all?fields=currencies'),
  );
  if (res.statusCode != 200) throw Exception('Failed to load currencies');
  final countries = jsonDecode(res.body) as List<dynamic>;
  final seen = <String>{};
  final result = <Map<String, String>>[];
  for (final c in countries) {
    final map = c['currencies'] as Map<String, dynamic>?;
    if (map == null) continue;
    for (final e in map.entries) {
      if (seen.contains(e.key)) continue;
      seen.add(e.key);
      final name =
          (e.value as Map<String, dynamic>)['name'] as String? ?? e.key;
      result.add({'code': e.key, 'name': name});
    }
  }
  result.sort((a, b) => a['code']!.compareTo(b['code']!));
  _currencyCache = result;
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// Data class for one draft role
// ─────────────────────────────────────────────────────────────────────────────
class _RoleDraft {
  String roleTitle;
  String roleDescription;
  String roleBudget;
  String budgetCurrency;
  String budgetType;
  int positionsAvailable;
  bool isRequired;
  Map<String, Map<String, dynamic>> skills;

  _RoleDraft({
    this.roleTitle = '',
    this.roleDescription = '',
    this.roleBudget = '',
    this.budgetCurrency = 'IDR',
    this.budgetType = 'fixed',
    this.positionsAvailable = 1,
    this.isRequired = true,
    Map<String, Map<String, dynamic>>? skills,
  }) : skills = skills ?? {};

  bool get isValid => roleTitle.trim().isNotEmpty;
}

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────
class PostNewJobRoles extends StatefulWidget {
  final String projectType;
  const PostNewJobRoles({super.key, required this.projectType});

  @override
  State<PostNewJobRoles> createState() => _PostNewJobRolesState();
}

class _PostNewJobRolesState extends State<PostNewJobRoles> {
  static const Color _primary = AppColors.primary;

  final List<_RoleDraft> _roles = [];
  int? _expandedIndex;

  bool get _isIndividual => widget.projectType == 'individual';

  @override
  void initState() {
    super.initState();
    _roles.add(_RoleDraft());
    _expandedIndex = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token!;
      context.read<SkillProvider>().fetchAllSkills(token);
    });
  }

  String? _validate() {
    if (_roles.isEmpty) return 'Add at least one role';
    for (int i = 0; i < _roles.length; i++) {
      if (!_roles[i].isValid) return 'Role ${i + 1} title is required';
    }
    return null;
  }

  void _onNext() {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    final provider = context.read<JobPostProvider>();
    final roleMaps = _roles.asMap().entries.map((e) {
      final r = e.value;
      return <String, dynamic>{
        'role_title': r.roleTitle.trim(),
        'role_description':
            r.roleDescription.trim().isEmpty ? null : r.roleDescription.trim(),
        if (r.roleBudget.trim().isNotEmpty)
          'role_budget': ThousandsSeparatorFormatter.parse(r.roleBudget.trim()),
        'budget_currency': r.budgetCurrency,
        'budget_type': r.budgetType,
        'positions_available': _isIndividual ? 1 : r.positionsAvailable,
        'is_required': _isIndividual ? true : r.isRequired,
        'display_order': e.key,
      };
    }).toList();
    provider.setDraftRoles(roleMaps);
    for (int i = 0; i < _roles.length; i++) {
      final skillIds = _roles[i].skills.keys.toList();
      final skillNames =
          _roles[i].skills.values.map((v) => v['skill_name'] as String).toList();
      provider.setDraftRoleSkills(i, skillIds, skillNames: skillNames);
      provider.setDraftRoleSkillMeta(i, _roles[i].skills);
    }
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const PostNewJobFiles()));
  }

  void _addRole() {
    setState(() {
      _roles.add(_RoleDraft());
      _expandedIndex = _roles.length - 1;
    });
  }

  void _deleteRole(int index) {
    setState(() {
      _roles.removeAt(index);
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else if (_expandedIndex != null && _expandedIndex! > index) {
        _expandedIndex = _expandedIndex! - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._roles.asMap().entries.map(
                    (e) => _RoleCard(
                      key: ValueKey(e.key),
                      index: e.key,
                      draft: e.value,
                      isExpanded: _expandedIndex == e.key,
                      canDelete: !_isIndividual,
                      isIndividual: _isIndividual,
                      onTapHeader: () => setState(() {
                        _expandedIndex =
                            _expandedIndex == e.key ? null : e.key;
                      }),
                      onDelete: () => _deleteRole(e.key),
                      onChanged: () => setState(() {}),
                    ),
                  ),
                  if (!_isIndividual) _AddRoleButton(onTap: _addRole),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
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
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
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
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      _isIndividual ? 'Role & Skills' : 'Team Roles & Skills',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x10000000), blurRadius: 12, offset: Offset(0, -4)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text(
            'Next',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role card
// ─────────────────────────────────────────────────────────────────────────────
class _RoleCard extends StatefulWidget {
  final int index;
  final _RoleDraft draft;
  final bool isExpanded;
  final bool canDelete;
  final bool isIndividual;
  final VoidCallback onTapHeader;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _RoleCard({
    super.key,
    required this.index,
    required this.draft,
    required this.isExpanded,
    required this.canDelete,
    required this.isIndividual,
    required this.onTapHeader,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  static const Color _primary = AppColors.primary;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _budgetCtrl;
  late final TextEditingController _posCtrl;
  final TextEditingController _skillSearchCtrl = TextEditingController();

  bool _showSkillPicker = false;

  // Currency picker state
  List<Map<String, String>>? _currencies;
  bool _loadingCurrencies = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.draft.roleTitle)
      ..addListener(() {
        widget.draft.roleTitle = _titleCtrl.text;
        widget.onChanged();
      });
    _descCtrl = TextEditingController(text: widget.draft.roleDescription)
      ..addListener(() => widget.draft.roleDescription = _descCtrl.text);
    _budgetCtrl = TextEditingController(text: widget.draft.roleBudget)
      ..addListener(() => widget.draft.roleBudget = _budgetCtrl.text);
    _posCtrl =
        TextEditingController(text: widget.draft.positionsAvailable.toString())
          ..addListener(() {
            widget.draft.positionsAvailable =
                int.tryParse(_posCtrl.text) ?? 1;
          });

    // Pre-load currencies in background
    _fetchCurrencies();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    _posCtrl.dispose();
    _skillSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrencies() async {
    if (_currencies != null || _loadingCurrencies) return;
    setState(() => _loadingCurrencies = true);
    try {
      final list = await _loadCurrencies();
      if (mounted) setState(() { _currencies = list; _loadingCurrencies = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCurrencies = false);
    }
  }

  Future<void> _pickCurrency() async {
    if (_currencies == null) {
      await _fetchCurrencies();
      if (_currencies == null) return;
    }
    if (!mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CurrencyPickerSheet(currencies: _currencies!),
    );
    if (picked != null && mounted) {
      setState(() => widget.draft.budgetCurrency = picked);
    }
  }

  void _onSearchChanged(String q) {
    final token = context.read<AuthProvider>().token!;
    context.read<SkillProvider>().searchSkills(token, q);
  }

  void _toggleSkill(SkillModel skill) {
    setState(() {
      if (widget.draft.skills.containsKey(skill.skillId)) {
        widget.draft.skills.remove(skill.skillId);
      } else {
        widget.draft.skills[skill.skillId] = {
          'skill_name': skill.skillName,
          'is_required': true,
          'importance_level': 'required',
        };
      }
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final hasSkills = d.skills.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
        border: Border.all(color: const Color(0xFFEEEFF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ─────────────────────────────────────────────────
          InkWell(
            onTap: widget.onTapHeader,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      d.roleTitle.isEmpty ? 'Untitled Role' : d.roleTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: d.roleTitle.isEmpty
                            ? const Color(0xFFB5B4B4)
                            : Colors.black87,
                      ),
                    ),
                  ),
                  if (widget.canDelete)
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFFF5C5C), size: 18),
                      onPressed: widget.onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    widget.isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _primary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded form ────────────────────────────────────────────────
          if (widget.isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFEEEFF4)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role Title
                  _label('Role Title *'),
                  _field(
                    controller: _titleCtrl,
                    hint: 'e.g. UI Designer, Backend Developer',
                    prefixIcon: Icons.work_outline,
                  ),

                  // Description
                  _label('Description'),
                  _field(
                    controller: _descCtrl,
                    hint: 'Describe what this role will do...',
                    maxLines: 4,
                    prefixIcon: Icons.description_outlined,
                  ),

                  // ── Budget ─────────────────────────────────────────────
                  _label('Budget Type'),
                  _buildBudgetTypePills(d),
                  const SizedBox(height: 14),

                  _label('Amount & Currency'),
                  _buildAmountCurrencyRow(d),
                  const SizedBox(height: 14),

                  // Positions + Required (hidden for individual)
                  if (!widget.isIndividual) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Positions'),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xFFE5E7EB)),
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 13),
                                      child: Icon(Icons.people_outline,
                                          color: _primary, size: 20),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _posCtrl,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF333333)),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          border: InputBorder.none,
                                          contentPadding:
                                              EdgeInsets.symmetric(
                                                  vertical: 13),
                                          hintText: '1',
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(right: 12),
                                      child: Text('pax',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFB5B4B4))),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Required'),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => d.isRequired = !d.isRequired),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: d.isRequired
                                          ? _primary
                                          : const Color(0xFFE5E7EB),
                                      width: d.isRequired ? 1.5 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    color: d.isRequired
                                        ? AppColors.secondary
                                        : Colors.white,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 13),
                                  child: Row(
                                    children: [
                                      Icon(
                                        d.isRequired
                                            ? Icons.check_circle_rounded
                                            : Icons.radio_button_unchecked,
                                        size: 18,
                                        color: d.isRequired
                                            ? _primary
                                            : const Color(0xFFB5B4B4),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        d.isRequired ? 'Yes' : 'No',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: d.isRequired
                                              ? _primary
                                              : const Color(0xFF7D7D7D),
                                          fontWeight: d.isRequired
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Skills header ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label('Skills', noMargin: true),
                      GestureDetector(
                        onTap: () => setState(
                            () => _showSkillPicker = !_showSkillPicker),
                        child: Row(
                          children: [
                            Icon(
                              _showSkillPicker
                                  ? Icons.remove_rounded
                                  : Icons.add_rounded,
                              size: 15,
                              color: _primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _showSkillPicker ? 'Close' : 'Add Skills',
                              style: const TextStyle(
                                color: _primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Selected skills chips ──────────────────────────────
                  if (hasSkills) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: d.skills.entries.map((entry) {
                        final meta = entry.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                meta['skill_name'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  setState(
                                      () => d.skills.remove(entry.key));
                                  widget.onChanged();
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: const Padding(
                                  padding: EdgeInsets.all(3),
                                  child: Icon(Icons.close_rounded,
                                      size: 12, color: _primary),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ] else ...[
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showSkillPicker = true),
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primary.withOpacity(0.35),
                          ),
                          color: AppColors.secondary.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],

                  // Skill picker
                  if (_showSkillPicker) ...[
                    const SizedBox(height: 10),
                    _SkillPicker(
                      selectedIds: d.skills.keys.toSet(),
                      searchController: _skillSearchCtrl,
                      onSearchChanged: _onSearchChanged,
                      onToggle: _toggleSkill,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Budget type pill row ───────────────────────────────────────────────────
  Widget _buildBudgetTypePills(_RoleDraft d) {
    const types = [('fixed', 'Fixed'), ('negotiable', 'Negotiable')];
    return Row(
      children: types.map((t) {
        final isSelected = d.budgetType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => d.budgetType = t.$1),
            child: Container(
              margin: t != types.last
                  ? const EdgeInsets.only(right: 8)
                  : null,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _primary : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? _primary : const Color(0xFFE5E7EB),
                ),
              ),
              child: Center(
                child: Text(
                  t.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Amount + currency input ────────────────────────────────────────────────
  Widget _buildAmountCurrencyRow(_RoleDraft d) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _budgetCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              inputFormatters: [ThousandsSeparatorFormatter()],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
              decoration: const InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                    fontSize: 14, color: Color(0xFF9CA3AF)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
              ),
            ),
          ),
          // Currency picker button
          GestureDetector(
            onTap: _loadingCurrencies ? null : _pickCurrency,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFDDD8FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_loadingCurrencies)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.primary),
                    )
                  else
                    Text(
                      d.budgetCurrency,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down,
                      size: 16, color: _primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, {bool noMargin = false}) => Padding(
        padding: EdgeInsets.only(bottom: 8, top: noMargin ? 0 : 0),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    double bottomMargin = 12,
    IconData? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      margin: EdgeInsets.only(bottom: bottomMargin),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFFB5B4B4), fontSize: 13),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: _primary, size: 20)
              : null,
          contentPadding: prefixIcon != null
              ? const EdgeInsets.symmetric(vertical: 14)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skill picker
// ─────────────────────────────────────────────────────────────────────────────
class _SkillPicker extends StatelessWidget {
  final Set<String> selectedIds;
  final TextEditingController searchController;
  final void Function(String) onSearchChanged;
  final void Function(SkillModel) onToggle;

  const _SkillPicker({
    required this.selectedIds,
    required this.searchController,
    required this.onSearchChanged,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF9F9F9),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
              decoration: const InputDecoration(
                hintText: 'Search skills...',
                hintStyle: TextStyle(color: Color(0xFFB5B4B4), fontSize: 13),
                prefixIcon:
                    Icon(Icons.search, color: Color(0xFFB5B4B4), size: 18),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Consumer<SkillProvider>(
            builder: (_, provider, __) {
              if (provider.isLoading ||
                  (provider.skills.isEmpty && provider.error == null)) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                );
              }
              if (provider.error != null) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(provider.error!,
                      style: const TextStyle(
                          color: Color(0xFFFF5C5C), fontSize: 12)),
                );
              }
              final list = provider.searchResults;
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No skills found',
                      style: TextStyle(
                          color: Color(0xFFB5B4B4), fontSize: 12)),
                );
              }
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: list.map((skill) {
                  final selected = selectedIds.contains(skill.skillId);
                  return GestureDetector(
                    onTap: () => onToggle(skill),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.secondary,
                        ),
                      ),
                      child: Text(
                        skill.skillName,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF555555),
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add role button
// ─────────────────────────────────────────────────────────────────────────────
class _AddRoleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddRoleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.secondary.withOpacity(0.3),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
            SizedBox(width: 6),
            Text(
              'Add Role',
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thousands separator formatter (same logic as in freelancer_profile)
// ─────────────────────────────────────────────────────────────────────────────
class ThousandsSeparatorFormatter extends TextInputFormatter {
  static final _intFmt = NumberFormat('#,##0', 'en');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String raw = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    final dotIndex = raw.indexOf('.');
    if (dotIndex != -1) {
      final afterDot =
          raw.substring(dotIndex + 1).replaceAll('.', '');
      final dec =
          afterDot.length > 2 ? afterDot.substring(0, 2) : afterDot;
      raw = '${raw.substring(0, dotIndex)}.$dec';
    }
    if (raw.isEmpty) return newValue.copyWith(text: '');
    final parts = raw.split('.');
    final intDigits = parts[0].replaceAll(',', '');
    final intFormatted =
        intDigits.isEmpty ? '0' : _intFmt.format(int.parse(intDigits));
    final formatted =
        parts.length > 1 ? '$intFormatted.${parts[1]}' : intFormatted;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static double? parse(String text) {
    final clean = text.replaceAll(',', '');
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Currency picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _CurrencyPickerSheet extends StatefulWidget {
  final List<Map<String, String>> currencies;
  const _CurrencyPickerSheet({required this.currencies});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<Map<String, String>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.currencies;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.currencies
          : widget.currencies
              .where((c) =>
                  c['code']!.toLowerCase().contains(q) ||
                  c['name']!.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Select Currency',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search currency code or name...',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: const Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(Icons.search,
                        size: 20, color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final c = _filtered[i];
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 44,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        c['code']!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    title: Text(c['name']!,
                        style: GoogleFonts.poppins(fontSize: 13)),
                    onTap: () => Navigator.pop(context, c['code']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
