import 'package:get_it/get_it.dart';

// 🟢 استدعاءات مديول الإشعارات
import 'package:lamma_new/features/notifications/domain/repositories/notification_repository.dart';
import 'package:lamma_new/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:lamma_new/features/notifications/domain/use_cases/get_notifications_use_case.dart';
import 'package:lamma_new/features/notifications/presentation/cubit/notification_cubit.dart'; // تأكد من مسار الكيوبت بتاعك

final sl = GetIt.instance;

void initNotificationModule() {
  // 1. Repositories
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(firestore: sl())
  );

  // 2. Use Cases
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));

  // 3. Cubit
  sl.registerFactory(() => NotificationCubit(
    getNotificationsUseCase: sl(),
  ));
}