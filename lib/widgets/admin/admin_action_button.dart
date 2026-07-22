import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/admin_colors.dart';

enum AdminActionStyle { filled, outlined }

/// Unified action button (Accept/Dismiss/Approve/Reject/etc.) with a subtle
/// web hover lift and press scale-down. Replaces the duplicate
/// `_ActionButton` classes previously defined separately in the AI and
/// Appeals pages.
class AdminActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final AdminActionStyle style;

  const AdminActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.style = AdminActionStyle.filled,
  });

  @override
  State<AdminActionButton> createState() => _AdminActionButtonState();
}

class _AdminActionButtonState extends State<AdminActionButton> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final filled = widget.style == AdminActionStyle.filled;
    final disabled = widget.onPressed == null;

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: disabled
                  ? AdminColors.surfaceAlt
                  : filled
                      ? widget.color
                      : (_hovering ? widget.color.withOpacity(0.08) : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: filled ? null : Border.all(color: disabled ? AdminColors.border : widget.color.withOpacity(0.4)),
              boxShadow: filled && !disabled && _hovering
                  ? [
                      BoxShadow(
                        color: widget.color.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: disabled ? AdminColors.faint : (filled ? Colors.white : widget.color),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: disabled ? AdminColors.faint : (filled ? Colors.white : widget.color),
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
