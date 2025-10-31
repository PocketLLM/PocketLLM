import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme textTheme = TextTheme(
    headlineLarge: GoogleFonts.sora(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 32 / 28,
      letterSpacing: -0.2,
    ),
    headlineMedium: GoogleFonts.sora(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 28 / 22,
    ),
    titleMedium: GoogleFonts.sora(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 24 / 18,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 24 / 16,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 22 / 15,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 20 / 13,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 24 / 16,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 20 / 14,
    ),
  );

  const AppTypography._();
}
