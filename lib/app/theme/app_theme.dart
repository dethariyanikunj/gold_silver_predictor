import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Dark background
  static const bg = Color(0xFF0A0E1A);
  static const bgCard = Color(0xFF111827);
  static const bgCardLight = Color(0xFF1A2235);
  static const border = Color(0xFF1E2D45);

  // Gold palette
  static const goldPrimary = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFF5D76E);
  static const goldDark = Color(0xFFB8860B);
  static const goldGlow = Color(0x33D4AF37);

  // Silver palette
  static const silverPrimary = Color(0xFFC0C0C0);
  static const silverLight = Color(0xFFE8E8E8);
  static const silverDark = Color(0xFF9E9E9E);
  static const silverGlow = Color(0x33C0C0C0);

  // Direction colors
  static const bullish = Color(0xFF00D4AA);
  static const bullishBg = Color(0x1A00D4AA);
  static const bearish = Color(0xFFFF4F6A);
  static const bearishBg = Color(0x1AFF4F6A);
  static const neutral = Color(0xFF6B7280);
  static const neutralBg = Color(0x1A6B7280);
  static const uncertainty = Color(0xFFF59E0B);
  static const uncertaintyBg = Color(0x1AF59E0B);

  // Text
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF475569);

  // Accent
  static const accent = Color(0xFF6366F1);
  static const accentGlow = Color(0x336366F1);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.bgCard,
        primary: AppColors.goldPrimary,
        secondary: AppColors.silverPrimary,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          displayMedium: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          titleLarge: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          titleMedium: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          bodyLarge: TextStyle(fontSize: 15, color: AppColors.textPrimary),
          bodyMedium: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          bodySmall: TextStyle(fontSize: 11, color: AppColors.textMuted),
          labelLarge: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      dividerColor: AppColors.border,
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }
}
