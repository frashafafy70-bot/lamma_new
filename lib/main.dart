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
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; 
import 'firebase_options.dart';

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/services/navigation_service.dart';
import 'package:lamma_new/core/services/fcm_service.dart';
import 'package:lamma_new/core/services/notification_service.dart';

import 'package:lamma_new/features/auth/presentation/pages/login_page.dart'; 
import 'package:lamma_new/features/auth/cubit/auth_cubit.dart'; 
import 'package:lamma_new/features/auth/data/services/auth_service.dart'; 
import 'package:lamma_new/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lamma_new/features/auth/domain/use_cases/login_use_case.dart';
import 'package:lamma_new/features/auth/domain/use_cases/sign_up_use_case.dart';
import 'package:lamma_new/features/auth/domain/use_cases/sign_out_use_case.dart';
import 'package:lamma_new/features/auth/domain/use_cases/auth_advanced_use_cases.dart';

import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart'; 
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_chat_cubit.dart';
import 'package:lamma_new/features/trips/data/repositories/chat_repository_impl.dart';

import 'package:lamma_new/features/home/home_page.dart'; 
import 'package:lamma_new/features/notifications/presentation/cubit/notification_cubit.dart';

import 'package:lamma_new/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:lamma_new/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:lamma_new/features/profile/domain/use_cases/get_user_profile_use_case.dart';
import 'package:lamma_new/features/profile/domain/use_cases/update_user_profile_use_case.dart';

import 'package:lamma_new/features/home/cubit/home_cubit.dart';
import 'package:lamma_new/features/home/data/repositories/home_repository_impl.dart';
import 'package:lamma_new/features/home/domain/use_cases/get_service_categories_use_case.dart';
import 'package:lamma_new/features/home/domain/use_cases/get_active_orders_summary_use_case.dart';

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
                  authRepository: authRepository, 
                );
              },
            ),

            BlocProvider(create: (context) => NotificationCubit()),
            
            BlocProvider(
              create: (context) {
                final profileRepository = ProfileRepositoryImpl(
                  auth: FirebaseAuth.instance,
                  firestore: FirebaseFirestore.instance,
                  storage: FirebaseStorage.instance,
                );
                
                return ProfileCubit(
                  getUserProfileUseCase: GetUserProfileUseCase(profileRepository),
                  updateUserProfileUseCase: UpdateUserProfileUseCase(profileRepository),
                  repository: profileRepository, 
                )..loadUserProfile();
              },
            ),

            BlocProvider(create: (context) => TripActionsCubit()), 
            BlocProvider(create: (context) => DriverActiveTripsCubit()),
            
            BlocProvider(
              create: (context) => TripChatCubit(
                chatRepository: ChatRepositoryImpl(), 
              ),
            ),
            
            BlocProvider(
              create: (context) {
                final homeRepository = HomeRepositoryImpl(
                  firestore: FirebaseFirestore.instance,
                  auth: FirebaseAuth.instance,
                );
                
                return HomeCubit(
                  getServiceCategoriesUseCase: GetServiceCategoriesUseCase(homeRepository),
                  getActiveOrdersSummaryUseCase: GetActiveOrdersSummaryUseCase(homeRepository),
                )..fetchHomeDashboardData(); 
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
            // 🟢 الحل الجذري لمنع التخطي المباشر وربطه بالفايرستور
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                
                final user = snapshot.data;
                
                if (user != null) {
                  // 🟢 بنراقب دوكيومنت المستخدم، لو مش موجود (لسه بيترفع) هيفضل في شاشة التحميل الفخمة
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                    builder: (context, docSnapshot) {
                      if (docSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(body: Center(child: CircularProgressIndicator()));
                      }
                      
                      if (docSnapshot.hasData && docSnapshot.data!.exists) {
                         // الداتا كلها اترفع وبقت تمام، يقدر يخش الرئيسية
                         return const HomePage();
                      }
                      
                      // 🟢 دي الشاشة اللي هتظهر أثناء ما الكود بيرفع الصور وبيعمل الحساب
                      return Scaffold(
                        backgroundColor: AppColors.primaryDark,
                        body: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    },
                  );
                }
                
                return const LoginPage(); 
              },
            ), 
          ),
        );
      },
    );
  }
}