import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../models/job_post_model.dart';

/// Minimal edit form for a job post's title and description - the only two
/// fields the harmful-text scan actually reads (see job_post_routes.py:
/// `_scan_text = f"{_title} {_desc}"`). Other job-post fields (category,
/// roles, files, deadline, etc.) don't affect moderation, so they're
/// intentionally left out of this form rather than rebuilding the full
/// multi-step post-job wizard just to fix a flagged title/description.
class JobPostEditForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final JobPostModel initialData;

  const JobPostEditForm({
    super.key,
    required this.onSave,
    required this.initialData,
  });

  @override
  State<JobPostEditForm> createState() => _JobPostEditFormState();
}

class _JobPostEditFormState extends State<JobPostEditForm> {
  final _formKey = GlobalKey<FormState>();

  late final titleCtrl = TextEditingController(
    text: widget.initialData.jobTitle,
  );
  late final descCtrl = TextEditingController(
    text: widget.initialData.jobDescription,
  );

  bool _isSubmitting = false;

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSave({
        "job_title": titleCtrl.text,
        "job_description": descCtrl.text,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
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
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
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

  @override
  Widget build(BuildContext context) {
    final isBlocked = widget.initialData.moderationStatus == 'blocked';

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

                const Text(
                  'Edit Job Post',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),

                if (isBlocked) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.block_rounded, size: 16, color: Color(0xFFDC2626)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This job post was flagged during review and is currently hidden from freelancers. Edit the title/description and save to resubmit it for review.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF991B1B), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                ],

                _buildField(
                  controller: titleCtrl,
                  hint: 'Job Title',
                  icon: Icons.title_outlined,
                ),
                _buildField(
                  controller: descCtrl,
                  hint: 'Job Description',
                  icon: Icons.description_outlined,
                  maxLines: 8,
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
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
                            'Save Changes',
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
