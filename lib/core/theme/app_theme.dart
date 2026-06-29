import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color bgDark = Color(0xFF111827);
  static const Color bgLight = Colors.white;
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color cardDark = Color(0xFF1F2937);
  static const Color cardLight = Color(0xFFF3F4F6);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.emeraldGreen,
        secondary: AppColors.accentBlue,
        error: AppColors.errorRed,
        surface: AppColors.cardLight,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      cardTheme: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.emeraldGreen,
        secondary: AppColors.accentBlue,
        error: AppColors.errorRed,
        surface: AppColors.cardDark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      cardTheme: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }
}
