import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart'; // 🟢 ضفنا مكتبة الصوت هنا كمان

// استدعاء ملف التوجيه الخاص بك
import 'package:lamma_new/core/services/navigation_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 🟢 مشغل صوتي خفيف خاص بالبانر الأمامي فقط
  static final AudioPlayer _foregroundAlertPlayer = AudioPlayer();

  static Future<void> initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); 

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings, 
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            NavigationService.handleNotificationRouting(data);
          } catch (e) {
            debugPrint("Error parsing notification payload: $e");
          }
        }
      },
    );

    // 🟢 التعديل هنا: إضافة v2 لاسم القناة لإجبار النظام على تفعيل الصوت ومسح الكاش القديم
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'lamma_alerts_channel_v2', 
      'تنبيهات لَمَّة الهامة', 
      description: 'هذه القناة مخصصة لإشعارات الرحلات والشات الهامة ذات الأولوية القصوى.',
      importance: Importance.max,
      playSound: true, // رنين طبيعي وصوت عالي لو التطبيق في الخلفية
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // 👑 دالة عرض الإشعار والتطبيق مفتوح (Foreground) مع لمسة الحرفنة
  static void showChicNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      
      // 🟢 تريكة الحرفنة: تشغيل صوت "بوب" هادي جداً برمجياً مع نزول البانر
      try {
        String type = message.data['type'] ?? '';
        
        // لو الإشعار عبارة عن شات أو أي حركة عادية والتطبيق مفتوح، اديله رنة البوب الفخمة
        // وبنبعد عن حالات التفاوض أو الإلغاء الكبيرة عشان الـ Cubit يتولى صوتها الضخم
        if (type == 'chat' || type == 'new_booking') {
          await _foregroundAlertPlayer.play(AssetSource('audio/pop.mp3'));
        }
      } catch (e) {
        debugPrint("خطأ في تشغيل صوت البوب: $e");
      }

      _flutterLocalNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'lamma_alerts_channel_v2', // 🟢 تحديث اسم القناة هنا أيضاً
            'تنبيهات لَمَّة الهامة',
            channelDescription: 'هذه القناة مخصصة لإشعارات الرحلات والشات الهامة ذات الأولوية القصوى.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            playSound: false, // 🤫 سايلنت من ناحية السيستم عشان الصوت البرمجي الهادي بتاعنا يشتغل بنظافة
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false, // سايلنت للآيفون بره وجوه السيستم، والاعتماد على البرمجة
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
}