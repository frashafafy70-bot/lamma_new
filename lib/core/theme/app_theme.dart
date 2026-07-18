import 'package:flutter/material.dart';
import 'app_colors.dart'; // ⚠️ تأكد من مسار ملف الألوان

// ==========================================
// 1. Theme Extension (لدعم الألوان المخصصة بشكل احترافي)
// ==========================================
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primaryNavy;
  final Color accentGold;
  final Color royalGreen;
  final Color royalGreenLight;
  final Color medicalTeal;

  const AppColorsExtension({
    required this.primaryNavy,
    required this.accentGold,
    required this.royalGreen,
    required this.royalGreenLight,
    required this.medicalTeal,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? primaryNavy, 
    Color? accentGold,
    Color? royalGreen,
    Color? royalGreenLight,
    Color? medicalTeal,
  }) {
    return AppColorsExtension(
      primaryNavy: primaryNavy ?? this.primaryNavy,
      accentGold: accentGold ?? this.accentGold,
      royalGreen: royalGreen ?? this.royalGreen,
      royalGreenLight: royalGreenLight ?? this.royalGreenLight,
      medicalTeal: medicalTeal ?? this.medicalTeal,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      primaryNavy: Color.lerp(primaryNavy, other.primaryNavy, t)!,
      accentGold: Color.lerp(accentGold, other.accentGold, t)!,
      royalGreen: Color.lerp(royalGreen, other.royalGreen, t)!,
      royalGreenLight: Color.lerp(royalGreenLight, other.royalGreenLight, t)!,
      medicalTeal: Color.lerp(medicalTeal, other.medicalTeal, t)!,
    );
  }
}

// ==========================================
// 2. الكلاس الأساسي للثيم (AppTheme)
// ==========================================
class AppTheme {
  
  // ------------------------------------------
  // إعدادات الوضع الفاتح (Light Mode)
  // ------------------------------------------
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
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
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
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
          accentGold: AppColors.accentGold,
          royalGreen: Color(0xFF1B4332), // استبدلها بـ AppColors.royalGreen لو موجودة
          royalGreenLight: Color(0xFF2D6A4F), // استبدلها بـ AppColors.royalGreenLight
          medicalTeal: Color(0xFF008080), // استبدلها بـ AppColors.medicalTeal
        ),
      ],
    );
  }

  // ------------------------------------------
  // إعدادات الوضع الداكن (Dark Mode)
  // ------------------------------------------
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
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
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white54),
      ),
      
      dividerTheme: DividerThemeData(
        color: AppColors.dividerColor.withOpacity(0.1),
        thickness: 1,
      ),

      extensions: const [
        AppColorsExtension(
          primaryNavy: AppColors.primaryNavy,
          accentGold: AppColors.accentGold,
          royalGreen: Color(0xFF1B4332), 
          royalGreenLight: Color(0xFF2D6A4F), 
          medicalTeal: Color(0xFF008080), 
        ),
      ],
    );
  }
}