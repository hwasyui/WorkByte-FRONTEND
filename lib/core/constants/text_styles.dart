import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppText {
  AppText._();

  /// 24px · w900 — page titles
  static TextStyle get h1 => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    height: 36 / 24,
  );

  /// 18px · w700 — section headings
  static TextStyle get h2 => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 28 / 18,
  );

  /// 16px · w600 — sub-headings / labels
  static TextStyle get h3 => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
  );

  /// 14px · w400 — default body text
  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 22 / 14,
  );

  /// 14px · w600 — emphasised body / button labels
  static TextStyle get bodySemiBold => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 22 / 14,
  );

  /// 12px · w400 — captions, hints, helper text
  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
  );

  /// 12px · w600 — emphasised captions
  static TextStyle get captionSemiBold => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 18 / 12,
  );

  /// 10px · w400 — overlines, badges, tiny labels
  static TextStyle get overline => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 16 / 10,
  );
}
