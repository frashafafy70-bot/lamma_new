import 'dart:async'; // 🟢 تم تصحيح حرف الـ I
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/trip_entity.dart';

// استدعاءات الـ UseCases المنفصلة
import '../../domain/usecases/add_trip_usecase.dart';
import '../../domain/usecases/delete_trip_usecase.dart';
import '../../domain/usecases/get_trips_usecase.dart';
import '../../domain/usecases/get_user_trips_usecase.dart';
import '../../domain/usecases/update_trip_status_usecase.dart';
import '../../domain/usecases/update_trip_usecase.dart';

import 'trip_state.dart';

class TripCubit extends Cubit<TripState> {
  final GetTripsUseCase getTripsUseCase;
  final GetUserTripsUseCase getUserTripsUseCase;
  final AddTripUseCase addTripUseCase;
  final UpdateTripUseCase updateTripUseCase;
  final UpdateTripStatusUseCase updateTripStatusUseCase;
  final DeleteTripUseCase deleteTripUseCase;

  StreamSubscription? _tripsSubscription;

  TripCubit({
    required this.getTripsUseCase,
    required this.getUserTripsUseCase,
    required this.addTripUseCase,
    required this.updateTripUseCase,
    required this.updateTripStatusUseCase,
    required this.deleteTripUseCase,
  }) : super(TripInitial());

  void loadAllTrips() {
    emit(TripsLoading());
    _tripsSubscription?.cancel();
    
    _tripsSubscription = getTripsUseCase.call().listen(
      (trips) {
        if (!isClosed) emit(TripsLoaded(trips)); // 🟢 تأمين إضافي للـ Stream
      },
      onError: (error) {
        if (!isClosed) emit(TripsError(error.toString()));
      },
    );
  }

  void loadUserTrips(String userId) {
    emit(TripsLoading());
    _tripsSubscription?.cancel();
    
    _tripsSubscription = getUserTripsUseCase.call(userId).listen(
      (trips) {
        if (!isClosed) emit(TripsLoaded(trips));
      },
      onError: (error) {
        if (!isClosed) emit(TripsError(error.toString()));
      },
    );
  }

  Future<void> addTrip(TripEntity trip) async {
    emit(TripLoading());
    
    final result = await addTripUseCase.call(trip);
    
    if (isClosed) return;
    
    result.fold(
      // 🟢 إرسال الـ Key أو رسالة الخطأ القادمة من الـ Domain
      (failure) => emit(TripOperationFailure(failure.message ?? 'error_unexpected')),
      // 🟢 إرسال Key النجاح ليتم ترجمته في الـ UI
      (_) => emit(TripOperationSuccess('success_trip_added')),
    );
  }

  Future<void> updateTripDetails(TripEntity trip) async {
    emit(TripLoading());
    
    final result = await updateTripUseCase.call(trip);
    
    if (isClosed) return;
    
    result.fold(
      (failure) => emit(TripOperationFailure(failure.message ?? 'error_unexpected')),
      (_) => emit(TripOperationSuccess('success_trip_updated')),
    );
  }

  Future<void> updateStatus(String tripId, String newStatus) async {
    final result = await updateTripStatusUseCase.call(tripId, newStatus);
    
    if (isClosed) return;
    
    result.fold(
      (failure) => emit(TripOperationFailure(failure.message ?? 'error_unexpected')),
      (_) => emit(TripStatusUpdated(tripId, newStatus)),
    );
  }

  Future<void> deleteTrip(String tripId) async {
    emit(TripLoading());
    
    final result = await deleteTripUseCase.call(tripId);
    
    if (isClosed) return;
    
    result.fold(
      (failure) => emit(TripOperationFailure(failure.message ?? 'error_unexpected')),
      (_) => emit(TripOperationSuccess('success_trip_deleted')),
    );
  }

  @override
  Future<void> close() {
    _tripsSubscription?.cancel();
    return super.close();
  }
}