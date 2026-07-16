import 'package:get_it/get_it.dart';

// --- Passenger UseCases ---
import '../../domain/usecases/get_passenger_active_trips_usecase.dart';
import '../../domain/usecases/get_available_travels_usecase.dart';
import '../../domain/usecases/send_notification_usecase.dart'; 
import '../../domain/usecases/manage_passenger_request_usecase.dart'; 

// --- Passenger Cubits ---
import '../cubit/passenger/available_travels_cubit.dart';
import '../cubit/passenger/passenger_my_requests_cubit.dart';
import '../cubit/passenger/trip_booking_cubit.dart';
import '../cubit/passenger/trip_search_cubit.dart'; 
import '../cubit/passenger/passenger_request_cubit.dart';

final sl = GetIt.instance;

void initPassengerDI() {
  // 🟢 Use Cases
  if (!sl.isRegistered<GetPassengerActiveTripsUseCase>()) sl.registerLazySingleton(() => GetPassengerActiveTripsUseCase(sl()));
  if (!sl.isRegistered<GetAvailableTravelsUseCase>()) sl.registerLazySingleton(() => GetAvailableTravelsUseCase(sl()));
  if (!sl.isRegistered<SendNotificationUseCase>()) sl.registerLazySingleton(() => SendNotificationUseCase(sl()));
  if (!sl.isRegistered<ManagePassengerRequestUseCase>()) sl.registerLazySingleton(() => ManagePassengerRequestUseCase(sl()));

  // 🟢 Cubits
  if (!sl.isRegistered<AvailableTravelsCubit>()) {
    sl.registerFactory(() => AvailableTravelsCubit(sl()));
  }
  if (!sl.isRegistered<PassengerMyRequestsCubit>()) {
    sl.registerFactory(() => PassengerMyRequestsCubit(
          getPassengerActiveTripsUseCase: sl(),
          sendNotificationUseCase: sl(),
          managePassengerRequestUseCase: sl(),
        ));
  }
  if (!sl.isRegistered<TripSearchCubit>()) {
    sl.registerFactory(() => TripSearchCubit(sl()));
  }
  if (!sl.isRegistered<TripBookingCubit>()) {
    sl.registerFactory(() => TripBookingCubit(sl()));
  }
  if (!sl.isRegistered<PassengerRequestCubit>()) {
    sl.registerFactory(() => PassengerRequestCubit(
          mapRepository: sl(),
          tripRepository: sl(),
        ));
  }
}