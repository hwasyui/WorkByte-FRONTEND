import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SnackBarType { error, success, info, warning }

class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final config = _configFor(type);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          duration: duration,
          content: _SnackBarContent(message: message, config: config),
        ),
      );
  }

  static _SnackConfig _configFor(SnackBarType type) {
    switch (type) {
      case SnackBarType.error:
        return const _SnackConfig(
          icon: Icons.error_outline_rounded,
          color: Color(0xFFEF4444),
          label: 'Error',
        );
      case SnackBarType.success:
        return const _SnackConfig(
          icon: Icons.check_circle_outline_rounded,
          color: Color(0xFF10B981),
          label: 'Success',
        );
      case SnackBarType.warning:
        return const _SnackConfig(
          icon: Icons.warning_amber_rounded,
          color: Color(0xFFF59E0B),
          label: 'Warning',
        );
      case SnackBarType.info:
        return const _SnackConfig(
          icon: Icons.info_outline_rounded,
          color: Color(0xFF4F46E5),
          label: 'Info',
        );
    }
  }
}

class _SnackConfig {
  final IconData icon;
  final Color color;
  final String label;

  const _SnackConfig({
    required this.icon,
    required this.color,
    required this.label,
  });
}

class _SnackBarContent extends StatelessWidget {
  final String message;
  final _SnackConfig config;

  const _SnackBarContent({required this.message, required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: config.color, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: config.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(config.icon, color: config.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  config.label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: config.color,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
