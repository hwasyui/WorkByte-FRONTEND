import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/job_post_provider.dart';
import '../../../../providers/skill_provider.dart';
import '../../../../models/skill_model.dart';
import 'job_files.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data class for one draft role (held locally until Next is tapped)
// ─────────────────────────────────────────────────────────────────────────────
class _RoleDraft {
  String roleTitle;
  String roleDescription;
  String roleBudget;
  String budgetCurrency;
  String budgetType;
  int positionsAvailable;
  bool isRequired;
  // skill_id → { skill_name, is_required, importance_level }
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
  final String projectType; // 'individual' | 'team'
  const PostNewJobRoles({super.key, required this.projectType});

  @override
  State<PostNewJobRoles> createState() => _PostNewJobRolesState();
}

class _PostNewJobRolesState extends State<PostNewJobRoles> {
  static const Color _primary = AppColors.primary;
  static const Color _bg = Color(0xFFF9F9F9);

  final List<_RoleDraft> _roles = [];
  int? _expandedIndex; // which role card is open

  bool get _isIndividual => widget.projectType == 'individual';

  @override
  void initState() {
    super.initState();
    if (_isIndividual) {
      _roles.add(_RoleDraft());
    } else {
      _roles.add(_RoleDraft()); // ← add first role automatically for team too
    }
    _expandedIndex = 0; // ← auto-expand role 0 for both types

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token!;
      context.read<SkillProvider>().fetchAllSkills(token);
    });
  }

  // ── Validation ─────────────────────────────────────────────────────────────
  String? _validate() {
    if (_roles.isEmpty) return 'Add at least one role';
    for (int i = 0; i < _roles.length; i++) {
      if (!_roles[i].isValid) return 'Role ${i + 1} title is required';
    }
    return null;
  }

  // ── Save to provider & navigate ────────────────────────────────────────────
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
        'role_description': r.roleDescription.trim().isEmpty
            ? null
            : r.roleDescription.trim(),
        if (r.roleBudget.trim().isNotEmpty)
          'role_budget': double.tryParse(r.roleBudget.trim()),
        'budget_currency': r.budgetCurrency,
        'budget_type': r.budgetType,
        'positions_available': r.positionsAvailable,
        'is_required': r.isRequired,
        'display_order': e.key,
      };
    }).toList();

    provider.setDraftRoles(roleMaps);

    // Save skills per role
    for (int i = 0; i < _roles.length; i++) {
      final skillIds = _roles[i].skills.keys.toList();
      final skillNames = _roles[i].skills.values
          .map((v) => v['skill_name'] as String)
          .toList();
      provider.setDraftRoleSkills(i, skillIds, skillNames: skillNames);

      // Also store skill metadata (is_required, importance_level) for the API
      provider.setDraftRoleSkillMeta(i, _roles[i].skills);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostNewJobFiles()),
    );
  }

  // ── Add role (team only) ────────────────────────────────────────────────────
  void _addRole() {
    setState(() {
      _roles.add(_RoleDraft());
      _expandedIndex = _roles.length - 1;
    });
  }

  void _deleteRole(int index) {
    setState(() {
      _roles.removeAt(index);
      if (_expandedIndex == index)
        _expandedIndex = null;
      else if (_expandedIndex != null && _expandedIndex! > index) {
        _expandedIndex = _expandedIndex! - 1;
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
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
                        onTapHeader: () => setState(() {
                          _expandedIndex = _expandedIndex == e.key
                              ? null
                              : e.key;
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
      ),
    );
  }

  Widget _buildHeader() => Container(
    color: _primary,
    padding: const EdgeInsets.only(top: 23, bottom: 24),
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 29),
          child: Text(
            'Post new job',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 29),
          child: Text(
            _isIndividual ? 'Role & Skills' : 'Team Roles & Skills',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    ),
  );

  Widget _buildBottomBar() => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 12,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Next',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Role card — collapsible, fully self-contained form
// ─────────────────────────────────────────────────────────────────────────────
class _RoleCard extends StatefulWidget {
  final int index;
  final _RoleDraft draft;
  final bool isExpanded;
  final bool canDelete;
  final VoidCallback onTapHeader;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _RoleCard({
    super.key,
    required this.index,
    required this.draft,
    required this.isExpanded,
    required this.canDelete,
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
            widget.draft.positionsAvailable = int.tryParse(_posCtrl.text) ?? 1;
          });
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

  // ── Skill picker helpers ────────────────────────────────────────────────────
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

  void _updateSkillMeta(String skillId, String field, dynamic value) {
    setState(() {
      widget.draft.skills[skillId]?[field] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final hasSkills = d.skills.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header (always visible) ──────────────────────────────────
          InkWell(
            onTap: widget.onTapHeader,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primary.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.roleTitle.isEmpty ? 'Untitled Role' : d.roleTitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: d.roleTitle.isEmpty
                                ? const Color(0xFFB5B4B4)
                                : const Color(0xFF333333),
                          ),
                        ),
                        if (d.roleBudget.isNotEmpty || hasSkills)
                          const SizedBox(height: 3),
                        if (d.roleBudget.isNotEmpty)
                          Text(
                            '${d.budgetCurrency} ${d.roleBudget}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF7D7D7D),
                            ),
                          ),
                        if (hasSkills)
                          Text(
                            '${d.skills.length} skill${d.skills.length == 1 ? '' : 's'} selected',
                            style: const TextStyle(
                              fontSize: 10,
                              color: _primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.canDelete)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFFF5C5C),
                        size: 18,
                      ),
                      onPressed: widget.onDelete,
                    ),
                  Icon(
                    widget.isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFFB5B4B4),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded form ──────────────────────────────────────────────────
          if (widget.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: Color(0xFFF0F0F1)),
                  const SizedBox(height: 16),

                  // Role title
                  _label('Role Title *'),
                  _field(
                    controller: _titleCtrl,
                    hint: 'e.g. UI Designer, Backend Developer',
                  ),

                  // Description
                  _label('Description'),
                  _field(
                    controller: _descCtrl,
                    hint: 'Describe what this role will do...',
                    maxLines: 3,
                  ),

                  // Budget row: amount + currency + type
                  _label('Budget'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Currency dropdown
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFF0F0F1)),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: d.budgetCurrency,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF333333),
                            ),
                            items: const ['IDR', 'USD', 'EUR', 'SGD']
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => d.budgetCurrency = v!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Budget amount
                      Expanded(
                        child: _field(
                          controller: _budgetCtrl,
                          hint: 'Amount',
                          keyboardType: TextInputType.number,
                          bottomMargin: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Budget type
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFF0F0F1)),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: d.budgetType,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF333333),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'fixed',
                                child: Text('Fixed'),
                              ),
                              DropdownMenuItem(
                                value: 'negotiable',
                                child: Text('Negotiable'),
                              ),
                            ],
                            onChanged: (v) => setState(() => d.budgetType = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Positions + is_required
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Positions'),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFF0F0F1),
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _posCtrl,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF333333),
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                        hintText: '1',
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'pax',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF7D7D7D),
                                    ),
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
                                        : const Color(0xFFF0F0F1),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  color: d.isRequired
                                      ? _primary.withOpacity(0.07)
                                      : Colors.white,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      d.isRequired
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked,
                                      size: 16,
                                      color: d.isRequired
                                          ? _primary
                                          : const Color(0xFFB5B4B4),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      d.isRequired ? 'Yes' : 'No',
                                      style: TextStyle(
                                        fontSize: 12,
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

                  // ── Skills section ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label('Skills', noMargin: true),
                      TextButton.icon(
                        onPressed: () => setState(
                          () => _showSkillPicker = !_showSkillPicker,
                        ),
                        icon: Icon(
                          _showSkillPicker
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.add_rounded,
                          size: 16,
                          color: _primary,
                        ),
                        label: Text(
                          _showSkillPicker ? 'Close' : 'Add Skills',
                          style: const TextStyle(color: _primary, fontSize: 11),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Selected skill chips
                  if (d.skills.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: d.skills.entries.map((entry) {
                        final meta = entry.value;
                        final isReq = meta['is_required'] as bool? ?? true;
                        final level =
                            meta['importance_level'] as String? ?? 'required';
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5F5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // importance dropdown
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: level,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _primary,
                                    ),
                                    isDense: true,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'required',
                                        child: Text('Required'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'preferred',
                                        child: Text('Preferred'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'nice_to_have',
                                        child: Text('Nice to Have'),
                                      ),
                                    ],
                                    onChanged: (v) => _updateSkillMeta(
                                      entry.key,
                                      'importance_level',
                                      v,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                meta['skill_name'] as String,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // remove button
                              InkWell(
                                onTap: () {
                                  setState(() => d.skills.remove(entry.key));
                                  widget.onChanged();
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 12,
                                    color: _primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Skill picker
                  if (_showSkillPicker)
                    _SkillPicker(
                      selectedIds: d.skills.keys.toSet(),
                      searchController: _skillSearchCtrl,
                      onSearchChanged: _onSearchChanged,
                      onToggle: _toggleSkill,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String text, {bool noMargin = false}) => Padding(
    padding: EdgeInsets.only(bottom: 6, top: noMargin ? 0 : 0),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF7D7D7D),
        fontSize: 11,
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
  }) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFF0F0F1)),
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
    ),
    margin: EdgeInsets.only(bottom: bottomMargin),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB5B4B4), fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: InputBorder.none,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Skill picker widget
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
        border: Border.all(color: const Color(0xFFF0F0F1)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF9F9F9),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF0F0F1)),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
              decoration: const InputDecoration(
                hintText: 'Search skills...',
                hintStyle: TextStyle(color: Color(0xFFB5B4B4), fontSize: 12),
                prefixIcon: Icon(
                  Icons.search,
                  color: Color(0xFFB5B4B4),
                  size: 16,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Skills grid
          Consumer<SkillProvider>(
            builder: (_, provider, __) {
              // Show loader on first fetch OR while actively loading
              if (provider.isLoading ||
                  (provider.skills.isEmpty && provider.error == null)) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }

              if (provider.error != null) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    provider.error!,
                    style: const TextStyle(
                      color: Color(0xFFFF5C5C),
                      fontSize: 11,
                    ),
                  ),
                );
              }

              final list = provider.searchResults;

              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'No skills found',
                    style: TextStyle(color: Color(0xFFB5B4B4), fontSize: 11),
                  ),
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
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Colors.white,
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
                          fontSize: 11,
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primary.withOpacity(0.04),
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
