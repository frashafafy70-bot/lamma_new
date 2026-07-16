import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart'; 

import 'package:lamma_new/core/services/navigation_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'lamma_alerts_channel_v2', 
      'تنبيهات لَمَّة الهامة', 
      description: 'هذه القناة مخصصة لإشعارات الرحلات والشات الهامة ذات الأولوية القصوى.',
      importance: Importance.max,
      playSound: true, 
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // 👑 دالة عرض الإشعار والتطبيق مفتوح + تشغيل الصوت المخصص
  static void showChicNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      
      // 🟢 الجراحة هنا: نقلنا كل لوجيك الصوت اللي كان في الكيوبت لمكانه الصح
      try {
        String type = message.data['type'] ?? '';
        
        if (type == 'passenger_offer' || type == 'negotiating' || type == 'passenger_action' || type == 'chat') {
          await _foregroundAlertPlayer.play(AssetSource('audio/ping_pong.mp3'));
        } 
        else if (type == 'new_request' || type == 'trip_accepted' || type == 'new_booking') {
          await _foregroundAlertPlayer.play(AssetSource('audio/edite.mp3'));
        } 
        else if (type == 'trip_cancelled' || type == 'canceled') {
          await _foregroundAlertPlayer.play(AssetSource('audio/cancell.mp3'));
        } 
        else {
          await _foregroundAlertPlayer.play(AssetSource('audio/notification.mp3'));
        }
      } catch (e) {
        debugPrint("خطأ في تشغيل صوت الإشعار: $e");
      }

      _flutterLocalNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'lamma_alerts_channel_v2', 
            'تنبيهات لَمَّة الهامة',
            channelDescription: 'هذه القناة مخصصة لإشعارات الرحلات والشات الهامة ذات الأولوية القصوى.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            playSound: false, // 🤫 سايلنت للسيستم عشان صوتنا يشتغل بمزاج
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
}