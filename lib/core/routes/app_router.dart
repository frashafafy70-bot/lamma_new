import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

// 🟢 استيراد ملف الحارس
import 'auth_guard.dart';
import 'package:lamma_new/features/home/views/notifications_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/email_sign_up_page.dart';

import '../../features/home/home_page.dart';
import 'package:lamma_new/features/trips/presentation/pages/passenger_search_page.dart';
import 'package:lamma_new/features/trips/presentation/pages/passenger_tabs/passenger_trip_tracking_page.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_trip_tracking_page.dart';

// 🟢 استدعاء الشاشات الإضافية اللي هنحتاجها عشان الإشعارات تفتحها
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_active_trips_tab.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_radar_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page|Screen|Tab,Route')
class AppRouter extends RootStackRouter {
  AppRouter({super.navigatorKey});

  @override
  List<AutoRoute> get routes => [
        // مسارات المصادقة
        AutoRoute(page: LoginRoute.page),
        AutoRoute(page: SignUpRoute.page),
        AutoRoute(page: ForgotPasswordRoute.page),
        AutoRoute(page: OtpRoute.page),
        AutoRoute(page: EmailSignUpRoute.page),

        // الشاشات المحمية الأساسية
        AutoRoute(
          page: HomeRoute.page,
          initial: true,
          guards: [AuthGuard()],
        ),
        AutoRoute(
          page: PassengerSearchRoute.page,
          guards: [AuthGuard()],
        ),

        // شاشات التتبع
        AutoRoute(
          page: PassengerTripTrackingRoute.page,
          guards: [AuthGuard()],
        ),
        AutoRoute(
          page: DriverTripTrackingRoute.page,
          guards: [AuthGuard()],
        ),

        // 🟢 المسارات الجديدة المطلوبة للإشعارات
        AutoRoute(
          page: TripChatRoute.page,
          guards: [AuthGuard()],
        ),
        // تم حذف المسار الفاضي من هنا 🚀
        AutoRoute(
          page: DriverRadarRoute.page,
          guards: [AuthGuard()],
        ),
        AutoRoute(
          page: NotificationsRoute.page,
          guards: [AuthGuard()],
        ),
      ];
}