import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/skill_provider.dart';
import '../providers/profile_provider.dart';
import '../models/skill_model.dart';

class AddSkillWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const AddSkillWidget({Key? key, required this.onSave}) : super(key: key);

  @override
  State<AddSkillWidget> createState() => _AddSkillWidgetState();
}

class _AddSkillWidgetState extends State<AddSkillWidget> {
  final _searchCtrl = TextEditingController();
  SkillModel? _selected;
  String? _proficiency;
  String? _newSkillCategory;
  bool _isSubmitting = false;
  bool _isCreating = false;
  bool _showSuggestions = false;
  bool _showCategoryPicker = false;
  String _pendingNewSkillName = '';

  static const _levels = ['Beginner', 'Intermediate', 'Advanced'];
  static const _categories = [
    ('hard_skill', 'Hard Skill'),
    ('tool', 'Tool'),
    ('soft_skill', 'Soft Skill'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token!;
      context.read<SkillProvider>().fetchAllSkills(token);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    final token = context.read<AuthProvider>().token!;
    context.read<SkillProvider>().searchSkills(token, q);
    setState(() {
      _showSuggestions = q.trim().isNotEmpty;
      if (_selected != null &&
          _selected!.skillName.toLowerCase() != q.toLowerCase()) {
        _selected = null;
      }
    });
  }

  void _select(SkillModel skill) {
    setState(() {
      _selected = skill;
      _showSuggestions = false;
      _searchCtrl.text = skill.skillName;
    });
  }

  void _promptCategoryThenCreate(String name) {
    setState(() {
      _pendingNewSkillName = name.trim();
      _newSkillCategory = null;
      _showCategoryPicker = true;
      _showSuggestions = false;
    });
  }

  Future<void> _confirmCreateWithCategory() async {
    if (_newSkillCategory == null) return;
    setState(() => _isCreating = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final result = await context.read<ProfileProvider>().createSkill(token, {
        'skill_name': _pendingNewSkillName,
        'skill_category': _newSkillCategory,
      });
      if (result != null && mounted) {
        final newSkill = SkillModel(
          skillId: result['skill_id'] as String,
          skillName: result['skill_name'] as String,
          skillCategory: result['skill_category'] as String?,
        );
        _select(newSkill);
        setState(() => _showCategoryPicker = false);
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _submit() async {
    if (_selected == null || _proficiency == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSave({
        "skill_id": _selected!.skillId,
        "proficiency_level": _proficiency!.toLowerCase(),
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──────────────────────────────────────────────────────
            const Center(
              child: Text(
                'Add Skill',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // ── Search field ───────────────────────────────────────────────
            const Text(
              "Skill",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onChanged,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Type to search skills...',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 20,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _selected = null;
                              _showSuggestions = false;
                            });
                            final token =
                                context.read<AuthProvider>().token!;
                            context
                                .read<SkillProvider>()
                                .searchSkills(token, '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            // ── Suggestions ────────────────────────────────────────────────
            if (_showSuggestions)
              Consumer<SkillProvider>(
                builder: (_, provider, __) {
                  final list = provider.searchResults.take(6).toList();
                  final exactMatch = list.any(
                    (s) =>
                        s.skillName.toLowerCase() == query.toLowerCase(),
                  );
                  final showCreate = query.isNotEmpty && !exactMatch;

                  if (provider.isLoading || _isCreating) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x10000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        ...list.map(
                          (skill) => _SkillItem(
                            skill: skill,
                            isSelected: _selected?.skillId == skill.skillId,
                            onTap: () => _select(skill),
                          ),
                        ),
                        if (showCreate) ...[
                          if (list.isNotEmpty)
                            Divider(
                              height: 1,
                              color: Colors.grey.shade100,
                            ),
                          InkWell(
                            onTap: () => _promptCategoryThenCreate(query),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.add_circle_outline,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        text: 'Add "',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: query,
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const TextSpan(
                                            text: '" as new skill',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (list.isEmpty && !showCreate)
                          const Padding(
                            padding: EdgeInsets.all(14),
                            child: Text(
                              'No skills found',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

            // ── Category picker (shown when creating a new skill) ──────────
            if (_showCategoryPicker && !_isCreating) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Creating "$_pendingNewSkillName" — choose type:',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showCategoryPicker = false),
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: _categories.asMap().entries.map((entry) {
                  final cat = entry.value.$1;
                  final label = entry.value.$2;
                  final isSelected = _newSkillCategory == cat;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _newSkillCategory = cat),
                      child: Container(
                        margin: entry.key < _categories.length - 1
                            ? const EdgeInsets.only(right: 8)
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[700],
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _newSkillCategory != null
                      ? _confirmCreateWithCategory
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Create Skill',
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ),
            ],

            // ── Selected indicator ─────────────────────────────────────────
            if (_selected != null && !_showSuggestions) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _selected!.skillName,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // ── Proficiency ────────────────────────────────────────────────
            const Text(
              "Proficiency",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: _levels.asMap().entries.map((entry) {
                final isSelected = _proficiency == entry.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _proficiency = entry.value),
                    child: Container(
                      margin: entry.key < _levels.length - 1
                          ? const EdgeInsets.only(right: 8)
                          : null,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey[700],
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Save button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selected != null &&
                        _proficiency != null &&
                        !_isSubmitting)
                    ? _submit
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        "Save",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillItem extends StatelessWidget {
  final SkillModel skill;
  final bool isSelected;
  final VoidCallback onTap;

  const _SkillItem({
    required this.skill,
    required this.isSelected,
    required this.onTap,
  });

  static String _formatCategory(String cat) {
    return switch (cat) {
      'hard_skill' => 'Hard Skill',
      'soft_skill' => 'Soft Skill',
      'tool' => 'Tool',
      _ => cat.replaceAll('_', ' '),
    };
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withOpacity(0.3)
              : null,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade50),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                skill.skillName,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? AppColors.primary : Colors.black87,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (skill.skillCategory != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatCategory(skill.skillCategory!),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                  ),
                ),
              ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check, size: 16, color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }
}
