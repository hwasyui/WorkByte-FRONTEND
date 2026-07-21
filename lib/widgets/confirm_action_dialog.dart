import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

enum ConfirmDialogTone { primary, warning, destructive }

/// Shared confirmation dialog used across the job post flow (and reusable
/// anywhere else) so every "are you sure?" prompt looks and behaves the same.
class ConfirmActionDialog extends StatelessWidget {
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _destructive = Color(0xFFE11D48);

  final IconData icon;
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final ConfirmDialogTone tone;

  const ConfirmActionDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.tone = ConfirmDialogTone.destructive,
  });

  /// Shows the dialog and resolves to `true` only if the user confirmed.
  static Future<bool> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    ConfirmDialogTone tone = ConfirmDialogTone.destructive,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmActionDialog(
        icon: icon,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        tone: tone,
      ),
    );
    return confirmed ?? false;
  }

  Color get _accent {
    switch (tone) {
      case ConfirmDialogTone.destructive:
        return _destructive;
      case ConfirmDialogTone.warning:
        return _warning;
      case ConfirmDialogTone.primary:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _accent, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: _textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textDark,
                      side: const BorderSide(color: _border),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      cancelLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
