import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:lamma_new/core/services/notification_service.dart';
import 'package:lamma_new/core/services/navigation_service.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initFCM() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true, 
          badge: true, 
          sound: true,
        );

        String? token = await _messaging.getToken();
        if (token != null) {
          _updateTokenInDatabase(token);
        }
        
        _messaging.onTokenRefresh.listen(_updateTokenInDatabase);

        FirebaseAuth.instance.authStateChanges().listen((User? user) async {
          if (user != null) {
            String? currentToken = await _messaging.getToken();
            if (currentToken != null) {
              _updateTokenInDatabase(currentToken);
            }
          }
        });

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Got a foreground message: ${message.notification?.title}');
          NotificationService.showChicNotification(message);
        });

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('Notification clicked from background!');
          NavigationService.handleNotificationRouting(message.data);
        });

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

  static Future<void> _updateTokenInDatabase(String token) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint("Update Token Error: $e");
    }
  }

  static Future<void> subscribeToDriversRadar() async {
    try {
      await _messaging.subscribeToTopic('drivers_radar');
      debugPrint("Subscribed to drivers_radar topic");
    } catch (e) {
      debugPrint("Error subscribing to topic: $e");
    }
  }

  static Future<void> unsubscribeFromDriversRadar() async {
    try {
      await _messaging.unsubscribeFromTopic('drivers_radar');
      debugPrint("Unsubscribed from drivers_radar topic");
    } catch (e) {
      debugPrint("Error unsubscribing from topic: $e");
    }
  }
}