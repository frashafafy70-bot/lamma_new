import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// 🟢 استدعاءات الشبكة
import 'package:lamma_new/core/network/network_cubit.dart';

// 🟢 استدعاءات الـ Auth
import 'package:lamma_new/features/auth/cubit/auth_cubit.dart';
import 'package:lamma_new/features/auth/data/services/auth_service.dart';
import 'package:lamma_new/features/auth/domain/repositories/auth_repository.dart'; // 👈 الـ Interface
import 'package:lamma_new/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lamma_new/features/auth/domain/use_cases/login_use_case.dart';
import 'package:lamma_new/features/auth/domain/use_cases/sign_up_use_case.dart';
import 'package:lamma_new/features/auth/domain/use_cases/sign_out_use_case.dart';
import 'package:lamma_new/features/auth/domain/use_cases/auth_advanced_use_cases.dart';

// 🟢 استدعاءات الـ Profile
import 'package:lamma_new/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:lamma_new/features/profile/domain/repositories/profile_repository.dart'; // 👈 الـ Interface
import 'package:lamma_new/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:lamma_new/features/profile/domain/use_cases/get_user_profile_use_case.dart';
import 'package:lamma_new/features/profile/domain/use_cases/update_user_profile_use_case.dart';

// 🟢 استدعاءات الـ Home & Notifications
import 'package:lamma_new/features/home/cubit/home_cubit.dart';
import 'package:lamma_new/features/home/domain/repositories/home_repository.dart'; // 👈 الـ Interface
import 'package:lamma_new/features/home/data/repositories/home_repository_impl.dart';
import 'package:lamma_new/features/home/domain/use_cases/get_service_categories_use_case.dart';
import 'package:lamma_new/features/home/domain/use_cases/get_active_orders_summary_use_case.dart';
import 'package:lamma_new/features/notifications/presentation/cubit/notification_cubit.dart';

// 🟢 استدعاءات الـ Trips
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_chat_cubit.dart';
import 'package:lamma_new/features/trips/domain/repositories/chat_repository.dart'; // 👈 الـ Interface
import 'package:lamma_new/features/trips/domain/repositories/trip_repository.dart'; // 👈 الـ Interface
import 'package:lamma_new/features/trips/data/repositories/chat_repository_impl.dart';
import 'package:lamma_new/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:lamma_new/features/trips/domain/usecases/get_driver_active_trips_usecase.dart';

final sl = GetIt.instance; // sl = Service Locator

Future<void> initDI() async {
  // ==========================================
  // 1. External (Firebase)
  // ==========================================
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);

  // ==========================================
  // 2. Core (Network)
  // ==========================================
  sl.registerFactory(() => NetworkCubit());
  sl.registerFactory(() => NotificationCubit());

  // ==========================================
  // 3. Features
  // ==========================================

  // --- Auth Feature ---
  sl.registerLazySingleton(() => AuthService());
  
  // 🟢 الحل: بنعرف الـ GetIt إن الـ Interface ده هيتنفذ بالكلاس ده
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => LoginWithGoogleUseCase(sl()));
  sl.registerLazySingleton(() => SendSignUpOtpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpAndSignUpUseCase(sl()));

  sl.registerFactory(() => AuthCubit(
    loginUseCase: sl(),
    signUpUseCase: sl(),
    signOutUseCase: sl(),
    loginWithGoogleUseCase: sl(),
    sendSignUpOtpUseCase: sl(),
    verifyOtpAndSignUpUseCase: sl(),
    authRepository: sl(),
  ));

  // --- Profile Feature ---
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(
    auth: sl(), firestore: sl(), storage: sl()
  ));
  
  sl.registerLazySingleton(() => GetUserProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserProfileUseCase(sl()));

  sl.registerFactory(() => ProfileCubit(
    getUserProfileUseCase: sl(),
    updateUserProfileUseCase: sl(),
    repository: sl(),
  ));

  // --- Home Feature ---
  sl.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(
    auth: sl(), firestore: sl(),
  ));

  sl.registerLazySingleton(() => GetServiceCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetActiveOrdersSummaryUseCase(sl()));

  sl.registerFactory(() => HomeCubit(
    getServiceCategoriesUseCase: sl(),
    getActiveOrdersSummaryUseCase: sl(),
  ));

  // --- Trips Feature ---
  sl.registerLazySingleton<TripRepository>(() => TripRepositoryImpl(
    auth: sl(), firestore: sl(),
  ));
  
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl());

  sl.registerLazySingleton(() => GetDriverActiveTripsUseCase(sl()));

  sl.registerFactory(() => DriverActiveTripsCubit(sl()));
  sl.registerFactory(() => TripChatCubit(chatRepository: sl()));
  sl.registerFactory(() => TripActionsCubit());
}