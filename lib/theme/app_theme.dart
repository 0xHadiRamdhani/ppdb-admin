import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette: Hitam, Biru, Putih (School/Modern EdTech Aesthetic)
  static const Color dark = Color(0xFF0F172A); // Slate 900 (Hitam Pekat / Deep Navy)
  static const Color darkSecondary = Color(0xFF1E293B); // Slate 800
  static const Color primaryBlue = Color(0xFF1D4ED8); // Royal Blue
  static const Color brightBlue = Color(0xFF2563EB); // Electric School Blue
  static const Color lightBlue = Color(0xFFEFF6FF); // Soft Blue Surface
  static const Color skyBlue = Color(0xFF38BDF8); // Accent Sky Blue
  static const Color background = Color(0xFFF8FAFC); // Clean Canvas White
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color border = Color(0xFFE2E8F0); // Subtle Slate Border
  static const Color textMuted = Color(0xFF64748B); // Slate Muted Text
  static const Color textDark = Color(0xFF0F172A); // Main Slate Dark Text

  // Status Color Utilities
  static Color getStatusColor(String? status) {
    switch (status) {
      case 'Lulus verifikasi':
        return const Color(0xFF15803D); // Green
      case 'Menunggu verifikasi':
        return const Color(0xFFD97706); // Amber
      case 'Berkas tidak lengkap':
      case 'Berkas dikembalikan':
        return const Color(0xFFEA580C); // Orange
      case 'Tidak lulus verifikasi':
        return const Color(0xFFDC2626); // Red
      default:
        return primaryBlue;
    }
  }

  static Color getStatusBgColor(String? status) {
    switch (status) {
      case 'Lulus verifikasi':
        return const Color(0xFFDCFCE7);
      case 'Menunggu verifikasi':
        return const Color(0xFFFEF3C7);
      case 'Berkas tidak lengkap':
      case 'Berkas dikembalikan':
        return const Color(0xFFFFEDD5);
      case 'Tidak lulus verifikasi':
        return const Color(0xFFFEE2E2);
      default:
        return lightBlue;
    }
  }

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: dark,
        surface: surface,
        error: Color(0xFFDC2626),
      ),
      fontFamily: null, // Default system font with clean weights
      appBarTheme: const AppBarTheme(
        backgroundColor: dark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
      ),
    );
  }
}
