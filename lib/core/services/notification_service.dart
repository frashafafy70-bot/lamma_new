import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart' hide TextDirection; 
import 'package:lamma_new/core/services/navigation_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  static final StreamController<Map<String, dynamic>> notificationStream = StreamController<Map<String, dynamic>>.broadcast();

  static Future<void> initLocalNotifications() async {
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
      description: 'قناة الرحلات العاجلة والطلبات.',
      importance: Importance.max,
      playSound: true,
    );

    final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(highImportanceChannel);
      await androidPlugin.createNotificationChannel(finalSoundChannel);
    }

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
        debugPrint("✅ تم الضغط على الإشعار المحلي: ${response.payload}");
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            NavigationService.handleNotificationRouting(data);
          } catch (e) {
            debugPrint("❌ خطأ في قراءة بيانات الإشعار: $e");
          }
        }
      },
    );
  }

  // عرض الإشعار بالشكل الشيك
  static void showChicNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification != null && android != null) {
      String targetChannelId = message.data['channel_id'] ?? 'lamma_final_sound';
      String targetChannelName = targetChannelId == 'lamma_high_importance_channel' 
          ? 'إشعارات لَمَّة الهامة' 
          : 'تنبيهات لمة الفورية';

      final String formattedDate = DateFormat('dd MMM yyyy، hh:mm a', 'ar').format(DateTime.now());

      String chicBody = '📅 $formattedDate\n\n${notification.body ?? ""}';
      
      if (message.data['pickup'] != null) {
        chicBody += '\n📍 من: ${message.data['pickup']}';
      }
      if (message.data['price'] != null) {
        chicBody += '\n💰 السعر المطروح: ${message.data['price']} ج.م';
      }

      BigTextStyleInformation bigTextStyle = BigTextStyleInformation(
        chicBody,
        htmlFormatBigText: true,
        contentTitle: '<b>${notification.title}</b>', 
        htmlFormatContentTitle: true,
        summaryText: 'تطبيق لمة', 
      );

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
            styleInformation: bigTextStyle, 
            color: const Color(0xFF1B4332), 
          ),
          iOS: const DarwinNotificationDetails(presentSound: true),
        ),
        payload: jsonEncode(message.data), 
      );
    }
  }
}