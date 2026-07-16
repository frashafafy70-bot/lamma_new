import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

// ==========================================
// 🟢 Repositories
// ==========================================
import 'domain/repositories/trip_repository.dart';
import 'data/repositories/trip_repository_impl.dart';

import 'domain/repositories/booking_repository.dart';
import 'data/repositories/booking_repository_impl.dart';

import 'domain/repositories/driver_radar_repository.dart';
import 'data/repositories/driver_radar_repository_impl.dart';

import 'domain/repositories/chat_repository.dart';
import 'data/repositories/chat_repository_impl.dart';

import 'domain/repositories/map_repository.dart';
import 'data/repositories/map_repository_impl.dart';

// ==========================================
// 🔵 UseCases (Shared, Driver, Passenger)
// ==========================================
import 'domain/usecases/add_trip_usecase.dart';
import 'domain/usecases/delete_trip_usecase.dart';
import 'domain/usecases/get_trip_by_id_usecase.dart';
import 'domain/usecases/get_trips_usecase.dart';
import 'domain/usecases/get_user_trips_usecase.dart';
import 'domain/usecases/update_trip_status_usecase.dart';
import 'domain/usecases/update_trip_usecase.dart';
import 'domain/usecases/cancel_trip_use_case.dart';
import 'domain/usecases/update_booking_seats_use_case.dart';
import 'domain/usecases/submit_negotiation_use_case.dart';
import 'domain/usecases/start_trip_use_case.dart';
import 'domain/usecases/complete_trip_use_case.dart';
import 'domain/usecases/accept_trip_offer_use_case.dart';
import 'domain/usecases/reject_trip_offer_use_case.dart';
import 'domain/usecases/submit_trip_rating_use_case.dart';
import 'domain/usecases/publish_travel_trip_use_case.dart';

// Driver Specific UseCases
import 'domain/usecases/get_driver_active_trips_usecase.dart';
import 'domain/usecases/get_driver_history_trips_usecase.dart'; 
import 'domain/usecases/get_driver_radar_trips_usecase.dart';
import 'domain/usecases/sync_driver_location_use_case.dart';
import 'domain/usecases/update_driver_location_usecase.dart'; 
import 'domain/usecases/accept_passenger_booking_usecase.dart';
import 'domain/usecases/reject_passenger_booking_usecase.dart';
import 'domain/usecases/cancel_passenger_booking_usecase.dart';
import 'domain/usecases/activate_driver_trip_usecase.dart';
import 'domain/usecases/check_has_active_trip_usecase.dart';
import 'domain/usecases/accept_radar_trip_usecase.dart'; 
import 'domain/usecases/negotiate_radar_trip_usecase.dart'; 

// Passenger Specific UseCases
import 'domain/usecases/get_passenger_active_trips_usecase.dart';
import 'domain/usecases/get_available_travels_usecase.dart';
import 'domain/usecases/send_notification_usecase.dart'; 
import 'domain/usecases/manage_passenger_request_usecase.dart'; 

// ==========================================
// 🟠 Cubits
// ==========================================
import 'presentation/cubit/trip_cubit.dart';
import 'cubit/shared/trip_actions_cubit.dart';
import 'cubit/shared/trip_chat_cubit.dart'; 

import 'cubit/driver/driver_active_trips_cubit.dart';
import 'cubit/driver/driver_radar_cubit.dart';
import 'cubit/driver/driver_history_cubit.dart';
import 'cubit/driver/driver_location_cubit.dart'; 

import 'cubit/passenger/available_travels_cubit.dart'; // 👈 الإضافة اللي كانت ناقصة
import 'cubit/passenger/passenger_my_requests_cubit.dart';
import 'cubit/passenger/trip_booking_cubit.dart';
import 'cubit/passenger/trip_search_cubit.dart'; 
import 'cubit/passenger/passenger_request_cubit.dart';

final sl = GetIt.instance;

