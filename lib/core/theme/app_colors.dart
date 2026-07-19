import 'package:flutter/material.dart';

class AppColors {
  // ==========================================
  // الألوان الأساسية (الهوية: كحلي، أخضر ملكي، ذهبي)
  // ==========================================
  static const Color primaryNavy = Color(0xFF0F172A); // الكحلي الفخم
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color royalGreen = Color(0xFF1B4332); // الأخضر الملكي
  static const Color accentGold = Color(0xFFD4AF37); // الذهبي
  static const Color medicalTeal = Color(0xFF0D9488); // لون القسم الطبي

  // ==========================================
  // درجات شفافة (مكتوبة بـ Hex لدعم الـ const)
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
  static const Color textMuted = Color(0xFF9E9E9E); // تم إرجاعها كـ Color صافي

  // ==========================================
  // ألوان الحالات (Color عادي لتتوافق مع الـ Extension)
  // ==========================================
  static const Color success = Color(0xFF4CAF50); // الأخضر
  static const Color error = Color(0xFFF44336); // الأحمر
  static const Color warning = Color(0xFFFF9800); // البرتقالي
  static const Color info = Color(0xFF2196F3); // الأزرق

  // ==========================================
  // ألوان الحدود والفواصل
  // ==========================================
  static const Color dividerColor = Color(0xFFE2E8F0);
}

// ==========================================
// 🚀 Senior Plus Extension 🚀
// هذا الامتداد يمنح أي لون (Color) القدرة على توليد ظلاله تلقائياً
// مما سيقضي على كل أخطاء .shade300 و .shade500 في باقي الملفات
// ==========================================
extension ColorShades on Color {
  Color get shade50 => Color.lerp(this, Colors.white, 0.9)!;
  Color get shade100 => Color.lerp(this, Colors.white, 0.8)!;
  Color get shade200 => Color.lerp(this, Colors.white, 0.6)!;
  Color get shade300 => Color.lerp(this, Colors.white, 0.4)!;
  Color get shade400 => Color.lerp(this, Colors.white, 0.2)!;
  Color get shade500 => this;
  Color get shade600 => Color.lerp(this, Colors.black, 0.1)!;
  Color get shade700 => Color.lerp(this, Colors.black, 0.2)!;
  Color get shade800 => Color.lerp(this, Colors.black, 0.3)!;
  Color get shade900 => Color.lerp(this, Colors.black, 0.4)!;
}
