import 'dart:async';
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
import '../../../../widgets/app_toast.dart';
import 'job_files.dart';

const List<String> _supportedCurrencies = [
  'IDR',
  'USD',
  'EUR',
  'SGD',
  'AUD',
  'MYR',
];

class _RoleDraft {
  String? jobRoleId;
  String roleTitle;
  String roleDescription;
  String roleBudget;
  String budgetCurrency;
  String budgetType;
  int positionsAvailable;
  bool isRequired;
  int displayOrder;
  Map<String, Map<String, dynamic>> skills;
  bool isSaving;
  DateTime? lastSavedAt;

  _RoleDraft({
    this.jobRoleId,
    this.roleTitle = '',
    this.roleDescription = '',
    this.roleBudget = '',
    this.budgetCurrency = 'IDR',
    this.budgetType = 'fixed',
    this.positionsAvailable = 1,
    this.isRequired = true,
    this.displayOrder = 0,
    Map<String, Map<String, dynamic>>? skills,
    this.isSaving = false,
    this.lastSavedAt,
  }) : skills = skills ?? {};

  bool get hasDraftTriggerFields => roleTitle.trim().isNotEmpty;

  bool get hasAnyContent =>
      roleTitle.trim().isNotEmpty ||
      roleDescription.trim().isNotEmpty ||
      roleBudget.trim().isNotEmpty ||
      budgetCurrency != 'IDR' ||
      budgetType != 'fixed' ||
      positionsAvailable != 1 ||
      isRequired != true ||
      skills.isNotEmpty;

  Map<String, dynamic> toBackendMap({
    required String jobPostId,
    required bool isIndividual,
    required int displayOrder,
  }) {
    return {
      'job_post_id': jobPostId,
      'role_title': roleTitle.trim(),
      'budget_type': budgetType,
      'role_budget': roleBudget.trim().isEmpty
          ? null
          : ThousandsSeparatorFormatter.parse(roleBudget.trim()),
      'budget_currency': budgetCurrency,
      'role_description': roleDescription.trim().isEmpty
          ? null
          : roleDescription.trim(),
      'positions_available': isIndividual ? 1 : positionsAvailable,
      'is_required': isIndividual ? true : isRequired,
      'display_order': displayOrder,
    };
  }
}

class PostNewJobRoles extends StatefulWidget {
  const PostNewJobRoles({super.key});

  @override
  State<PostNewJobRoles> createState() => _PostNewJobRolesState();
}

