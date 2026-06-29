import 'package:flutter/material.dart';

class AppColors {
  // ==========================================
  // الألوان الأساسية (Primary & Secondary)
  // ==========================================
  static const Color primaryDark = Color(0xFF131E31); // الكحلي الفخم
  static const Color royalGreen = Color(0xFF1A3B2A); // الأخضر الملكي للرحلات
  static const Color accentGold = Color(0xFFF3C444); // الذهبي المميز

  // درجات فاتحة (شفافة) مفيدة جداً للخلفيات في الأيقونات وتأثيرات الرادار
  static final Color primaryDarkLight = const Color(0xFF131E31).withValues(alpha: 0.1);
  static final Color royalGreenLight = const Color(0xFF1A3B2A).withValues(alpha: 0.1);
  static final Color accentGoldLight = const Color(0xFFF3C444).withValues(alpha: 0.1);

  // ==========================================
  // ألوان الخلفيات والنصوص
  // ==========================================
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  
  // ==========================================
  // ألوان الحالات والنصوص الفرعية (MaterialColor)
  // (تم الحفاظ عليها لدعم درجات مثل shade400)
  // ==========================================
  static const MaterialColor textMuted = Colors.grey; 
  static const MaterialColor success = Colors.green;
  static const MaterialColor error = Colors.red;
  static const MaterialColor warning = Colors.orange;
  static const MaterialColor info = Colors.blue;

  // ==========================================
  // ألوان الحدود والفواصل (Borders & Dividers)
  // ==========================================
  static const Color dividerColor = Color(0xFFE9ECEF);
}