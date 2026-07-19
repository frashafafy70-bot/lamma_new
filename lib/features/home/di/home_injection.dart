import 'package:get_it/get_it.dart';

// 🟢 استدعاءات الـ Repositories
import 'package:lamma_new/features/home/domain/repositories/home_repository.dart';
import 'package:lamma_new/features/home/data/repositories/home_repository_impl.dart';

// 🟢 استدعاء الـ UseCases بالمسارات الكاملة
import 'package:lamma_new/features/home/domain/use_cases/get_service_categories_use_case.dart';
import 'package:lamma_new/features/home/domain/use_cases/get_active_orders_summary_use_case.dart';
import 'package:lamma_new/features/home/domain/use_cases/home_badges_use_cases.dart';

// 🟢 استدعاء الـ Cubit بالمسار الكامل
import 'package:lamma_new/features/home/cubit/home_cubit.dart';

final sl = GetIt.instance;

void initHome() {
  // ==========================================
  // 1. تسجيل الـ Repository (تمت إضافة الـ auth والـ firestore)
  // ==========================================
  if (!sl.isRegistered<HomeRepository>()) {
    sl.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(
        firestore: sl(), // يجلب FirebaseFirestore من الـ Injection الرئيسي
        auth: sl(), // يجلب FirebaseAuth من الـ Injection الرئيسي
      ),
    );
  }

  // ==========================================
  // 2. تسجيل الـ Use Cases
  // ==========================================
  sl.registerLazySingleton(() => GetServiceCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetActiveOrdersSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetRadarBadgeUseCase(sl()));
  sl.registerLazySingleton(() => GetActiveTripsBadgeUseCase(sl()));
  sl.registerLazySingleton(() => GetClientRequestsBadgeUseCase(sl()));

  // ==========================================
  // 3. تسجيل الـ HomeCubit كـ Factory
  // ==========================================
  sl.registerFactory(() => HomeCubit(
        getServiceCategoriesUseCase: sl(),
        getActiveOrdersSummaryUseCase: sl(),
        getRadarBadgeUseCase: sl(),
        getActiveTripsBadgeUseCase: sl(),
        getClientRequestsBadgeUseCase: sl(),
      ));
}
