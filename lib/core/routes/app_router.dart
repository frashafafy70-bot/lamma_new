import 'package:auto_route/auto_route.dart';

import '../../features/auth/presentation/pages/auth_wrapper.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/home/home_page.dart';
import '../../features/trips/presentation/pages/passenger_search_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page|Screen|Tab,Route')
class AppRouter extends RootStackRouter {
  // 🟢 استقبال الـ navigatorKey للإصدار الجديد غصب عنه هنا
  AppRouter({super.navigatorKey}); 

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: AuthWrapperRoute.page, initial: true),
        AutoRoute(page: LoginRoute.page),
        AutoRoute(page: SignUpRoute.page),
        AutoRoute(page: ForgotPasswordRoute.page),
        AutoRoute(page: HomeRoute.page),
        AutoRoute(page: PassengerSearchRoute.page),
      ];
}