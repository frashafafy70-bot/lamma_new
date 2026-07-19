import 'package:get_it/get_it.dart';

// --- Driver Repositories ---
import '../../domain/repositories/driver_radar_repository.dart';
import '../../data/repositories/driver_radar_repository_impl.dart';

// --- Driver UseCases ---
import '../../domain/usecases/get_driver_active_trips_usecase.dart';
import '../../domain/usecases/get_driver_history_trips_usecase.dart';
import '../../domain/usecases/get_driver_radar_trips_usecase.dart';
import '../../domain/usecases/update_driver_location_usecase.dart';
import '../../domain/usecases/accept_passenger_booking_usecase.dart';
import '../../domain/usecases/reject_passenger_booking_usecase.dart';
import '../../domain/usecases/cancel_passenger_booking_usecase.dart';
import '../../domain/usecases/activate_driver_trip_usecase.dart';
import '../../domain/usecases/check_has_active_trip_usecase.dart';
import '../../domain/usecases/accept_radar_trip_usecase.dart';
import '../../domain/usecases/negotiate_radar_trip_usecase.dart';
import '../../domain/usecases/sync_driver_location_use_case.dart';
import '../../domain/usecases/cancel_trip_use_case.dart';
import '../../domain/usecases/delete_trip_usecase.dart';
import '../../domain/usecases/update_trip_status_usecase.dart';

// --- Driver Cubits ---
import '../cubit/driver/driver_active_trips_cubit.dart';
import '../cubit/driver/driver_radar_cubit.dart';
import '../cubit/driver/driver_history_cubit.dart';
import '../cubit/driver/driver_location_cubit.dart';

final sl = GetIt.instance;

void initDriverDI() {
  // 🟢 Repositories
  if (!sl.isRegistered<DriverRadarRepository>())
    sl.registerLazySingleton<DriverRadarRepository>(
        () => DriverRadarRepositoryImpl(firestore: sl()));

  // 🟢 Use Cases
  if (!sl.isRegistered<GetDriverActiveTripsUseCase>())
    sl.registerLazySingleton(() => GetDriverActiveTripsUseCase(sl()));
  if (!sl.isRegistered<GetDriverHistoryTripsUseCase>())
    sl.registerLazySingleton(() => GetDriverHistoryTripsUseCase(sl()));
  if (!sl.isRegistered<GetDriverRadarTripsUseCase>())
    sl.registerLazySingleton(() => GetDriverRadarTripsUseCase(sl()));
  if (!sl.isRegistered<AcceptRadarTripUseCase>())
    sl.registerLazySingleton(() => AcceptRadarTripUseCase(sl()));
  if (!sl.isRegistered<NegotiateRadarTripUseCase>())
    sl.registerLazySingleton(() => NegotiateRadarTripUseCase(sl()));
  if (!sl.isRegistered<SyncDriverLocationUseCase>())
    sl.registerLazySingleton(() => SyncDriverLocationUseCase(sl()));
  if (!sl.isRegistered<UpdateDriverLocationUseCase>())
    sl.registerLazySingleton(() => UpdateDriverLocationUseCase(sl()));
  if (!sl.isRegistered<AcceptPassengerBookingUseCase>())
    sl.registerLazySingleton(() => AcceptPassengerBookingUseCase(sl()));
  if (!sl.isRegistered<RejectPassengerBookingUseCase>())
    sl.registerLazySingleton(() => RejectPassengerBookingUseCase(sl()));
  if (!sl.isRegistered<CancelPassengerBookingUseCase>())
    sl.registerLazySingleton(() => CancelPassengerBookingUseCase(sl()));
  if (!sl.isRegistered<ActivateDriverTripUseCase>())
    sl.registerLazySingleton(() => ActivateDriverTripUseCase(sl()));
  if (!sl.isRegistered<CheckHasActiveTripUseCase>())
    sl.registerLazySingleton(() => CheckHasActiveTripUseCase(sl()));

  // 🟢 Cubits
  if (!sl.isRegistered<DriverLocationCubit>()) {
    sl.registerFactory(
        () => DriverLocationCubit(updateDriverLocationUseCase: sl()));
  }
  if (!sl.isRegistered<DriverActiveTripsCubit>()) {
    sl.registerFactory(() => DriverActiveTripsCubit(
          getDriverActiveTripsUseCase: sl(),
          acceptPassengerBookingUseCase: sl(),
          rejectPassengerBookingUseCase: sl(),
          cancelPassengerBookingUseCase: sl(),
          activateDriverTripUseCase: sl(),
          checkHasActiveTripUseCase: sl(),
          updateTripStatusUseCase: sl(),
          syncDriverLocationUseCase: sl(),
        ));
  }
  if (!sl.isRegistered<DriverRadarCubit>()) {
    sl.registerFactory(() => DriverRadarCubit(
          getDriverRadarTripsUseCase: sl(),
          acceptRadarTripUseCase: sl(),
          negotiateRadarTripUseCase: sl(),
        ));
  }
  if (!sl.isRegistered<DriverHistoryCubit>()) {
    sl.registerFactory(() => DriverHistoryCubit(
          getDriverHistoryTripsUseCase: sl(),
          cancelTripUseCase: sl(),
          deleteTripUseCase: sl(),
        ));
  }
}
