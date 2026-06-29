import 'package:flutter/material.dart';

class AppColors {
  static const orange = Color(0xFFFF5A00);
  static const orangeDark = Color(0xFFE84500);
  static const orangeSoft = Color(0xFFFFEEE6);
  static const navy = Color(0xFF07182C);
  static const navySoft = Color(0xFF0B223A);
  static const text = Color(0xFF0B1B2F);
  static const muted = Color(0xFF69707A);
  static const line = Color(0xFFD9DCE1);
  static const surface = Color(0xFFF7F8FA);
  static const white = Color(0xFFFFFFFF);
  static const bezel = Color(0xFF101214);
  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFE03131);
  static const warning = Color(0xFFF59E0B);
}

class AppTextStyles {
  static const title = TextStyle(
    color: AppColors.text,
    fontSize: 52,
    height: 1.05,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const titleCompact = TextStyle(
    color: AppColors.text,
    fontSize: 40,
    height: 1.08,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const body = TextStyle(
    color: AppColors.text,
    fontSize: 20,
    height: 1.35,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const bodyCompact = TextStyle(
    color: AppColors.text,
    fontSize: 17,
    height: 1.35,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const label = TextStyle(
    color: AppColors.muted,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
}

class AppTheme {
  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.orange,
        secondary: AppColors.navy,
        surface: AppColors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.orange, width: 1.3),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
