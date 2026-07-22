import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/admin_colors.dart';

/// Centered, width-capped confirm dialog. Replaces bare `AlertDialog` calls
/// across the admin pages, which stretch edge-to-edge on wide/web viewports
/// because AlertDialog has no intrinsic max width of its own.
Future<bool?> showAdminConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Confirm',
  Color confirmColor = AdminColors.primary,
  IconData icon = Icons.help_outline_rounded,
  Widget? extra,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: _AdminDialogPop(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: confirmColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: confirmColor, size: 22),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AdminColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: GoogleFonts.poppins(fontSize: 13, color: AdminColors.muted, height: 1.5),
                ),
                if (extra != null) ...[
                  const SizedBox(height: 14),
                  extra,
                ],
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        foregroundColor: AdminColors.muted,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text(cancelLabel, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      child: Text(
                        confirmLabel,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    ),
  );
}

/// Width-capped shell for the larger detail-sheet dialogs (user/job detail,
/// AI flag detail, etc). Keeps the existing scrollable content untouched —
/// callers pass their current sheet body in as [child].
class AdminDetailDialogShell extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double? maxHeight;
  final double borderRadius;

  const AdminDetailDialogShell({
    super.key,
    required this.child,
    this.maxWidth = 640,
    this.maxHeight,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      backgroundColor: Colors.transparent,
      child: _AdminDialogPop(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight ?? screen.height * 0.85,
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Subtle scale + fade entrance so dialogs feel less like an abrupt pop-in.
class _AdminDialogPop extends StatelessWidget {
  final Widget child;
  const _AdminDialogPop({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.0),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      builder: (_, scale, c) => Opacity(
        opacity: scale.clamp(0.0, 1.0) == 1.0 ? 1.0 : (scale - 0.92) / 0.08,
        child: Transform.scale(scale: scale, child: c),
      ),
      child: child,
    );
  }
}
