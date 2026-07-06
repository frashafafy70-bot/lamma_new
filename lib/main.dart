// ignore_for_file: use_build_context_synchronously

import 'dart:ui'; 
import 'package:flutter/material.dart'; 
import 'package:flutter/foundation.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; 
import 'firebase_options.dart';

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/services/navigation_service.dart';
import 'package:lamma_new/core/services/fcm_service.dart';
import 'package:lamma_new/core/services/notification_service.dart';

import 'features/auth/presentation/pages/login_page.dart'; 
import 'features/auth/cubit/auth_cubit.dart'; 
import 'features/auth/data/services/auth_service.dart'; 

// 🟢 استيرادات الـ Clean Architecture الخاصة بالـ Auth
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/use_cases/login_use_case.dart';
import 'features/auth/domain/use_cases/sign_up_use_case.dart';
import 'features/auth/domain/use_cases/sign_out_use_case.dart';
import 'features/auth/domain/use_cases/auth_advanced_use_cases.dart';

import 'features/trips/cubit/shared/trip_actions_cubit.dart'; 
import 'package:lamma_new/features/home/home_page.dart'; 

import 'package:lamma_new/features/home/cubit/home_cubit.dart';
import 'package:lamma_new/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:lamma_new/features/trips/domain/usecases/get_driver_active_orders_usecase.dart';
import 'package:lamma_new/features/trips/domain/usecases/get_passenger_active_orders_usecase.dart';
import 'package:lamma_new/features/trips/domain/usecases/add_travel_trip_usecase.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';

// 🟢 استيرادات كيوبت و ريبوزيتوري الشات
import 'package:lamma_new/features/trips/cubit/shared/trip_chat_cubit.dart';
import 'package:lamma_new/features/trips/data/repositories/chat_repository_impl.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
            // 🟢 تم تحديث الـ AuthCubit ليعمل بالـ Clean Architecture بالكامل
            BlocProvider(
              create: (context) {
                final authService = AuthService();
                final authRepository = AuthRepositoryImpl(authService);
                
                return AuthCubit(
                  loginUseCase: LoginUseCase(authRepository),
                  signUpUseCase: SignUpUseCase(authRepository),
                  signOutUseCase: SignOutUseCase(authRepository),
                  loginWithGoogleUseCase: LoginWithGoogleUseCase(authRepository),
                  sendSignUpOtpUseCase: SendSignUpOtpUseCase(authRepository),
                  verifyOtpAndSignUpUseCase: VerifyOtpAndSignUpUseCase(authRepository),
                );
              },
            ),

            BlocProvider(create: (context) => TripActionsCubit()), 
            BlocProvider(create: (context) => DriverActiveTripsCubit()),
            
            // 🟢 تم إضافة كيوبت الشات هنا ليعمل على مستوى التطبيق
            BlocProvider(
              create: (context) => TripChatCubit(
                chatRepository: ChatRepositoryImpl(), 
              ),
            ),
            
            BlocProvider(
              create: (context) {
                final tripRepository = TripRepositoryImpl();
                return HomeCubit(
                  getDriverActiveOrders: GetDriverActiveOrdersCountUseCase(tripRepository),
                  getPassengerActiveOrders: GetPassengerActiveOrdersCountUseCase(tripRepository),
                  addTravelTripUseCase: AddTravelTripUseCase(tripRepository),
                )..loadUserProfile();
              },
            ),
          ],
          child: MaterialApp(
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