// ignore_for_file: use_build_context_synchronously

import 'dart:ui'; 
import 'package:flutter/material.dart'; 
import 'package:flutter/foundation.dart'; // ضروري جداً لشرط kIsWeb
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; 
import 'firebase_options.dart';

// استدعاءات الخدمات الخاصة بيك
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/services/navigation_service.dart';
import 'package:lamma_new/core/services/fcm_service.dart';
import 'package:lamma_new/core/services/notification_service.dart';
import 'package:lamma_new/features/trips/data/services/map_service.dart'; 

import 'features/auth/presentation/pages/login_page.dart'; 
import 'features/auth/cubit/auth_cubit.dart'; 
import 'features/auth/data/services/auth_service.dart'; 
import 'features/home/home_page.dart'; 
import 'features/trips/cubit/shared/trip_actions_cubit.dart'; 

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // بوابة الحماية: خدمات الموبايل فقط لا تعمل على الويب
  if (!kIsWeb) {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await NotificationService.initLocalNotifications();
    await FCMService.initFCM();
  }

  String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  await MapService().init(apiKey: apiKey);

  runApp(const LammaApp()); 
}

class LammaApp extends StatelessWidget {
  const LammaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690), 
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => AuthCubit(AuthService())),
            BlocProvider(create: (context) => TripActionsCubit()), 
          ],
          child: MaterialApp(
            // 🟢 التعديل اللي بيخلي التطبيق ملموم في النص ومقاسه موبايل دايماً
            builder: (context, widget) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: widget,
                ),
              );
            },
            
            navigatorKey: NavigationService.navigatorKey, 
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ar', 'EG')],
            theme: ThemeData(
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