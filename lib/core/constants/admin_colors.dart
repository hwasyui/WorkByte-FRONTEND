import 'package:flutter/material.dart';

/// Shared palette for the admin portal only. Mirrors the hex values already
/// scattered across lib/screens/admin and lib/widgets/admin so new/rewritten
/// widgets have one source of truth instead of re-typing literals.
class AdminColors {
  AdminColors._();

  // Brand
  static const Color navy = Color(0xFF1E1B4B);
  static const Color navyDeep = Color(0xFF15132F);
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryBg = Color(0xFFEEF2FF);

  // Section accents
  static const Color green = Color(0xFF059669);
  static const Color greenBg = Color(0xFFECFDF5);
  static const Color cyan = Color(0xFF0891B2);
  static const Color cyanBg = Color(0xFFECFEFF);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleBg = Color(0xFFF3E8FF);
  static const Color amber = Color(0xFFD97706);
  static const Color amberBg = Color(0xFFFFFBEB);
  static const Color amberBgAlt = Color(0xFFFFF7ED);
  static const Color amberBorder = Color(0xFFFED7AA);
  static const Color red = Color(0xFFDC2626);
  static const Color redBg = Color(0xFFFEE2E2);

  // Grayscale
  static const Color ink = Color(0xFF111827);
  static const Color body = Color(0xFF374151);
  static const Color muted = Color(0xFF6B7280);
  static const Color faint = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color surfaceAlt = Color(0xFFF3F4F6);
  static const Color surfaceSoft = Color(0xFFF9FAFB);
  static const Color pageBg = Color(0xFFF3F4F6);

  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navy, navyDeep],
  );

  static const LinearGradient loginGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, Color(0xFF312E81), primary],
  );
}
