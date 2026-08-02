import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/admin_colors.dart';
import '../../services/admin_service.dart';

Future<AdminActionOutcome?> showAdminReasonDialog(
  BuildContext context, {
  required String title,
  required String submitLabel,
  required Color accentColor,
  required IconData icon,
  required Future<AdminActionOutcome> Function(String reason) onSubmit,
  String? warningText,
  String hintText = 'Explain your decision…',
  int minLength = 10,
  int maxLength = 1000,
}) {
  return showDialog<AdminActionOutcome>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (_) => _AdminReasonDialog(
      title: title,
      submitLabel: submitLabel,
      accentColor: accentColor,
      icon: icon,
      onSubmit: onSubmit,
      warningText: warningText,
      hintText: hintText,
      minLength: minLength,
      maxLength: maxLength,
    ),
  );
}

class _AdminReasonDialog extends StatefulWidget {
  final String title;
  final String submitLabel;
  final Color accentColor;
  final IconData icon;
  final Future<AdminActionOutcome> Function(String reason) onSubmit;
  final String? warningText;
  final String hintText;
  final int minLength;
  final int maxLength;

  const _AdminReasonDialog({
    required this.title,
    required this.submitLabel,
    required this.accentColor,
    required this.icon,
    required this.onSubmit,
    required this.warningText,
    required this.hintText,
    required this.minLength,
    required this.maxLength,
  });

  @override
  State<_AdminReasonDialog> createState() => _AdminReasonDialogState();
}

class _AdminReasonDialogState extends State<_AdminReasonDialog> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _len => _controller.text.trim().length;
  bool get _valid => _len >= widget.minLength && _len <= widget.maxLength;

  Future<void> _submit() async {
    if (!_valid || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final outcome = await widget.onSubmit(_controller.text.trim());
    if (!mounted) return;
    if (outcome.success) {
      Navigator.pop(context, outcome);
    } else {
      setState(() {
        _submitting = false;
        _error = outcome.errorMessage ?? 'Action failed — please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: widget.accentColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AdminColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.warningText != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminColors.amberBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AdminColors.amberBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 16, color: AdminColors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.warningText!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AdminColors.body,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  maxLength: widget.maxLength,
                  enabled: !_submitting,
                  style: GoogleFonts.poppins(fontSize: 13, color: AdminColors.body),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle:
                        GoogleFonts.poppins(fontSize: 12, color: AdminColors.faint),
                    filled: true,
                    fillColor: AdminColors.surfaceSoft,
                    contentPadding: const EdgeInsets.all(12),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AdminColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _error != null
                            ? AdminColors.red
                            : AdminColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _error != null
                            ? AdminColors.red
                            : widget.accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _error != null
                          ? Text(
                              _error!,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AdminColors.red,
                              ),
                            )
                          : Text(
                              _len < widget.minLength
                                  ? 'At least ${widget.minLength} characters'
                                  : '$_len / ${widget.maxLength}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AdminColors.faint,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.pop(context, null),
                      style: TextButton.styleFrom(
                        foregroundColor: AdminColors.muted,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _valid && !_submitting ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AdminColors.border,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.submitLabel,
                              style:
                                  GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
