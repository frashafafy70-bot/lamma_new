import 'package:flutter/material.dart';
import 'package:lamma_new/core/theme/app_colors.dart'; // 🟢 استدعاء ملف الألوان النظيف

// ==========================================
// 1. Theme Extension
// ==========================================
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primaryNavy;
  final Color primaryDarkLight;
  final Color accentGold;
  final Color accentGoldLight;
  final Color royalGreen;
  final Color royalGreenLight;
  final Color medicalTeal;
  final Color medicalTealLight;

  const AppColorsExtension({
    required this.primaryNavy,
    required this.primaryDarkLight,
    required this.accentGold,
    required this.accentGoldLight,
    required this.royalGreen,
    required this.royalGreenLight,
    required this.medicalTeal,
    required this.medicalTealLight,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? primaryNavy,
    Color? primaryDarkLight,
    Color? accentGold,
    Color? accentGoldLight,
    Color? royalGreen,
    Color? royalGreenLight,
    Color? medicalTeal,
    Color? medicalTealLight,
  }) {
    return AppColorsExtension(
      primaryNavy: primaryNavy ?? this.primaryNavy,
      primaryDarkLight: primaryDarkLight ?? this.primaryDarkLight,
      accentGold: accentGold ?? this.accentGold,
      accentGoldLight: accentGoldLight ?? this.accentGoldLight,
      royalGreen: royalGreen ?? this.royalGreen,
      royalGreenLight: royalGreenLight ?? this.royalGreenLight,
      medicalTeal: medicalTeal ?? this.medicalTeal,
      medicalTealLight: medicalTealLight ?? this.medicalTealLight,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
      ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      primaryNavy: Color.lerp(primaryNavy, other.primaryNavy, t)!,
      primaryDarkLight:
          Color.lerp(primaryDarkLight, other.primaryDarkLight, t)!,
      accentGold: Color.lerp(accentGold, other.accentGold, t)!,
      accentGoldLight: Color.lerp(accentGoldLight, other.accentGoldLight, t)!,
      royalGreen: Color.lerp(royalGreen, other.royalGreen, t)!,
      royalGreenLight: Color.lerp(royalGreenLight, other.royalGreenLight, t)!,
      medicalTeal: Color.lerp(medicalTeal, other.medicalTeal, t)!,
      medicalTealLight:
          Color.lerp(medicalTealLight, other.medicalTealLight, t)!,
    );
  }
}

// ==========================================
// 2. الكلاس الأساسي للثيم (AppTheme)
// ==========================================
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      brightness: Brightness.light,
      primaryColor: AppColors.primaryDark,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryDark,
        secondary: AppColors.accentGold,
        surface: AppColors.cardWhite,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.textDark),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.textMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerColor,
        thickness: 1,
      ),
      extensions: const [
        AppColorsExtension(
          primaryNavy: AppColors.primaryNavy,
          primaryDarkLight: AppColors.primaryDarkLight,
          accentGold: AppColors.accentGold,
          accentGoldLight: AppColors.accentGoldLight,
          royalGreen: AppColors.royalGreen,
          royalGreenLight: AppColors.royalGreenLight,
          medicalTeal: AppColors.medicalTeal,
          medicalTealLight: AppColors.medicalTealLight,
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryDark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark,
        secondary: AppColors.accentGold,
        surface: AppColors.cardDark,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cardDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white54),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.dividerColor.withValues(alpha: 0.1),
        thickness: 1,
      ),
      extensions: const [
        AppColorsExtension(
          primaryNavy: AppColors.primaryNavy,
          primaryDarkLight: AppColors.primaryDarkLight,
          accentGold: AppColors.accentGold,
          accentGoldLight: AppColors.accentGoldLight,
          royalGreen: AppColors.royalGreen,
          royalGreenLight: AppColors.royalGreenLight,
          medicalTeal: AppColors.medicalTeal,
          medicalTealLight: AppColors.medicalTealLight,
        ),
      ],
    );
  }
}
