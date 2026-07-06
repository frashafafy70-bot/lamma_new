import 'package:flutter/material.dart';
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';
// تأكد من استدعاء صفحة الرحلة النشطة الخاصة بالسائق هنا
// import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_active_trips_tab.dart'; 

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

  // دالة ذكية لتوجيه السائق لصفحة الرحلة النشطة (Driver Active Trip)
  static void navigateToDriverActiveTrip(String tripId) {
    if (navigatorKey.currentState != null) {
      // قم بتفعيل هذا الكود وتوجيهه للصفحة الصحيحة لديك
      /*
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => DriverActiveTripsTab(tripId: tripId),
        ),
      );
      */
      debugPrint("🚀 تم التوجيه إلى رحلة السائق النشطة: $tripId");
    }
  }

  // اللوجيك الذكي للتوجيه بناءً على البيانات القادمة من الإشعار
  static void handleNotificationRouting(Map<String, dynamic> data) {
    String? tripId = data['tripId'];
    String? type = data['type']; // حدد نوع الإشعار من الباك إند

    if (tripId != null) {
      if (type == 'chat') {
        navigateToTripChat(tripId);
      } else if (type == 'active_trip') {
        navigateToDriverActiveTrip(tripId);
      } else {
        // التوجيه الافتراضي
        navigateToTripChat(tripId); 
      }
    }
  }
}