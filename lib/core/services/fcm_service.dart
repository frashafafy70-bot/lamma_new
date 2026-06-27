import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // تهيئة الإشعارات وإرجاع الـ Token للـ Cubit
  static Future<String?> initNotifications() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await _messaging.getToken();
        
        // مراقبة تحديث الـ Token في الخلفية
        _messaging.onTokenRefresh.listen(_updateTokenInDatabase);

        // الاستماع للإشعارات والتطبيق مفتوح (Foreground)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Got a message whilst in the foreground!');
          debugPrint('Message data: ${message.data}');
          if (message.notification != null) {
            debugPrint('Message also contained a notification: ${message.notification?.title}');
            // هنا ممكن تعرض SnackBar أو Dialog بالإشعار الجديد
          }
        });
        
        return token;
      }
      return null;
    } catch (e) {
      debugPrint("FCM Init Error: $e");
      return null;
    }
  }

  // تحديث الـ Token في قاعدة البيانات
  static Future<void> _updateTokenInDatabase(String token) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    } catch (e) {
      debugPrint("Update Token Error: $e");
    }
  }

  // ==========================================
  // دوال إضافية خاصة بتطبيق لمة
  // ==========================================

  // استدعاء هذه الدالة عندما يسجل المستخدم كـ "كابتن" أو يفتح التطبيق وهو كابتن
  static Future<void> subscribeToDriversRadar() async {
    try {
      await _messaging.subscribeToTopic('drivers_radar');
      debugPrint("Subscribed to drivers_radar topic");
    } catch (e) {
      debugPrint("Error subscribing to topic: $e");
    }
  }

  // استدعاء هذه الدالة إذا قام الكابتن بتسجيل الخروج أو إيقاف استقبال الطلبات
  static Future<void> unsubscribeFromDriversRadar() async {
    try {
      await _messaging.unsubscribeFromTopic('drivers_radar');
      debugPrint("Unsubscribed from drivers_radar topic");
    } catch (e) {
      debugPrint("Error unsubscribing from topic: $e");
    }
  }
}