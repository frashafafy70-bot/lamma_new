import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

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
        debugPrint("✅ تم الضغط على الإشعار: ${response.payload}");
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      
      if (notification != null && android != null) {
        String targetChannelId = message.data['channel_id'] ?? 'lamma_final_sound';
        String targetChannelName = targetChannelId == 'lamma_high_importance_channel' 
            ? 'إشعارات لَمَّة الهامة' 
            : 'تنبيهات لمة الفورية';

        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode, 
          title: notification.title, 
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              targetChannelId, 
              targetChannelName, 
              channelDescription: 'قناة التنبيهات الفورية والرحلات العاجلة', 
              icon: '@mipmap/ic_launcher', 
              importance: Importance.max, 
              priority: Priority.high,
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(presentSound: true),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });
  }
}