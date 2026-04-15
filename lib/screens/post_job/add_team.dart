import 'package:flutter/material.dart';
import '../../models/job_role_model.dart';

Future<JobRoleModel?> showAddTeamModal(
  BuildContext context, {
  JobRoleModel? editRole,
}) {
  return showModalBottomSheet<JobRoleModel?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddTeamSheet(editRole: editRole),
  );
}

class _AddTeamSheet extends StatefulWidget {
  final JobRoleModel? editRole;

  const _AddTeamSheet({this.editRole});

  @override
  State<_AddTeamSheet> createState() => _AddTeamSheetState();
}

class _AddTeamSheetState extends State<_AddTeamSheet> {
  static const _primary = Color(0xFF00AAA8);

  final _roleController = TextEditingController();
  final _budgetController = TextEditingController();
  final _descController = TextEditingController();

  bool get _isEdit => widget.editRole != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _roleController.text = widget.editRole!.roleTitle;
      _budgetController.text =
          widget.editRole!.roleBudget?.toStringAsFixed(0) ?? '';
      _descController.text = widget.editRole!.roleDescription ?? '';
    }
  }

  @override
  void dispose() {
    _roleController.dispose();
    _budgetController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final roleText = _roleController.text.trim();
    final budgetText = _budgetController.text.trim();

    if (roleText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Role title is required')));
      return;
    }

    if (budgetText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Budget is required')));
      return;
    }

    final budget = double.tryParse(budgetText);
    if (budget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget must be a valid number')),
      );
      return;
    }

    final role = JobRoleModel(
      jobRoleId: widget.editRole?.jobRoleId ?? '',
      jobPostId: '',
      roleTitle: roleText,
      roleBudget: budget,
      budgetCurrency: 'USD',
      budgetType: 'fixed',
      roleDescription: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      positionsAvailable: widget.editRole?.positionsAvailable ?? 1,
      isRequired: widget.editRole?.isRequired ?? true,
      displayOrder: widget.editRole?.displayOrder ?? 0,
    );

    Navigator.pop(context, role);
  }

  Future<void> _onDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Delete Role',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'Are you sure you want to delete this role?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF7D7D7D)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    Navigator.pop(context, _DeleteSentinel());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF00AAA8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Post new job',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isEdit ? 'Edit Team Role' : 'Add Team Role',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 100,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                _label('Role *'),
                const SizedBox(height: 8),
                _field(hint: 'Ex: UI Designer', controller: _roleController),
                const SizedBox(height: 15),
                _label('Budget *'),
                const SizedBox(height: 8),
                _field(
                  hint: 'Ex: 1000000',
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),
                _label('Description'),
                const SizedBox(height: 8),
                _field(
                  hint: 'Ex: We need a UI Designer who can work with team',
                  controller: _descController,
                  maxLines: 4,
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      _isEdit ? 'Update' : 'Add',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF7D7D7D),
      fontSize: 12,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _field({
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFF0F0F1)),
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
    ),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB5B4B4), fontSize: 12),
        contentPadding: const EdgeInsets.all(15),
        border: InputBorder.none,
      ),
    ),
  );
}

class _DeleteSentinel extends JobRoleModel {
  _DeleteSentinel()
    : super(
        jobRoleId: '__delete__',
        jobPostId: '',
        roleTitle: '',
        budgetType: '',
      );
}
