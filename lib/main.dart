// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:ui'; 
import 'package:flutter/material.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; 
import 'firebase_options.dart';

// 🟢 استدعاء الثوابت والخدمات (المايسترو)
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/services/navigation_service.dart';

import 'features/auth/presentation/pages/login_page.dart'; 
import 'features/auth/cubit/auth_cubit.dart'; 
import 'features/auth/data/services/auth_service.dart'; 
import 'features/home/home_page.dart'; 

// 🟢 اللوجيك الذكي للتوجيه باستخدام NavigationService
void handleNotificationRouting(Map<String, dynamic> data) {
  if (data.containsKey('tripId')) {
    String tripId = data['tripId'];
    debugPrint("🚀 توجيه ذكي للرحلة: $tripId");
    
    // استخدام المايسترو الجديد للتوجه لصفحة الشات
    NavigationService.navigateToTripChat(tripId);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // يمكننا هنا لاحقاً إضافة لوجيك لتحديث أي بيانات في الخلفية إن لزم الأمر
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'lamma_final_sound', 
  'تنبيهات لمة الفورية', 
  description: 'قناة الرحلات العاجلة والطلبات.',
  importance: Importance.max, 
  playSound: true, 
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // تفعيل Crashlytics لاصطياد أخطاء الـ UI (Flutter)
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // تفعيل Crashlytics لاصطياد أخطاء الخلفية والأساسيات (Async)
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings, 
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint("✅ تم الضغط على الإشعار: ${response.payload}");
      if (response.payload != null) {
        try {
          final Map<String, dynamic> data = jsonDecode(response.payload!);
          handleNotificationRouting(data);
        } catch (e) {
          debugPrint("❌ خطأ: $e");
        }
      }
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

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
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
          payload: jsonEncode(message.data), 
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationRouting(message.data);
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          handleNotificationRouting(message.data);
        });
      }
    });

    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) _saveTokenToFirestore(token, user.uid);
      }
    });

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
    return ScreenUtilInit(
      designSize: const Size(360, 690), 
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return BlocProvider(
          create: (context) => AuthCubit(AuthService()),
          child: MaterialApp(
            // 🟢 ربط المايسترو هنا!
            navigatorKey: NavigationService.navigatorKey, 
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ar', 'EG')],
            theme: ThemeData(
              // 🟢 استخدام ألوان التطبيق الرسمية كقاعدة للثيم
              colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryDark),
              useMaterial3: true,
              fontFamily: 'Cairo', 
            ),
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                return snapshot.hasData ? const HomePage() : const LoginPage(); 
              },
            ), 
          ),
        );
      },
    );
  }
}