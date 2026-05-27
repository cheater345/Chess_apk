import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF769656);
  static const Color darkGreen = Color(0xFF4A6B3A);
  static const Color lightGreen = Color(0xFFA8C87A);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surfaceDark = Color(0xFF16213E);
  static const Color cardDark = Color(0xFF1F2B47);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentSilver = Color(0xFFC0C0C0);
  static const Color accentBronze = Color(0xFFCD7F32);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color successGreen = Color(0xFF2ECC71);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color chessBoardLight = Color(0xFFF0D9B5);
  static const Color chessBoardDark = Color(0xFFB58863);

  static const Color boardGreenLight = Color(0xFF769656);
  static const Color boardGreenDark = Color(0xFFEEEDD2);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: accentGold,
        surface: surfaceDark,
        error: errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: const TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: const TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: const TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: const TextStyle(
          color: textSecondary,
          fontSize: 16,
        ),
        bodyMedium: const TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2A4A),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardDark,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class AppGradients {
  static const LinearGradient primaryGreenGradient = LinearGradient(
    colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [AppTheme.backgroundDark, AppTheme.surfaceDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldAccent = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient rankGradient(String rank) {
    switch (rank) {
      case 'Bronze':
        return const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFF8B4513)]);
      case 'Silver':
        return const LinearGradient(colors: [Color(0xFFC0C0C0), Color(0xFF808080)]);
      case 'Gold':
        return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]);
      case 'Platinum':
        return const LinearGradient(colors: [Color(0xFFE5E4E2), Color(0xFFB0B0B0)]);
      case 'Diamond':
        return const LinearGradient(colors: [Color(0xFFB9F2FF), Color(0xFF00BFFF)]);
      case 'Master':
        return const LinearGradient(colors: [Color(0xFFFF69B4), Color(0xFFFF1493)]);
      case 'Grandmaster':
        return const LinearGradient(colors: [Color(0xFFFF0000), Color(0xFF8B0000)]);
      default:
        return const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFF8B4513)]);
    }
  }
}
