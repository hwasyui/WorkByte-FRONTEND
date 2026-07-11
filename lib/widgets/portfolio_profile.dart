import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../models/portfolio_model.dart';

class PortfolioProfile extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  /// When set, the form pre-fills from this entry and behaves as an edit
  /// (different button label, and saving re-triggers the moderation scan
  /// server-side) instead of adding a new one.
  final PortfolioModel? initialData;

  const PortfolioProfile({super.key, required this.onSave, this.initialData});

  @override
  State<PortfolioProfile> createState() => _PortfolioProfileState();
}

class _PortfolioProfileState extends State<PortfolioProfile> {
  final _formKey = GlobalKey<FormState>();

  late final projectTitleCtrl = TextEditingController(
    text: widget.initialData?.projectTitle,
  );
  late final projectDescCtrl = TextEditingController(
    text: widget.initialData?.projectDescription,
  );
  final yourRoleCtrl = TextEditingController();
  late final projectUrlCtrl = TextEditingController(
    text: widget.initialData?.projectUrl,
  );

  late DateTime? completionDate = widget.initialData?.completionDate;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialData != null;

  @override
  void dispose() {
    projectTitleCtrl.dispose();
    projectDescCtrl.dispose();
    yourRoleCtrl.dispose();
    projectUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        completionDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() => _isSubmitting = true);
      try {
        await widget.onSave({
          "projectTitle": projectTitleCtrl.text,
          "projectDescription": projectDescCtrl.text,
          "yourRole": yourRoleCtrl.text,
          "projectUrl": projectUrlCtrl.text,
          "completionDate": completionDate,
        });
        if (mounted) Navigator.pop(context);
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  // ── Reusable styled text field ──────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAF0)),
      ),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                12, maxLines > 1 ? 14 : 0, 8, maxLines > 1 ? 0 : 0),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              validator: validator ??
                  (v) => (v == null || v.isEmpty) ? 'Required' : null,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFADAEC0),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: maxLines > 1 ? 14 : 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  // ── Date picker field ───────────────────────────────────────────────────────
  Widget _buildDateField({
    required String hint,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAF0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  date == null ? hint : _formatDate(date),
                  style: TextStyle(
                    fontSize: 14,
                    color: date == null
                        ? const Color(0xFFADAEC0)
                        : const Color(0xFF1A1A2E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F8FC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDE8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                _buildField(
                  controller: projectTitleCtrl,
                  hint: 'Project Title',
                  icon: Icons.title_outlined,
                ),
                _buildField(
                  controller: projectDescCtrl,
                  hint: 'Project Description',
                  icon: Icons.description_outlined,
                  maxLines: 4,
                ),
                _buildField(
                  controller: yourRoleCtrl,
                  hint: 'Your Role (optional)',
                  icon: Icons.person_outline,
                  validator: (_) => null,
                ),
                _buildField(
                  controller: projectUrlCtrl,
                  hint: 'Project URL (optional)',
                  icon: Icons.link_outlined,
                  validator: (_) => null,
                ),

                _buildDateField(
                  hint: 'Completion Date',
                  date: completionDate,
                  onTap: _pickDate,
                ),

                const SizedBox(height: 8),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withOpacity(0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditing ? 'Save Changes' : 'Save',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}