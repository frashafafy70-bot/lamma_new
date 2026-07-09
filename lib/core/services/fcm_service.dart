import 'package:firebase_messaging/firebase_messaging.dart'; // 🟢 تم تصحيح حرف I
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:lamma_new/core/services/notification_service.dart';
import 'package:lamma_new/core/services/navigation_service.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initFCM() async {
    try {
      // 1. طلب الصلاحيات
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // إعداد عرض الإشعارات والتطبيق مفتوح لـ iOS
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true, 
          badge: true, 
          sound: true,
        );

        // 2. جلب التوكن الأولي وتحديثه في الداتا بيز
        String? token = await _messaging.getToken();
        if (token != null) {
          _updateTokenInDatabase(token);
        }
        
        // 3. مراقبة تغير التوكن
        _messaging.onTokenRefresh.listen(_updateTokenInDatabase);

        // 4. (اللوجيك اللي رجعناه) مراقبة حالة تسجيل الدخول لتحديث التوكن فوراً
        FirebaseAuth.instance.authStateChanges().listen((User? user) async {
          if (user != null) {
            String? currentToken = await _messaging.getToken();
            if (currentToken != null) {
              _updateTokenInDatabase(currentToken);
            }
          }
        });

        // 5. الاستماع للإشعارات في الـ Foreground (التطبيق مفتوح)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Got a foreground message: ${message.notification?.title}');
          // تمرير الإشعار للرسام لعرضه بالشكل الشيك بتاعك
          NotificationService.showChicNotification(message);
        });

        // 6. الاستماع للضغط على الإشعار والتطبيق في الخلفية
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('Notification clicked from background!');
          NavigationService.handleNotificationRouting(message.data);
        });

        // 7. الاستماع للضغط على الإشعار والتطبيق مغلق تماماً
        _messaging.getInitialMessage().then((RemoteMessage? message) {
          if (message != null) {
            Future.delayed(const Duration(milliseconds: 500), () {
              NavigationService.handleNotificationRouting(message.data);
            });
          }
        });
      }
    } catch (e) {
      debugPrint("FCM Init Error: $e");
    }
  }

  // تحديث التوكن في الفايرستور
  static Future<void> _updateTokenInDatabase(String token) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {'fcmToken': token},
        SetOptions(merge: true), // استخدمنا merge عشان منمسحش داتا اليوزر
      );
    } catch (e) {
      debugPrint("Update Token Error: $e");
    }
  }

  // ==========================================
  // دوال إضافية خاصة بتطبيق لمة
  // ==========================================

  // استدعاء هذه الدالة عندما يسجل المستخدم كـ "سائق" أو يفتح التطبيق وهو سائق
  static Future<void> subscribeToDriversRadar() async {
    try {
      await _messaging.subscribeToTopic('drivers_radar');
      debugPrint("Subscribed to drivers_radar topic");
    } catch (e) {
      debugPrint("Error subscribing to topic: $e");
    }
  }

  // استدعاء هذه الدالة إذا قام السائق بتسجيل الخروج أو إيقاف استقبال الطلبات
  static Future<void> unsubscribeFromDriversRadar() async {
    try {
      await _messaging.unsubscribeFromTopic('drivers_radar');
      debugPrint("Unsubscribed from drivers_radar topic");
    } catch (e) {
      debugPrint("Error unsubscribing from topic: $e");
    }
  }
}