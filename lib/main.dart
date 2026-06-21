// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'firebase_options.dart';

import 'features/auth/presentation/pages/login_page.dart'; 
import 'features/home/home_page.dart'; 

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

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
  
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ملاحظة: لو ظهرت الأيقونة كمربع أبيض في الإشعارات، قم بتغيير '@mipmap/ic_launcher' 
  // إلى اسم الأيقونة الشفافة التي ستصممها لاحقاً مثل 'ic_notification'
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings, 
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint("✅ تم الضغط على الإشعار من Local Notifications: ${response.payload}");
    },
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

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

    // 1. التعامل مع الإشعار والتطبيق مفتوح (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode, 
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'lamma_final_sound', 
              'تنبيهات لمة الفورية', 
              channelDescription: 'قناة الإشعارات الهامة',
              importance: Importance.max, 
              priority: Priority.high,
              playSound: true,
              icon: '@mipmap/ic_launcher', // نفس ملاحظة الأيقونة هنا
            ),
          ),
        );
      }
    });

    // 2. التعامل مع الضغط على الإشعار والتطبيق في الخلفية (Background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("✅ تم الضغط على الإشعار والتطبيق في الخلفية: ${message.data}");
      // هنا يمكنك إضافة منطق التوجيه (Navigation) لاحقاً
    });

    // 3. التعامل مع الضغط على الإشعار والتطبيق كان مغلق تماماً (Terminated)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint("✅ تم فتح التطبيق من إشعار كان مغلق تماماً: ${message.data}");
        // هنا يمكنك إضافة منطق التوجيه (Navigation) لاحقاً
      }
    });

    // مراقبة حالة تسجيل الدخول وحفظ التوكن
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) _saveTokenToFirestore(token, user.uid);
      }
    });

    // تحديث التوكن في حال تغيره
    FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) _saveTokenToFirestore(newToken, currentUser.uid);
    });
  }

  Future<void> _saveTokenToFirestore(String token, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('❌ خطأ حفظ التوكن: $e');
    }
  }

  Future<void> _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    String? token = await messaging.getToken();
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) _saveTokenToFirestore(token, user.uid);
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
          return snapshot.hasData ? HomePage() : LoginPage(); 
        },
      ), 
    );
  }
}