void initTripModule() {
  // ==========================================
  // 1. Cubits
  // ==========================================
  
  if (!sl.isRegistered<TripCubit>()) {
    sl.registerFactory(() => TripCubit(
          getTripsUseCase: sl(),
          getUserTripsUseCase: sl(),
          addTripUseCase: sl(),
          updateTripUseCase: sl(),
          updateTripStatusUseCase: sl(),
          deleteTripUseCase: sl(),
        ));
  }

  if (!sl.isRegistered<DriverLocationCubit>()) {
    sl.registerFactory(() => DriverLocationCubit(
          updateDriverLocationUseCase: sl(),
        ));
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

  // 🟢 تعديل تسجيل AvailableTravelsCubit ليأخذ معامل واحد فقط
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

  if (!sl.isRegistered<TripActionsCubit>()) {
    sl.registerFactory(() => TripActionsCubit(
          cancelTripUseCase: sl(),
          updateBookingSeatsUseCase: sl(),
          submitNegotiationUseCase: sl(),
          startTripUseCase: sl(),
          completeTripUseCase: sl(),
          acceptTripOfferUseCase: sl(),
          rejectTripOfferUseCase: sl(),
          submitTripRatingUseCase: sl(),
          publishTravelTripUseCase: sl(),
          syncDriverLocationUseCase: sl(),
        ));
  }

  if (!sl.isRegistered<TripChatCubit>()) {
    sl.registerFactory(() => TripChatCubit(chatRepository: sl()));
  }

  if (!sl.isRegistered<PassengerRequestCubit>()) {
    sl.registerFactory(() => PassengerRequestCubit(
          mapRepository: sl(),
          tripRepository: sl(),
        ));
  }

  // ==========================================
  // 2. Use Cases 
  // ==========================================
  if (!sl.isRegistered<GetTripsUseCase>()) sl.registerLazySingleton(() => GetTripsUseCase(sl()));
  if (!sl.isRegistered<GetUserTripsUseCase>()) sl.registerLazySingleton(() => GetUserTripsUseCase(sl()));
  if (!sl.isRegistered<GetTripByIdUseCase>()) sl.registerLazySingleton(() => GetTripByIdUseCase(sl()));
  if (!sl.isRegistered<AddTripUseCase>()) sl.registerLazySingleton(() => AddTripUseCase(sl()));
  if (!sl.isRegistered<UpdateTripUseCase>()) sl.registerLazySingleton(() => UpdateTripUseCase(sl()));
  if (!sl.isRegistered<UpdateTripStatusUseCase>()) sl.registerLazySingleton(() => UpdateTripStatusUseCase(sl()));
  if (!sl.isRegistered<DeleteTripUseCase>()) sl.registerLazySingleton(() => DeleteTripUseCase(sl()));

  if (!sl.isRegistered<GetDriverActiveTripsUseCase>()) sl.registerLazySingleton(() => GetDriverActiveTripsUseCase(sl()));
  if (!sl.isRegistered<GetDriverHistoryTripsUseCase>()) sl.registerLazySingleton(() => GetDriverHistoryTripsUseCase(sl()));

  if (!sl.isRegistered<GetPassengerActiveTripsUseCase>()) sl.registerLazySingleton(() => GetPassengerActiveTripsUseCase(sl()));
  if (!sl.isRegistered<CancelTripUseCase>()) sl.registerLazySingleton(() => CancelTripUseCase(sl()));
  if (!sl.isRegistered<UpdateBookingSeatsUseCase>()) sl.registerLazySingleton(() => UpdateBookingSeatsUseCase(sl()));
  if (!sl.isRegistered<SubmitNegotiationUseCase>()) sl.registerLazySingleton(() => SubmitNegotiationUseCase(sl()));
  if (!sl.isRegistered<GetAvailableTravelsUseCase>()) sl.registerLazySingleton(() => GetAvailableTravelsUseCase(sl()));
  
  if (!sl.isRegistered<GetDriverRadarTripsUseCase>()) sl.registerLazySingleton(() => GetDriverRadarTripsUseCase(sl()));
  if (!sl.isRegistered<AcceptRadarTripUseCase>()) sl.registerLazySingleton(() => AcceptRadarTripUseCase(sl()));
  if (!sl.isRegistered<NegotiateRadarTripUseCase>()) sl.registerLazySingleton(() => NegotiateRadarTripUseCase(sl()));
  
  if (!sl.isRegistered<StartTripUseCase>()) sl.registerLazySingleton(() => StartTripUseCase(sl()));
  if (!sl.isRegistered<CompleteTripUseCase>()) sl.registerLazySingleton(() => CompleteTripUseCase(sl()));
  if (!sl.isRegistered<AcceptTripOfferUseCase>()) sl.registerLazySingleton(() => AcceptTripOfferUseCase(sl()));
  if (!sl.isRegistered<RejectTripOfferUseCase>()) sl.registerLazySingleton(() => RejectTripOfferUseCase(sl()));

  if (!sl.isRegistered<SubmitTripRatingUseCase>()) sl.registerLazySingleton(() => SubmitTripRatingUseCase(sl()));
  if (!sl.isRegistered<PublishTravelTripUseCase>()) sl.registerLazySingleton(() => PublishTravelTripUseCase(sl()));
  
  if (!sl.isRegistered<SyncDriverLocationUseCase>()) sl.registerLazySingleton(() => SyncDriverLocationUseCase(sl()));
  if (!sl.isRegistered<UpdateDriverLocationUseCase>()) sl.registerLazySingleton(() => UpdateDriverLocationUseCase(sl()));

  if (!sl.isRegistered<AcceptPassengerBookingUseCase>()) sl.registerLazySingleton(() => AcceptPassengerBookingUseCase(sl()));
  if (!sl.isRegistered<RejectPassengerBookingUseCase>()) sl.registerLazySingleton(() => RejectPassengerBookingUseCase(sl()));
  if (!sl.isRegistered<CancelPassengerBookingUseCase>()) sl.registerLazySingleton(() => CancelPassengerBookingUseCase(sl()));
  if (!sl.isRegistered<ActivateDriverTripUseCase>()) sl.registerLazySingleton(() => ActivateDriverTripUseCase(sl()));
  if (!sl.isRegistered<CheckHasActiveTripUseCase>()) sl.registerLazySingleton(() => CheckHasActiveTripUseCase(sl()));
  
  if (!sl.isRegistered<SendNotificationUseCase>()) sl.registerLazySingleton(() => SendNotificationUseCase(sl()));
  if (!sl.isRegistered<ManagePassengerRequestUseCase>()) sl.registerLazySingleton(() => ManagePassengerRequestUseCase(sl()));

  // ==========================================
  // 3. Repositories & Services
  // ==========================================
  
  if (!sl.isRegistered<BookingRepository>()) {
    sl.registerLazySingleton<BookingRepository>(() => BookingRepositoryImpl(sl()));
  }

  if (!sl.isRegistered<TripRepository>()) {
    sl.registerLazySingleton<TripRepository>(() => TripRepositoryImpl(firestore: sl()));
  }

  if (!sl.isRegistered<DriverRadarRepository>()) {
    sl.registerLazySingleton<DriverRadarRepository>(() => DriverRadarRepositoryImpl(firestore: sl()));
  }

  if (!sl.isRegistered<ChatRepository>()) {
    sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl());
  }

  if (!sl.isRegistered<MapRepository>()) {
    sl.registerLazySingleton<MapRepository>(() => MapRepositoryImpl());
  }

  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton(() => FirebaseFirestore.instance);
  }
}