import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DkbColors {
  static const Color primary = Color(0xFF1C2B56);
  static const Color primaryLight = Color(0xFF2E4080);
  static const Color primaryDeep = Color(0xFF0D1A36);
  static const Color accent = Color(0xFF00A3E0);
  static const Color accentDark = Color(0xFF0082B3);
  static const Color background = Color(0xFFF2F4F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0D1A36);
  static const Color textSecondary = Color(0xFF5A6478);
  static const Color textMuted = Color(0xFFADB5BD);
  static const Color divider = Color(0xFFE4E8F0);
  static const Color success = Color(0xFF1AAE6F);
  static const Color danger = Color(0xFFE53935);
  static const Color warning = Color(0xFFF59E0B);
  static const Color cardShadow = Color(0x141C2B56);

  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primaryDeep],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E4080), Color(0xFF0D1A36)],
    stops: [0.0, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );
}

class DkbShadows {
  static List<BoxShadow> xs = [
    BoxShadow(color: DkbColors.cardShadow, blurRadius: 4, offset: Offset(0, 1)),
  ];
  static List<BoxShadow> sm = [
    BoxShadow(color: DkbColors.cardShadow, blurRadius: 8, offset: Offset(0, 2)),
  ];
  static List<BoxShadow> md = [
    BoxShadow(color: DkbColors.cardShadow, blurRadius: 16, offset: Offset(0, 4)),
  ];
  static List<BoxShadow> lg = [
    BoxShadow(color: DkbColors.cardShadow, blurRadius: 24, offset: Offset(0, 8)),
  ];
  static List<BoxShadow> xl = [
    BoxShadow(color: DkbColors.cardShadow, blurRadius: 40, offset: Offset(0, 12)),
  ];
}

class DkbRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double full = 999;
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: DkbColors.primary,
        secondary: DkbColors.accent,
        surface: DkbColors.background,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: DkbColors.textPrimary,
        error: DkbColors.danger,
      ),
      scaffoldBackgroundColor: DkbColors.background,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: DkbColors.textPrimary,
        displayColor: DkbColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: DkbColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DkbColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DkbRadius.md),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DkbColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DkbRadius.md),
          borderSide: const BorderSide(color: DkbColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DkbRadius.md),
          borderSide: const BorderSide(color: DkbColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DkbRadius.md),
          borderSide: const BorderSide(color: DkbColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DkbRadius.md),
          borderSide: const BorderSide(color: DkbColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DkbRadius.md),
          borderSide: const BorderSide(color: DkbColors.danger, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          color: DkbColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: DkbColors.textMuted,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: DkbColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DkbRadius.md),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: DkbColors.divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DkbColors.surface,
        selectedColor: DkbColors.primary,
        labelStyle: GoogleFonts.inter(fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DkbRadius.full),
          side: const BorderSide(color: DkbColors.divider),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DkbColors.primary,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DkbRadius.sm),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: DkbColors.surface,
        selectedItemColor: DkbColors.primary,
        unselectedItemColor: DkbColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return DkbColors.accent;
          return DkbColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DkbColors.accent.withValues(alpha: 0.3);
          }
          return DkbColors.divider;
        }),
      ),
    );
  }
}
