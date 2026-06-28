import 'package:flutter/material.dart';

class AppColors {
  // الألوان الأساسية للتطبيق (ألوان مخصصة Hex)
  static const Color primaryDark = Color(0xFF131E31); // الكحلي الفخم
  static const Color accentGold = Color(0xFFF3C444); // الذهبي المميز
  static const Color royalGreen = Color(0xFF1A3B2A); // الأخضر الملكي للرحلات
  
  // ألوان الحالات (تم تحويلها لـ MaterialColor عشان تقبل درجات زي shade400)
  static const MaterialColor success = Colors.green;
  static const MaterialColor error = Colors.red;
  static const MaterialColor warning = Colors.orange;
  static const MaterialColor info = Colors.blue;

  // ألوان الخلفيات والنصوص
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  
  // 🟢 التعديل الأهم هنا: تحويلها لـ MaterialColor
  static const MaterialColor textMuted = Colors.grey; 
}