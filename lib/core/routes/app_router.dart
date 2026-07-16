import 'package:auto_route/auto_route.dart';

// 🟢 استيراد ملف الحارس الذي أنشأناه للتو
import 'auth_guard.dart'; 

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/home/home_page.dart';
import '../../features/trips/presentation/pages/passenger_search_page.dart';

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
        
        // الشاشات المحمية
        AutoRoute(
          page: HomeRoute.page, 
          initial: true, 
          guards: [AuthGuard()], 
        ),
        AutoRoute(
          page: PassengerSearchRoute.page, 
          guards: [AuthGuard()],
        ),
      ];
}