import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppText {
  AppText._();

  static TextStyle get h1 => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    height: 36 / 24,
  );

  static TextStyle get h2 => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 28 / 18,
  );

  static TextStyle get h3 => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
  );

  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 22 / 14,
  );

  static TextStyle get bodySemiBold => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 22 / 14,
  );

  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
  );

  static TextStyle get captionSemiBold => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 18 / 12,
  );

  static TextStyle get overline => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 16 / 10,
  );
}
