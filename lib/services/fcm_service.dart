import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // 1. طلب إذن المستخدم
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. الحصول على الـ Token الخاص بالموبايل الحالي
      String? token = await _messaging.getToken();
      
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
    }
    
    // 3. مراقبة تحديث الـ Token (لو اتغير لأي سبب)
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  // حفظ الـ Token في Firestore عشان نستخدمه لما نحب نبعت إشعار للشخص ده
  Future<void> _saveTokenToDatabase(String token) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fcmToken': token,
    });
  }
}