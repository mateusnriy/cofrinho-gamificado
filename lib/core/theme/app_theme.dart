import 'package:flutter/material.dart';

class AppTheme {
  // Paleta Soft 3D Base
  static const Color primary = Color(0xFF2E7D32); // Verde Ação Médio
  static const Color primaryDark = Color(0xFF1B5E20); // Verde Floresta Profundo
  static const Color primaryMid = Color(0xFF388E3C);
  static const Color primaryLight = Color(0xFF66BB6A);
  static const Color primaryPale = Color(0xFFE8F5E9);
  static const Color secondary = Color(0xFF0284C7); // Azul Sky
  static const Color warning = Color(0xFFF9A825); // Ouro Âmbar Gamificado
  static const Color warningGold = Color(0xFFFFD600);
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFE53935);

  // Cores Light
  static const Color bgLight = Color(0xFFF5F5F5); // Off-white descansado
  static const Color cardLight = Colors.white;
  static const Color textMainLight = Color(0xFF1A1A1A);
  static const Color textMutedLight = Color(0xFF757575);

  // Cores Dark (Floresta Noturna)
  static const Color bgDark = Color(0xFF0D1F14); // Verde noturno profundo
  static const Color cardDark = Color(0xFF1B2E22); // Verde musgo
  static const Color cardDarkElevated = Color(0xFF243B2A);
  static const Color primaryNeonDark = Color(0xFF00C853); // Verde luminescente
  static const Color primaryAccentDark = Color(0xFF69F0AE);
  static const Color textMainDark = Color(0xFFFFFFFF);
  static const Color textMutedDark = Color(0xFFA5D6A7);

  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      surface: bgLight,
    );

    return _buildTheme(
      base: base,
      bg: bgLight,
      card: cardLight,
      textMain: textMainLight,
      textMuted: textMutedLight,
      fabColor: primary,
      isDark: false,
    );
  }

  static ThemeData get dark {
    final base = ColorScheme.fromSeed(
      seedColor: primaryNeonDark,
      brightness: Brightness.dark,
      primary: primaryNeonDark,
      secondary: secondary,
      surface: bgDark,
    );

    return _buildTheme(
      base: base,
      bg: bgDark,
      card: cardDark,
      textMain: textMainDark,
      textMuted: textMutedDark,
      fabColor: primaryNeonDark,
      isDark: true,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme base,
    required Color bg,
    required Color card,
    required Color textMain,
    required Color textMuted,
    required Color fabColor,
    required bool isDark,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textMain,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: textMain,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textMain),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: fabColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? primaryNeonDark : primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? cardDarkElevated : const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: isDark ? const Color(0xFF243B2A) : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: isDark ? const Color(0xFF243B2A) : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? primaryNeonDark : primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        labelStyle: TextStyle(color: textMuted),
        hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.7)),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: textMain,
            letterSpacing: -1),
        headlineMedium: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textMain,
            letterSpacing: -0.5),
        headlineSmall: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: textMain),
        titleMedium: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textMain),
        bodyLarge: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            color: textMain,
            fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            color: textMuted,
            fontWeight: FontWeight.w500),
        bodySmall: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            color: textMuted,
            fontWeight: FontWeight.w500),
      ),
    );
  }

  static const List<Color> goalColors = [
    Color(0xFF2E7D32),
    Color(0xFF0284C7),
    Color(0xFF7C3AED),
    Color(0xFFF59E0B),
    Color(0xFFE11D48),
    Color(0xFF0D9488),
    Color(0xFF1B5E20),
    Color(0xFFD97706),
  ];

  static const List<IconData> goalIcons = [
    Icons.sports_esports_rounded,
    Icons.flight_takeoff_rounded,
    Icons.directions_car_rounded,
    Icons.home_work_rounded,
    Icons.savings_rounded,
    Icons.school_rounded,
    Icons.favorite_rounded,
    Icons.laptop_mac_rounded,
    Icons.shopping_bag_rounded,
    Icons.fitness_center_rounded,
    Icons.beach_access_rounded,
    Icons.pets_rounded,
  ];
}
