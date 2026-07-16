import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Repositories ---
import '../../domain/repositories/trip_repository.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/repositories/map_repository.dart';
import '../../data/repositories/map_repository_impl.dart';

// --- Shared UseCases ---
import '../../domain/usecases/add_trip_usecase.dart';
import '../../domain/usecases/delete_trip_usecase.dart';
import '../../domain/usecases/get_trip_by_id_usecase.dart';
import '../../domain/usecases/get_trips_usecase.dart';
import '../../domain/usecases/get_user_trips_usecase.dart';
import '../../domain/usecases/update_trip_status_usecase.dart';
import '../../domain/usecases/update_trip_usecase.dart';
import '../../domain/usecases/cancel_trip_use_case.dart';
import '../../domain/usecases/update_booking_seats_use_case.dart';
import '../../domain/usecases/submit_negotiation_use_case.dart';
import '../../domain/usecases/start_trip_use_case.dart';
import '../../domain/usecases/complete_trip_use_case.dart';
import '../../domain/usecases/accept_trip_offer_use_case.dart';
import '../../domain/usecases/reject_trip_offer_use_case.dart';
import '../../domain/usecases/submit_trip_rating_use_case.dart';
import '../../domain/usecases/publish_travel_trip_use_case.dart';
import '../../domain/usecases/sync_driver_location_use_case.dart';

// --- Shared Cubits ---
import '../cubit/shared/trip_actions_cubit.dart';
import '../cubit/shared/trip_chat_cubit.dart';
import '../../presentation/cubit/trip_cubit.dart';

final sl = GetIt.instance;

void initSharedDI() {
  // 🟢 Core
  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton(() => FirebaseFirestore.instance);
  }

  // 🟢 Repositories
  if (!sl.isRegistered<TripRepository>()) sl.registerLazySingleton<TripRepository>(() => TripRepositoryImpl(firestore: sl()));
  if (!sl.isRegistered<BookingRepository>()) sl.registerLazySingleton<BookingRepository>(() => BookingRepositoryImpl(sl()));
  if (!sl.isRegistered<ChatRepository>()) sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl());
  if (!sl.isRegistered<MapRepository>()) sl.registerLazySingleton<MapRepository>(() => MapRepositoryImpl());

  // 🟢 Use Cases
  if (!sl.isRegistered<GetTripsUseCase>()) sl.registerLazySingleton(() => GetTripsUseCase(sl()));
  if (!sl.isRegistered<GetUserTripsUseCase>()) sl.registerLazySingleton(() => GetUserTripsUseCase(sl()));
  if (!sl.isRegistered<GetTripByIdUseCase>()) sl.registerLazySingleton(() => GetTripByIdUseCase(sl()));
  if (!sl.isRegistered<AddTripUseCase>()) sl.registerLazySingleton(() => AddTripUseCase(sl()));
  if (!sl.isRegistered<UpdateTripUseCase>()) sl.registerLazySingleton(() => UpdateTripUseCase(sl()));
  if (!sl.isRegistered<UpdateTripStatusUseCase>()) sl.registerLazySingleton(() => UpdateTripStatusUseCase(sl()));
  if (!sl.isRegistered<DeleteTripUseCase>()) sl.registerLazySingleton(() => DeleteTripUseCase(sl()));
  if (!sl.isRegistered<CancelTripUseCase>()) sl.registerLazySingleton(() => CancelTripUseCase(sl()));
  if (!sl.isRegistered<UpdateBookingSeatsUseCase>()) sl.registerLazySingleton(() => UpdateBookingSeatsUseCase(sl()));
  if (!sl.isRegistered<SubmitNegotiationUseCase>()) sl.registerLazySingleton(() => SubmitNegotiationUseCase(sl()));
  if (!sl.isRegistered<StartTripUseCase>()) sl.registerLazySingleton(() => StartTripUseCase(sl()));
  if (!sl.isRegistered<CompleteTripUseCase>()) sl.registerLazySingleton(() => CompleteTripUseCase(sl()));
  if (!sl.isRegistered<AcceptTripOfferUseCase>()) sl.registerLazySingleton(() => AcceptTripOfferUseCase(sl()));
  if (!sl.isRegistered<RejectTripOfferUseCase>()) sl.registerLazySingleton(() => RejectTripOfferUseCase(sl()));
  if (!sl.isRegistered<SubmitTripRatingUseCase>()) sl.registerLazySingleton(() => SubmitTripRatingUseCase(sl()));
  if (!sl.isRegistered<PublishTravelTripUseCase>()) sl.registerLazySingleton(() => PublishTravelTripUseCase(sl()));

  // 🟢 Cubits
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
}