import 'package:flutter/material.dart';

enum TripCategory { internal, shopping, travel }

extension TripCategoryExtension on TripCategory {
  // القيمة اللي بتتبعت للسيرفر أو البلوك
  String get value {
    switch (this) {
      case TripCategory.internal:
        return 'داخلي';
      case TripCategory.shopping:
        return 'طلبات';
      case TripCategory.travel:
        return 'سفر';
    }
  }

  // الكلمة اللي بتظهر للمستخدم في الواجهة
  String get displayTitle {
    switch (this) {
      case TripCategory.internal:
        return 'توصيل';
      case TripCategory.shopping:
        return 'شراء طلبات';
      case TripCategory.travel:
        return 'سفر';
    }
  }

  // الأيقونة الخاصة بكل نوع
  IconData get icon {
    switch (this) {
      case TripCategory.internal:
        return Icons.local_taxi_rounded;
      case TripCategory.shopping:
        return Icons.shopping_bag_rounded;
      case TripCategory.travel:
        return Icons.emoji_transportation_rounded;
    }
  }
}
