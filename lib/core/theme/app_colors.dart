import 'package:flutter/material.dart';

class AppColors {
  // ==========================================
  // الألوان الأساسية (الهوية: كحلي، أخضر ملكي، ذهبي)
  // ==========================================
  static const Color primaryNavy = Color(0xFF0F172A); // الكحلي الفخم
  static const Color primaryDark = Color(0xFF0F172A); // (بديل لنفس اللون لتوافق الكود)
  static const Color royalGreen = Color(0xFF1B4332);  // الأخضر الملكي
  static const Color accentGold = Color(0xFFD4AF37);  // الذهبي
  static const Color medicalTeal = Color(0xFF0D9488); // لون القسم الطبي

  // ==========================================
  // درجات شفافة (مكتوبة بـ Hex لدعم الـ const)
  // 1A = 10% Opacity
  // ==========================================
  static const Color primaryDarkLight = Color(0x1A0F172A);
  static const Color royalGreenLight = Color(0x1A1B4332);
  static const Color accentGoldLight = Color(0x1AD4AF37);
  static const Color medicalTealLight = Color(0x1A0D9488);

  // ==========================================
  // ألوان الخلفيات والكروت
  // ==========================================
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardWhite = Colors.white;
  static const Color cardDark = Color(0xFF1E1E1E);

  // ==========================================
  // ألوان النصوص
  // ==========================================
  static const Color textDark = Color(0xFF1E293B); 
  static const Color textWhite = Colors.white;
  // تم إعادتها إلى MaterialColor لحل مشكلة shade300 و shade600
  static const MaterialColor textMuted = Colors.grey; 

  // ==========================================
  // ألوان الحالات (MaterialColor)
  // ==========================================
  static const MaterialColor success = Colors.green;
  static const MaterialColor error = Colors.red;
  static const MaterialColor warning = Colors.orange;
  static const MaterialColor info = Colors.blue;

  // ==========================================
  // ألوان الحدود والفواصل
  // ==========================================
  static const Color dividerColor = Color(0xFFE2E8F0);
}