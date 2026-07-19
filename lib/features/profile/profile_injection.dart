import 'package:get_it/get_it.dart';

// 🟢 استدعاءات الـ Repositories
import 'package:lamma_new/features/profile/domain/repositories/profile_repository.dart';
import 'package:lamma_new/features/profile/data/repositories/profile_repository_impl.dart';

// 🟢 استدعاءات الـ UseCases بالمسارات الكاملة
import 'package:lamma_new/features/profile/domain/use_cases/get_user_profile_use_case.dart';
import 'package:lamma_new/features/profile/domain/use_cases/update_user_profile_use_case.dart';
import 'package:lamma_new/features/profile/domain/use_cases/submit_role_registration_use_case.dart';
import 'package:lamma_new/features/profile/domain/use_cases/switch_user_role_use_case.dart';
import 'package:lamma_new/features/profile/domain/use_cases/upload_document_use_case.dart';

// 🟢 استدعاء الـ Cubit
import 'package:lamma_new/features/profile/presentation/cubit/profile_cubit.dart';

final sl = GetIt.instance;

void initProfile() {
  // ==========================================
  // 1. تسجيل الـ Repository
  // ==========================================
  if (!sl.isRegistered<ProfileRepository>()) {
    sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(
        auth: sl(),
        firestore: sl(),
        storage: sl(),
      ),
    );
  }

  // ==========================================
  // 2. تسجيل جميع الـ Use Cases
  // ==========================================
  sl.registerLazySingleton(() => GetUserProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserProfileUseCase(sl()));
  sl.registerLazySingleton(() => SubmitRoleRegistrationUseCase(sl()));
  sl.registerLazySingleton(() => SwitchUserRoleUseCase(sl()));
  sl.registerLazySingleton(() => UploadDocumentUseCase(sl()));

  // ==========================================
  // 3. تسجيل الـ Cubit كـ Factory
  // ==========================================
  sl.registerFactory(() => ProfileCubit(
        getUserProfileUseCase: sl(),
        updateUserProfileUseCase: sl(),
        switchUserRoleUseCase: sl(),
        uploadDocumentUseCase: sl(),
        submitRoleRegistrationUseCase: sl(),
        repository: sl(),
      ));
}
