import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/trip_entity.dart';

// 🟢 استدعاءات الـ UseCases المنفصلة
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
        emit(TripsLoaded(trips));
      },
      onError: (error) {
        emit(TripsError(error.toString()));
      },
    );
  }

  void loadUserTrips(String userId) {
    emit(TripsLoading());
    _tripsSubscription?.cancel();
    
    _tripsSubscription = getUserTripsUseCase.call(userId).listen(
      (trips) {
        emit(TripsLoaded(trips));
      },
      onError: (error) {
        emit(TripsError(error.toString()));
      },
    );
  }

  Future<void> addTrip(TripEntity trip) async {
    emit(TripLoading());
    
    // 🟢 استخدام fold بدلاً من try-catch
    final result = await addTripUseCase.call(trip);
    
    if (isClosed) return;
    
    result.fold(
      (failure) => emit(TripOperationFailure(failure.message ?? 'حدث خطأ غير متوقع')),
      (_) => emit(TripOperationSuccess("تم إضافة الرحلة بنجاح")),
    );
  }

  Future<void> updateTripDetails(TripEntity trip) async {
    emit(TripLoading());
    
    final result = await updateTripUseCase.call(trip);
    
    if (isClosed) return;
    
    result.fold(
      (failure) => emit(TripOperationFailure(failure.message ?? 'حدث خطأ غير متوقع')),
      (_) => emit(TripOperationSuccess("تم تحديث بيانات الرحلة")),
    );
  }

  Future<void> updateStatus(String tripId, String newStatus) async {
    final result = await updateTripStatusUseCase.call(tripId, newStatus);
    
    if (isClosed) return;
    
    result.fold(
      (failure) => emit(TripOperationFailure(failure.message ?? 'حدث خطأ غير متوقع')),
      (_) => emit(TripStatusUpdated(tripId, newStatus)),
    );
  }

  Future<void> deleteTrip(String tripId) async {
    emit(TripLoading());
    
    final result = await deleteTripUseCase.call(tripId);
    
    if (isClosed) return;
    
    result.fold(
      (failure) => emit(TripOperationFailure(failure.message ?? 'حدث خطأ غير متوقع')),
      (_) => emit(TripOperationSuccess("تم حذف الرحلة")),
    );
  }

  @override
  Future<void> close() {
    _tripsSubscription?.cancel();
    return super.close();
  }
}