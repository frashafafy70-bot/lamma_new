import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_active_trips_tab.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_radar_tab.dart';
// 🟢 الاستيراد رجع يشتغل تمام بعد ما حطيت الكود الصح في الملف
import 'package:lamma_new/features/trips/presentation/pages/passenger_tabs/passenger_trip_tracking_page.dart';

class NavigationService {
  // المفتاح المركزي للتطبيق
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // دالة الشات
  static void navigateToTripChat(String tripId) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (_) => TripChatPage(tripId: tripId)),
      );
    }
  }

  // اللوجيك الذكي للتوجيه بناءً على البيانات القادمة من الإشعار
  static Future<void> handleNotificationRouting(Map<String, dynamic> data) async {
    // جلب الـ ID سواء كان رقم رحلة أو رقم حجز مقعد
    String? id = data['tripId'] ?? data['bookingId'];
    String? type = data['type']; 

    debugPrint("🔔 توجيه الإشعار - النوع: $type, المعرف: $id");

    if (id == null || navigatorKey.currentState == null) return;

    // 🟢 نجيب الـ ID بتاع المستخدم الحالي (عشان نباصيه لصفحة العميل)
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    switch (type) {
      case 'chat':
        // 💬 توجيه للشات مباشرة
        navigateToTripChat(id);
        break;

      case 'negotiation_offer':
      case 'active_trip':
        if (currentUserId.isEmpty) return;

        try {
          var doc = await FirebaseFirestore.instance.collection('trips').doc(id).get();
          if (doc.exists) {
            var tripData = doc.data()!;
            if (tripData['driverId'] == currentUserId) {
              // 🚕 المستخدم هو الكابتن -> يروح لرحلاته النشطة
              navigatorKey.currentState!.push(MaterialPageRoute(
                builder: (_) => const DriverActiveTripsTab(), 
              ));
            } else {
              // 👤 المستخدم هو العميل -> يروح لصفحة تتبع الرحلة الخاصة به
              navigatorKey.currentState!.push(MaterialPageRoute(
                builder: (_) => PassengerTripTrackingPage(
                  tripId: id,
                  passengerId: currentUserId, // 🟢 تم تمرير معرف العميل هنا
                ),
              ));
            }
          }
        } catch (e) {
          debugPrint("خطأ في جلب بيانات الرحلة للتوجيه: $e");
        }
        break;

      case 'new_trip_request':
        // 📡 إشعار الرادار (للكابتن) -> يروح للرادار
        navigatorKey.currentState!.push(MaterialPageRoute(
          builder: (_) => const DriverRadarTab(),
        ));
        break;

      case 'new_booking':
        // 💺 طلب حجز مقعد جديد (للكابتن) -> يروح لرحلاته النشطة
        navigatorKey.currentState!.push(MaterialPageRoute(
          builder: (_) => const DriverActiveTripsTab(),
        ));
        break;

      case 'booking_accepted':
        // 🎉 تم قبول الحجز (للعميل) -> يروح لتتبع رحلته
        navigatorKey.currentState!.push(MaterialPageRoute(
          builder: (_) => PassengerTripTrackingPage(
            tripId: id,
            passengerId: currentUserId, // 🟢 وتم تمريره هنا كمان
          ),
        ));
        break;

      default:
        debugPrint("⚠️ نوع إشعار غير معروف: $type");
        break;
    }
  }
}