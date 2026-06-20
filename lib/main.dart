// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; 
import 'package:hive_flutter/hive_flutter.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'firebase_options.dart';

import 'features/auth/presentation/pages/login_page.dart'; 
import 'features/home/home_page.dart'; 

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("رسالة في الخلفية: ${message.messageId}");
}

// 🔔 اسم القناة الجديد والنهائي لمنع تداخل الكاش في الموبايل
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'lamma_final_sound', 
  'تنبيهات لمة الفورية', 
  description: 'قناة الرحلات العاجلة والطلبات.',
  importance: Importance.max, 
  playSound: true, 
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  
  // ✅ التعديل الأول: رجعنا كلمة settings: عشان المحرر طالبها
  // وتم إضافة onDidReceiveNotificationResponse لضمان فتح التطبيق عند الضغط على إشعار الـ Foreground
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings, 
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint("✅ تم الضغط على الإشعار والتطبيق مفتوح: ${response.payload}");
    },
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await Hive.initFlutter();
  await Hive.openBox('lawsuits'); 

  runApp(const LammaApp()); 
}

class LammaApp extends StatefulWidget {
  const LammaApp({super.key});

  @override
  State<LammaApp> createState() => _LammaAppState();
}

class _LammaAppState extends State<LammaApp> {

  @override
  void initState() {
    super.initState();
    _setupPushNotifications();

    // 1. استقبال الإشعارات والتطبيق مفتوح
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        // ✅ التعديل الثاني: رجعنا الأسماء (id, title, body, notificationDetails) 
        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode, 
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'lamma_final_sound', 
              'تنبيهات لمة الفورية', 
              channelDescription: 'قناة الإشعارات الهامة',
              importance: Importance.max, 
              priority: Priority.high,
              playSound: true,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // 2. مراقبة تغيير حالة الدخول
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          _saveTokenToFirestore(token, user.uid);
        }
      }
    });

    // 3. مراقبة تجديد التوكن
    FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _saveTokenToFirestore(newToken, currentUser.uid);
      }
    });
  }

  Future<void> _saveTokenToFirestore(String token, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
      debugPrint('☁️ تم حفظ/تحديث التوكن بنجاح للمستخدم');
    } catch (e) {
      debugPrint('❌ حدث خطأ أثناء حفظ التوكن: $e');
    }
  }

  Future<void> _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ المستخدم وافق على الإشعارات');
      String? token = await messaging.getToken();
      debugPrint('📱 FCM Token: $token'); 
      
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && token != null) {
        _saveTokenToFirestore(token, user.uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'EG')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        useMaterial3: true,
        fontFamily: 'Cairo', 
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.hasData ?  HomePage() :  LoginPage(); 
        },
      ), 
    );
  }
}