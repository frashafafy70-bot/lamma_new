import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🟢 استدعاء ملف الـ Router (عشان يتعرف على أسماء المسارات المولدة)
import 'package:lamma_new/core/routes/app_router.dart';

class NavigationService {
  // المفتاح المركزي للتطبيق
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // دالة الشات
  static void navigateToTripChat(String tripId) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      // 🟢 توجيه باستخدام auto_route
      context.router.push(TripChatRoute(tripId: tripId));
    }
  }

  // اللوجيك الذكي للتوجيه بناءً على البيانات القادمة من الإشعار
  static Future<void> handleNotificationRouting(
      Map<String, dynamic> data) async {
    // جلب الـ ID سواء كان رقم رحلة أو رقم حجز مقعد
    String? id = data['tripId'] ?? data['bookingId'];
    String? type = data['type'];

    debugPrint("🔔 توجيه الإشعار - النوع: $type, المعرف: $id");

    final context = navigatorKey.currentContext;
    if (id == null || context == null) return;

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
          var doc = await FirebaseFirestore.instance
              .collection('trips')
              .doc(id)
              .get();
          if (doc.exists) {
            var tripData = doc.data()!;
            if (tripData['driverId'] == currentUserId) {
              // 🚕 المستخدم هو الكابتن -> يروح للرادار (واللي جواه رحلاته النشطة كـ Tab)
              context.router.push(const DriverRadarRoute());
            } else {
              // 👤 المستخدم هو العميل
              // 🛑 نتأكد إن الحالة مش تفاوض أو قيد الانتظار قبل ما نفتح التتبع
              if (tripData['status'] != 'negotiating' &&
                  tripData['status'] != 'pending') {
                context.router.push(PassengerTripTrackingRoute(
                  tripId: id,
                  passengerId: currentUserId,
                ));
              }
            }
          }
        } catch (e) {
          debugPrint("خطأ في جلب بيانات الرحلة للتوجيه: $e");
        }
        break;

      case 'new_trip_request':
        // 📡 إشعار الرادار (للكابتن) -> يروح للرادار
        context.router.push(const DriverRadarRoute());
        break;

      case 'new_booking':
        // 💺 طلب حجز مقعد جديد (للكابتن) -> يروح للرادار
        context.router.push(const DriverRadarRoute());
        break;

      case 'booking_accepted':
        // 🎉 تم قبول الحجز (للعميل) -> يروح لتتبع رحلته
        context.router.push(PassengerTripTrackingRoute(
          tripId: id,
          passengerId: currentUserId,
        ));
        break;

      default:
        debugPrint("⚠️ نوع إشعار غير معروف: $type");
        break;
    }
  }
}