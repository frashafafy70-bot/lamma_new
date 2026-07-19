// ignore_for_file: use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:lamma_new/l10n/app_localizations.dart';
import 'firebase_options.dart';

// 🟢 استدعاء ملفات الثيم
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/theme/app_theme.dart';

import 'package:lamma_new/core/services/navigation_service.dart';
import 'package:lamma_new/core/services/fcm_service.dart';
import 'package:lamma_new/core/services/notification_service.dart';

import 'package:lamma_new/core/di/injection_container.dart' as di;

import 'package:lamma_new/core/network/network_cubit.dart';
import 'package:lamma_new/core/network/network_state.dart';

import 'package:lamma_new/core/local_storage/cache_helper.dart';
import 'package:lamma_new/core/routes/app_router.dart';

import 'package:lamma_new/features/auth/cubit/auth_cubit.dart';

import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_chat_cubit.dart';

import 'package:lamma_new/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:lamma_new/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:lamma_new/features/home/cubit/home_cubit.dart';

import 'package:lamma_new/features/trips/trip_injection.dart';
import 'package:lamma_new/features/trips/presentation/cubit/trip_cubit.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('--- 1. Widgets Initialized ---');

  await dotenv.load(fileName: ".env");
  debugPrint('--- 2. DotEnv Loaded ---');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('--- 3. Firebase Initialized ---');

  await CacheHelper.init();
  debugPrint('--- 4. CacheHelper Initialized ---');

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 52428800,
  );
  debugPrint('--- 5. Firestore Settings Applied ---');

  await di.initDI();
  debugPrint('--- 6. DI Initialized ---');

  initTripModule();
  debugPrint('--- 7. Trip Module Initialized ---');

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
    debugPrint('--- 8. Local Notifications Initialized ---');

    await FCMService.initFCM();
    debugPrint('--- 9. FCM Initialized ---');
  }

  // 🟢 ربط الـ navigatorKey الخاص بـ NavigationService بـ AppRouter
  final appRouter = AppRouter(navigatorKey: NavigationService.navigatorKey);
  debugPrint('--- 10. App Router Created ---');

  debugPrint('--- 11. Starting runApp ---');
  runApp(LammaApp(appRouter: appRouter));
}

class LammaApp extends StatelessWidget {
  final AppRouter appRouter;

  const LammaApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => di.sl<NetworkCubit>()),
            BlocProvider(create: (context) => di.sl<AuthCubit>()),
            BlocProvider(create: (context) => di.sl<NotificationCubit>()),
            BlocProvider(create: (context) => di.sl<ProfileCubit>()),
            BlocProvider(create: (context) => di.sl<TripActionsCubit>()),
            BlocProvider(create: (context) => di.sl<DriverActiveTripsCubit>()),
            BlocProvider(create: (context) => di.sl<TripChatCubit>()),
            BlocProvider(create: (context) => di.sl<HomeCubit>()),
            BlocProvider(create: (context) => di.sl<TripCubit>()),
          ],
          child: MaterialApp.router(
            builder: (context, widget) {
              return BlocBuilder<NetworkCubit, NetworkState>(
                builder: (context, networkState) {
                  return Stack(
                    children: [
                      if (widget != null) widget,
                      if (networkState is NetworkDisconnected)
                        Positioned(
                          top: MediaQuery.of(context).padding.top,
                          left: 0,
                          right: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              decoration: BoxDecoration(
                                  color: Colors.redAccent.shade700,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    )
                                  ]),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.wifi_off_rounded,
                                      color: Colors.white, size: 18.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .noInternetConnection,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
            debugShowCheckedModeBanner: false,

            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),

            // 🟢 استخدام ملف الـ AppTheme للتحكم الكامل في ألوان وستايل التطبيق
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system, // هيغير حسب إعدادات جهاز المستخدم

            routerConfig: appRouter.config(),
          ),
        );
      },
    );
  }
}
