import 'package:flutter/material.dart';

class AppTheme {
  // الألوان الأساسية المستوحاة من الهوية الحمراء الأنيقة
  static const Color primaryRed = Color(0xFFDD322F); // الأحمر الأساسي
  static const Color accentRed = Color(0xFFFF5252);  // الأحمر الفاتح للتطعيم
  static const Color darkRed = Color(0xFF9A0007);    // الأحمر الداكن (تم تصحيحه هنا ✅)

  // إعدادات الوضع الفاتح (Light Mode)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryRed,
      scaffoldBackgroundColor: const Color(0xFFF9F9F9), // خلفية بيضاء مريحة للعين
      
      // إعدادات الألوان العامة
      colorScheme: const ColorScheme.light(
        primary: primaryRed,
        secondary: accentRed,
        surface: Colors.white,
        error: Color(0xFFD32F2F),
      ),

      // ثيم شريط التطبيق العلوي (AppBar)
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      // ثيم النصوص للوضع الفاتح
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
      ),
    );
  }

  // إعدادات الوضع الداكن (Dark Mode)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryRed,
      scaffoldBackgroundColor: const Color(0xFF121212), // خلفية داكنة مريحة
      
      // إعدادات الألوان العامة للوضع الداكن
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        secondary: accentRed,
        surface: Color(0xFF1E1E1E),
        error: Color(0xFFCF6679),
      ),

      // ثيم شريط التطبيق العلوي للوضع الداكن
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      // ثيم النصوص للوضع الداكن
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white54),
      ),
    );
  }
}