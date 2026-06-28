import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' hide TextDirection; // 🟢 تم إضافتها عشان نظبط الوقت والتاريخ

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  static final StreamController<Map<String, dynamic>> notificationStream = StreamController<Map<String, dynamic>>.broadcast();

  static Future<void> setupNotificationsWithSound() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true, 
      badge: true, 
      sound: true, 
      provisional: false,
    );
    
    const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
      'lamma_high_importance_channel', 
      'إشعارات لَمَّة الهامة', 
      description: 'هذه القناة مخصصة للإشعارات التي تتطلب تنبيهاً صوتياً.', 
      importance: Importance.max, 
      playSound: true,
    );

    const AndroidNotificationChannel finalSoundChannel = AndroidNotificationChannel(
      'lamma_final_sound',
      'تنبيهات لمة الفورية',
      description: 'قناة الرحلات العاجلة',
      importance: Importance.max,
      playSound: true,
    );

    final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(highImportanceChannel);
      await androidPlugin.createNotificationChannel(finalSoundChannel);
    }

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, 
      badge: true, 
      sound: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'), 
      iOS: DarwinInitializationSettings(
        requestSoundPermission: true, 
        requestBadgePermission: true, 
        requestAlertPermission: true,
      ),
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("✅ تم الضغط على الإشعار من خدمة الإشعارات: ${response.payload}");
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            notificationStream.add(data);
          } catch (e) {
            debugPrint("❌ خطأ في قراءة بيانات الإشعار: $e");
          }
        }
      },
    );

    // 🟢 استقبال الإشعار وهو في التطبيق وتنسيقه بالشكل الشيك
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      
      if (notification != null && android != null) {
        String targetChannelId = message.data['channel_id'] ?? 'lamma_final_sound';
        String targetChannelName = targetChannelId == 'lamma_high_importance_channel' 
            ? 'إشعارات لَمَّة الهامة' 
            : 'تنبيهات لمة الفورية';

        // 1. تظبيط الوقت والتاريخ بشكل شيك
        final String formattedDate = DateFormat('dd MMM yyyy، hh:mm a', 'ar').format(DateTime.now());

        // 2. بناء الجسم الشيك للإشعار
        String chicBody = '📅 $formattedDate\n\n${notification.body ?? ""}';
        
        // لو بعتنا داتا إضافية في الـ Payload نعرضها
        if (message.data['pickup'] != null) {
          chicBody += '\n📍 من: ${message.data['pickup']}';
        }
        if (message.data['price'] != null) {
          chicBody += '\n💰 السعر المطروح: ${message.data['price']} ج.م';
        }

        // 3. استخدام BigTextStyle عشان الكلام الطويل ميتقصش
        BigTextStyleInformation bigTextStyle = BigTextStyleInformation(
          chicBody,
          htmlFormatBigText: true,
          contentTitle: '<b>${notification.title}</b>', // نخلي العنوان بولد
          htmlFormatContentTitle: true,
          summaryText: 'تطبيق لمة', 
        );

        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode, 
          title: notification.title, 
          body: notification.body, // ده النص العادي للموبايلات القديمة
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              targetChannelId, 
              targetChannelName, 
              channelDescription: 'قناة التنبيهات الفورية والرحلات العاجلة', 
              icon: '@mipmap/ic_launcher', 
              importance: Importance.max, 
              priority: Priority.high,
              playSound: true,
              styleInformation: bigTextStyle, // 🟢 تركيب الاستايل الشيك هنا
              color: const Color(0xFF1A3B2A), // 🟢 اللون الكحلي/الأخضر بتاعك للأيقونة
            ),
            iOS: const DarwinNotificationDetails(presentSound: true),
          ),
          payload: jsonEncode(message.data), 
        );
      }
    });
  }

  static Future<void> sendPushNotification({
    required String targetFcmToken,
    required String title,
    required String body,
    required String tripId,
    required String serverKey,
    String? pickup, // 🟢 اختياري لو حابب تبعت المكان
    String? price,  // 🟢 اختياري لو حابب تبعت السعر
  }) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': targetFcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            'tripId': tripId,
            'channel_id': 'lamma_final_sound',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            if (pickup != null) 'pickup': pickup, // بنبعته في الداتا عشان الـ Listener يقراه
            if (price != null) 'price': price,
          }
        }),
      );
      debugPrint("✅ الإشعار تم إرساله بنجاح");
    } catch (e) {
      debugPrint("❌ خطأ في إرسال الإشعار: $e");
    }
  }
}