class _PostNewJobRolesState extends State<PostNewJobRoles> {
  static const Color _primary = AppColors.primary;
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF16A34A);
  static const Color _warning = Color(0xFFF59E0B);

  final List<_RoleDraft> _roles = [];
  final Map<int, Timer> _autosaveTimers = {};
  int? _expandedIndex;
  bool _isSavingAll = false;
  bool _isHydrating = false;
  String _projectType = 'individual';

  bool get _isIndividual => _projectType == 'individual';

  @override
  void initState() {
    super.initState();
    _roles.add(_RoleDraft(displayOrder: 0));
    _expandedIndex = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = context.read<AuthProvider>().token!;
      await context.read<SkillProvider>().fetchAllSkills(token);
      await _hydrateProjectType();
      await _restoreDraftRolesIfAvailable();
    });
  }

  @override
  void dispose() {
    for (final timer in _autosaveTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> _hydrateProjectType() async {
    final provider = context.read<JobPostProvider>();
    final raw = provider.draftJobData?['project_type']?.toString();
    if (!mounted) return;
    setState(() {
      _projectType = raw == 'team' ? 'team' : 'individual';
    });
  }

  void _syncProjectTypeToProvider() {
    context.read<JobPostProvider>().setDraftJobData({
      'project_type': _projectType,
      'draft_step': 'roles',
    }, notify: false);
  }

  Future<void> _restoreDraftRolesIfAvailable() async {
    final provider = context.read<JobPostProvider>();
    final token = context.read<AuthProvider>().token;
    final jobPostId = provider.currentDraftJobPostId;

    _isHydrating = true;

    if (jobPostId != null &&
        jobPostId.isNotEmpty &&
        token != null &&
        token.isNotEmpty) {
      await provider.fetchJobRoles(token, jobPostId);
      final savedRoles = provider.jobRoles;
      if (savedRoles.isNotEmpty) {
        final restored = <_RoleDraft>[];
        for (int i = 0; i < savedRoles.length; i++) {
          final role = savedRoles[i];
          final roleId = (role.jobRoleId ?? '').toString();
          if (roleId.isNotEmpty) {
            await provider.fetchRoleSkills(token, roleId);
          }
          final roleSkills = provider.skillsForRole(roleId);
          final allSkills = context.read<SkillProvider>().skills;
          final skillMap = <String, Map<String, dynamic>>{};
          for (final rs in roleSkills) {
            final sid = rs.skillId.toString();
            if (sid.isEmpty) continue;
            SkillModel? matchedSkill;
            for (final skill in allSkills) {
              if (skill.skillId == sid) {
                matchedSkill = skill;
                break;
              }
            }
            skillMap[sid] = {
              'job_role_skill_id': rs.jobRoleSkillId,
              'skill_id': sid,
              'skill_name': matchedSkill?.skillName ?? 'Skill',
              'is_required': rs.isRequired,
              'importance_level': rs.importanceLevel ?? 'required',
            };
          }

          restored.add(
            _RoleDraft(
              jobRoleId: roleId,
              roleTitle: (role.roleTitle ?? '').toString(),
              roleDescription: (role.roleDescription ?? '').toString(),
              roleBudget: role.roleBudget == null
                  ? ''
                  : ThousandsSeparatorFormatter.formatNumber(role.roleBudget),
              budgetCurrency: (role.budgetCurrency ?? 'IDR').toString(),
              budgetType: (role.budgetType ?? 'fixed').toString(),
              positionsAvailable: role.positionsAvailable ?? 1,
              isRequired: role.isRequired ?? true,
              displayOrder: role.displayOrder ?? i,
              skills: skillMap,
              lastSavedAt: provider.lastDraftSavedAt,
            ),
          );
        }

        if (!mounted) return;
        setState(() {
          _roles
            ..clear()
            ..addAll(
              restored.isEmpty ? [_RoleDraft(displayOrder: 0)] : restored,
            );
          _expandedIndex = _roles.isEmpty ? null : 0;
        });
        _syncProjectTypeToProvider();
        _syncRolesToProvider();
        _isHydrating = false;
        return;
      }
    }

    if (provider.draftRoles.isNotEmpty) {
      final restored = <_RoleDraft>[];
      for (int i = 0; i < provider.draftRoles.length; i++) {
        final map = Map<String, dynamic>.from(provider.draftRoles[i]);
        final rawSkills = provider.draftRoleSkillMeta[i];
        final skillMap = <String, Map<String, dynamic>>{};
        if (rawSkills != null) {
          for (final entry in rawSkills.entries) {
            skillMap[entry.key.toString()] = Map<String, dynamic>.from(
              entry.value as Map<String, dynamic>,
            );
          }
        }
        restored.add(
          _RoleDraft(
            jobRoleId: map['job_role_id']?.toString(),
            roleTitle: (map['role_title'] ?? '').toString(),
            roleDescription: (map['role_description'] ?? '').toString(),
            roleBudget: map['role_budget'] == null
                ? ''
                : ThousandsSeparatorFormatter.formatNumber(map['role_budget']),
            budgetCurrency: (map['budget_currency'] ?? 'IDR').toString(),
            budgetType: (map['budget_type'] ?? 'fixed').toString(),
            positionsAvailable:
                (map['positions_available'] as num?)?.toInt() ?? 1,
            isRequired: (map['is_required'] as bool?) ?? true,
            displayOrder: (map['display_order'] as num?)?.toInt() ?? i,
            skills: skillMap,
            lastSavedAt: provider.lastDraftSavedAt,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _roles
          ..clear()
          ..addAll(restored.isEmpty ? [_RoleDraft(displayOrder: 0)] : restored);
        _expandedIndex = _roles.isEmpty ? null : 0;
      });
      _syncProjectTypeToProvider();
      _syncRolesToProvider();
    }

    _isHydrating = false;
  }

  String? _validate() {
    if (_roles.isEmpty) return 'Add at least one role';
    for (int i = 0; i < _roles.length; i++) {
      if (!_roles[i].hasDraftTriggerFields) {
        return 'Role ${i + 1} title is required';
      }
    }
    return null;
  }

  void _syncRolesToProvider() {
    final provider = context.read<JobPostProvider>();
    final roleMaps = _roles.asMap().entries.map((e) {
      final r = e.value;
      return {
        if (r.jobRoleId != null) 'job_role_id': r.jobRoleId,
        'role_title': r.roleTitle.trim(),
        'role_description': r.roleDescription.trim().isEmpty
            ? null
            : r.roleDescription.trim(),
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
    provider.setDraftJobData({
      'project_type': _projectType,
      'draft_step': 'roles',
    }, notify: false);

    for (int i = 0; i < _roles.length; i++) {
      final skillIds = _roles[i].skills.keys.toList();
      final skillNames = _roles[i].skills.values
          .map((v) => (v['skill_name'] ?? 'Skill').toString())
          .toList();
      provider.setDraftRoleSkills(i, skillIds, skillNames: skillNames);
      provider.setDraftRoleSkillMeta(i, _roles[i].skills);
    }
  }

  void _scheduleRoleAutosave(int index) {
    if (_isHydrating) return;
    if (index < 0 || index >= _roles.length) return;
    _syncProjectTypeToProvider();
    _syncRolesToProvider();
    _autosaveTimers[index]?.cancel();
    if (!_roles[index].hasDraftTriggerFields) return;
    _autosaveTimers[index] = Timer(
      const Duration(milliseconds: 1000),
      () async {
        await _saveRoleDraft(index);
      },
    );
  }

  Future<void> _saveRoleDraft(int index) async {
    if (!mounted || _isHydrating) return;
    if (index < 0 || index >= _roles.length) return;
    final role = _roles[index];
    if (!role.hasDraftTriggerFields) return;

    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;

    final provider = context.read<JobPostProvider>();
    final jobPostId = provider.currentDraftJobPostId;
    if (jobPostId == null || jobPostId.isEmpty) return;

    setState(() => role.isSaving = true);
    try {
      final payload = role.toBackendMap(
        jobPostId: jobPostId,
        isIndividual: _isIndividual,
        displayOrder: index,
      );
      dynamic savedRole;
      if (role.jobRoleId == null || role.jobRoleId!.isEmpty) {
        savedRole = await provider.createJobRole(token, payload);
      } else {
        final updatePayload = Map<String, dynamic>.from(payload)
          ..remove('job_post_id');
        savedRole = await provider.updateJobRole(
          token: token,
          jobRoleId: role.jobRoleId!,
          data: updatePayload,
        );
      }

      if (savedRole == null) {
        throw Exception(provider.error ?? 'Failed to save role');
      }

      role.jobRoleId = savedRole.jobRoleId?.toString();
      role.lastSavedAt = DateTime.now();
      await _syncRoleSkills(index);
      _syncProjectTypeToProvider();
      _syncRolesToProvider();
    } catch (_) {
    } finally {
      if (mounted && index < _roles.length) {
        setState(() => _roles[index].isSaving = false);
      }
    }
  }

  Future<void> _syncRoleSkills(int index) async {
    if (index < 0 || index >= _roles.length) return;
    final role = _roles[index];
    final roleId = role.jobRoleId;
    final token = context.read<AuthProvider>().token;
    final provider = context.read<JobPostProvider>();
    if (roleId == null || roleId.isEmpty || token == null || token.isEmpty)
      return;

    await provider.fetchRoleSkills(token, roleId);
    final existingSkillRows = provider.skillsForRole(roleId);
    final existingBySkillId = <String, dynamic>{};
    for (final item in existingSkillRows) {
      final sid = (item.skillId ?? '').toString();
      if (sid.isNotEmpty) existingBySkillId[sid] = item;
    }

    final selectedSkillIds = role.skills.keys.toSet();
    for (final skillId in selectedSkillIds) {
      final skillMeta = role.skills[skillId]!;
      final existing = existingBySkillId[skillId];
      if (existing == null) {
        final created = await provider.createRoleSkill(token, {
          'job_role_id': roleId,
          'skill_id': skillId,
          'is_required': skillMeta['is_required'] ?? true,
          'importance_level': skillMeta['importance_level'] ?? 'required',
        });
        if (created != null) {
          role.skills[skillId] = {
            ...skillMeta,
            'job_role_skill_id': created.jobRoleSkillId,
          };
        }
      }
    }

    for (final entry in existingBySkillId.entries) {
      if (!selectedSkillIds.contains(entry.key)) {
        await provider.deleteRoleSkill(
          token,
          entry.value.jobRoleSkillId,
          roleId,
        );
      }
    }
  }

  Future<void> _saveAllRoles() async {
    for (int i = 0; i < _roles.length; i++) {
      await _saveRoleDraft(i);
    }
  }

  Future<void> _onNext() async {
    final err = _validate();
    if (err != null) {
      AppToast.error(err);
      return;
    }

    setState(() => _isSavingAll = true);
    try {
      await _saveAllRoles();
      _syncProjectTypeToProvider();
      _syncRolesToProvider();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostNewJobFiles()),
      );
    } finally {
      if (mounted) setState(() => _isSavingAll = false);
    }
  }

  void _addRole() {
    setState(() {
      _roles.add(_RoleDraft(displayOrder: _roles.length));
      _expandedIndex = _roles.length - 1;
    });
    _syncRolesToProvider();
  }

  Future<void> _deleteRole(int index) async {
    final role = _roles[index];
    final roleId = role.jobRoleId;
    final token = context.read<AuthProvider>().token;
    final provider = context.read<JobPostProvider>();

    if (roleId != null &&
        roleId.isNotEmpty &&
        token != null &&
        token.isNotEmpty) {
      await provider.deleteJobRole(token, roleId);
    }

    _autosaveTimers[index]?.cancel();
    _autosaveTimers.remove(index);
    setState(() {
      _roles.removeAt(index);
      if (_roles.isEmpty) {
        _roles.add(_RoleDraft(displayOrder: 0));
        _expandedIndex = 0;
      } else if (_expandedIndex == index) {
        _expandedIndex = null;
      } else if (_expandedIndex != null && _expandedIndex! > index) {
        _expandedIndex = _expandedIndex! - 1;
      }
    });
    _syncRolesToProvider();
  }

  String _roleStatusText(_RoleDraft role) {
    if (role.isSaving) return 'Saving role...';
    if (role.lastSavedAt != null) return 'Role draft saved';
    if (role.hasAnyContent && !role.hasDraftTriggerFields)
      return 'Add a role title to start autosave';
    return 'Not saved yet';
  }

  Color _roleStatusAccent(_RoleDraft role) {
    if (role.isSaving) return _warning;
    if (role.lastSavedAt != null) return _success;
    return _textMuted;
  }

  IconData _roleStatusIcon(_RoleDraft role) {
    if (role.isSaving) return Icons.sync_rounded;
    if (role.lastSavedAt != null) return Icons.check_circle_rounded;
    return Icons.edit_note_rounded;
  }

  @override
  Widget build(BuildContext context) {
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProjectTypeSection(),
                        const SizedBox(height: 8),
                        ..._roles.asMap().entries.map(
                          (e) => _RoleCard(
                            key: ValueKey(
                              e.value.jobRoleId ?? 'draft_${e.key}',
                            ),
                            index: e.key,
                            draft: e.value,
                            isExpanded: _expandedIndex == e.key,
                            canDelete: !_isIndividual,
                            isIndividual: _isIndividual,
                            statusText: _roleStatusText(e.value),
                            statusAccent: _roleStatusAccent(e.value),
                            statusIcon: _roleStatusIcon(e.value),
                            onTapHeader: () => setState(() {
                              _expandedIndex = _expandedIndex == e.key
                                  ? null
                                  : e.key;
                            }),
                            onDelete: () => _deleteRole(e.key),
                            onChanged: () {
                              setState(() {});
                              _scheduleRoleAutosave(e.key);
                            },
                          ),
                        ),
                        if (!_isIndividual) _AddRoleButton(onTap: _addRole),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
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
            active: false,
            completed: true,
          ),
          SizedBox(width: 8),
          Expanded(child: Divider(color: _border, thickness: 1)),
          SizedBox(width: 8),
          _StepPill(index: 2, label: 'Role', active: true, completed: false),
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

  Widget _buildProjectTypeSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose whether this job is for one freelancer or a team.',
            style: TextStyle(fontSize: 12.5, color: _textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: _surface,
              border: Border.all(color: _border),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _typeOption('Individual', 'individual', Icons.person_outline),
                _typeOption('Team', 'team', Icons.people_outline),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: _primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isIndividual
                        ? 'Individual: completed by 1 freelancer.'
                        : 'Team: completed by 2 or more freelancers.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeOption(String label, String value, IconData icon) {
    final selected = _projectType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _projectType = value);
          _syncProjectTypeToProvider();
          _scheduleRoleAutosave(_expandedIndex ?? 0);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            color: selected ? _primary : Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : _primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF1F2937),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      'Role & Skills',
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _isSavingAll ? null : _onNext,
          icon: _isSavingAll
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
            _isSavingAll ? 'Saving roles...' : 'Next: Attachment',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
            decoration: BoxDecoration(
              color: fg,
              shape: completed ? BoxShape.circle : BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 13)
                : Text(
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

class _RoleCard extends StatefulWidget {
  final int index;
  final _RoleDraft draft;
  final bool isExpanded;
  final bool canDelete;
  final bool isIndividual;
  final String statusText;
  final Color statusAccent;
  final IconData statusIcon;
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
    required this.statusText,
    required this.statusAccent,
    required this.statusIcon,
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
      ..addListener(() {
        widget.draft.roleDescription = _descCtrl.text;
        widget.onChanged();
      });
    _budgetCtrl = TextEditingController(text: widget.draft.roleBudget)
      ..addListener(() {
        widget.draft.roleBudget = _budgetCtrl.text;
        widget.onChanged();
      });
    _posCtrl =
        TextEditingController(text: widget.draft.positionsAvailable.toString())
          ..addListener(() {
            widget.draft.positionsAvailable = int.tryParse(_posCtrl.text) ?? 1;
            widget.onChanged();
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
          'skill_id': skill.skillId,
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.onTapHeader,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  Row(
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
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFFF5C5C),
                            size: 18,
                          ),
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
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.statusIcon,
                          size: 13,
                          color: widget.statusAccent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.statusText,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: widget.statusAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Role Title'),
                  _field(
                    controller: _titleCtrl,
                    hint: 'e.g. UI Designer, Backend Developer',
                    prefixIcon: Icons.work_outline,
                  ),
                  _label('Description'),
                  _field(
                    controller: _descCtrl,
                    hint: 'Describe what this role will do...',
                    maxLines: 4,
                    prefixIcon: Icons.description_outlined,
                  ),
                  _label('Budget Type'),
                  _buildBudgetTypePills(d),
                  const SizedBox(height: 14),
                  _label('Amount & Currency'),
                  _buildAmountCurrencyRow(d),
                  const SizedBox(height: 14),
                  if (!widget.isIndividual) ...[
                    _label('Positions Available'),
                    _field(
                      controller: _posCtrl,
                      hint: '1',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.groups_2_outlined,
                    ),
                    _buildRequiredToggle(d),
                    const SizedBox(height: 14),
                  ],
                  _label('Skills'),
                  _buildSkillsSection(hasSkills),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1F2937),
        ),
      ),
    );
  }

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
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: EdgeInsets.only(bottom: bottomMargin),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13.5, color: Color(0xFF1F2937)),
        inputFormatters:
            keyboardType == TextInputType.number && controller == _budgetCtrl
            ? [ThousandsSeparatorFormatter()]
            : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: _primary, size: 20)
              : null,
          contentPadding: prefixIcon != null
              ? const EdgeInsets.symmetric(vertical: 17)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildBudgetTypePills(_RoleDraft d) {
    return Row(
      children: [
        _budgetPill(d, 'fixed', 'Fixed'),
        const SizedBox(width: 8),
        _budgetPill(d, 'negotiable', 'Negotiable'),
      ],
    );
  }

  Widget _budgetPill(_RoleDraft d, String value, String label) {
    final selected = d.budgetType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => d.budgetType = value);
          widget.onChanged();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected ? _primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _primary : const Color(0xFFE5E7EB),
            ),
            boxShadow: selected
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF374151),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCurrencyRow(_RoleDraft d) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _field(
            controller: _budgetCtrl,
            hint: '0',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.payments_outlined,
            bottomMargin: 0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _supportedCurrencies.contains(d.budgetCurrency)
                    ? d.budgetCurrency
                    : 'IDR',
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _primary,
                ),
                items: _supportedCurrencies.map((currency) {
                  return DropdownMenuItem<String>(
                    value: currency,
                    child: Text(
                      currency,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => d.budgetCurrency = value);
                  widget.onChanged();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequiredToggle(_RoleDraft d) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Required role',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
        ),
        Switch(
          value: d.isRequired,
          activeColor: _primary,
          onChanged: (value) {
            setState(() => d.isRequired = value);
            widget.onChanged();
          },
        ),
      ],
    );
  }

  Widget _buildSkillsSection(bool hasSkills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.draft.skills.entries.map((entry) {
            final skill = entry.value;
            return Chip(
              label: Text((skill['skill_name'] ?? 'Skill').toString()),
              onDeleted: () {
                setState(() => widget.draft.skills.remove(entry.key));
                widget.onChanged();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(color: _primary.withOpacity(0.15)),
              ),
              deleteIconColor: const Color(0xFFE11D48),
              backgroundColor: AppColors.secondary,
              labelStyle: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => setState(() => _showSkillPicker = !_showSkillPicker),
          icon: Icon(_showSkillPicker ? Icons.close : Icons.add, size: 18),
          label: Text(_showSkillPicker ? 'Close skill picker' : 'Add skills'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _primary,
            side: BorderSide(color: _primary.withOpacity(0.18)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_showSkillPicker) ...[
          const SizedBox(height: 12),
          _SkillPicker(
            selectedIds: widget.draft.skills.keys.toSet(),
            searchController: _skillSearchCtrl,
            onSearchChanged: _onSearchChanged,
            onToggle: _toggleSkill,
          ),
        ],
        if (!hasSkills)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No skills selected yet.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ),
      ],
    );
  }
}

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
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF8FAFC),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
              decoration: const InputDecoration(
                hintText: 'Search skills...',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                prefixIcon: Icon(
                  Icons.search,
                  color: Color(0xFFB5B4B4),
                  size: 18,
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
          Consumer<SkillProvider>(
            builder: (_, provider, __) {
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
                      fontSize: 12,
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
                    style: TextStyle(color: Color(0xFFB5B4B4), fontSize: 12),
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

class _AddRoleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddRoleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add another role'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class ThousandsSeparatorFormatter extends TextInputFormatter {
  static final _formatter = NumberFormat.decimalPattern();

  static String formatNumber(dynamic value) {
    if (value == null) return '';
    final number = value is num
        ? value
        : int.tryParse(value.toString().replaceAll(',', ''));
    if (number == null) return value.toString();
    return _formatter.format(number);
  }

  static int? parse(String value) {
    return int.tryParse(value.replaceAll(',', ''));
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final number = int.tryParse(digits);
    if (number == null) return oldValue;
    final formatted = _formatter.format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
