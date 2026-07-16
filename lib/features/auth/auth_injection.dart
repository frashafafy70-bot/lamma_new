import 'package:get_it/get_it.dart';

// 🟢 استدعاءات الـ Auth
import 'package:lamma_new/features/auth/cubit/auth_cubit.dart';
import 'package:lamma_new/features/auth/data/services/auth_service.dart';
import 'package:lamma_new/features/auth/domain/repositories/auth_repository.dart'; 
import 'package:lamma_new/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lamma_new/features/auth/domain/use_cases/login_use_case.dart';
import 'package:lamma_new/features/auth/domain/use_cases/sign_up_use_case.dart';
import 'package:lamma_new/features/auth/domain/use_cases/sign_out_use_case.dart';
import 'package:lamma_new/features/auth/domain/use_cases/auth_advanced_use_cases.dart';

final sl = GetIt.instance;

void initAuthModule() {
  // 1. Services
  sl.registerLazySingleton(() => AuthService());
  
  // 2. Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  
  // 3. Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => LoginWithGoogleUseCase(sl()));
  sl.registerLazySingleton(() => SendSignUpOtpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpAndSignUpUseCase(sl()));

  // 4. Cubits
  sl.registerFactory(() => AuthCubit(
    loginUseCase: sl(),
    signUpUseCase: sl(),
    signOutUseCase: sl(),
    loginWithGoogleUseCase: sl(),
    sendSignUpOtpUseCase: sl(),
    verifyOtpAndSignUpUseCase: sl(),
    authRepository: sl(),
  ));
}