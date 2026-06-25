import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class EducationProfile extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const EducationProfile({super.key, required this.onSave});

  @override
  State<EducationProfile> createState() => _EducationProfileState();
}

class _EducationProfileState extends State<EducationProfile> {
  final _formKey = GlobalKey<FormState>();

  final schoolCtrl = TextEditingController();
  final degreeCtrl = TextEditingController();
  final fieldCtrl = TextEditingController();
  final gradeCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  bool isCurrent = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    schoolCtrl.dispose();
    degreeCtrl.dispose();
    fieldCtrl.dispose();
    gradeCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
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
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
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
      if (!isCurrent && endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End date is required if not currently studying'),
          ),
        );
        return;
      }
      setState(() => _isSubmitting = true);
      try {
        await widget.onSave({
          "school": schoolCtrl.text,
          "degree": degreeCtrl.text,
          "field": fieldCtrl.text,
          "grade": gradeCtrl.text,
          "description": descCtrl.text,
          "startDate": startDate,
          "endDate": endDate,
          "isCurrent": isCurrent,
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAEAF0)),
          ),
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
                    fontSize: 13,
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
                  controller: schoolCtrl,
                  hint: 'School',
                  icon: Icons.school_outlined,
                ),
                _buildField(
                  controller: degreeCtrl,
                  hint: 'Degree',
                  icon: Icons.workspace_premium_outlined,
                ),
                _buildField(
                  controller: fieldCtrl,
                  hint: 'Field of Study',
                  icon: Icons.menu_book_outlined,
                ),

                // Date row
                Row(
                  children: [
                    _buildDateField(
                      hint: 'Start Date',
                      date: startDate,
                      onTap: () => _pickDate(true),
                    ),
                    const SizedBox(width: 12),
                    _buildDateField(
                      hint: 'End Date',
                      date: endDate,
                      onTap: () => _pickDate(false),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Currently studying here
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Currently studying here',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Checkbox(
                        value: isCurrent,
                        onChanged: (v) => setState(() => isCurrent = v!),
                        activeColor: AppColors.primary,
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildField(
                  controller: gradeCtrl,
                  hint: 'Grade (optional)',
                  icon: Icons.grade_outlined,
                  validator: (_) => null,
                ),
                _buildField(
                  controller: descCtrl,
                  hint: 'Description',
                  icon: Icons.description_outlined,
                  maxLines: 4,
                  validator: (_) => null,
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
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
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
