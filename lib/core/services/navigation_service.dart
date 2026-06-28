import 'package:flutter/material.dart';
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';

class NavigationService {
  // المفتاح المركزي للتطبيق
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // دالة ذكية للتوجيه لصفحة الشات من أي مكان
  static void navigateToTripChat(String tripId) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => TripChatPage(tripId: tripId),
        ),
      );
    }
  }

  // مستقبلاً: تقدر تضيف دوال هنا لفتح صفحة الرادار أو تفاصيل الرحلة إلخ...
}