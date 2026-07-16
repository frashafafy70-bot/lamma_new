import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/usecases/get_driver_active_trips_usecase.dart'; 
import '../../domain/usecases/accept_passenger_booking_usecase.dart';
import '../../domain/usecases/reject_passenger_booking_usecase.dart';
import '../../domain/usecases/cancel_passenger_booking_usecase.dart';
import '../../domain/usecases/activate_driver_trip_usecase.dart';
import '../../domain/usecases/check_has_active_trip_usecase.dart';
import '../../domain/usecases/update_trip_status_usecase.dart';
import '../../domain/usecases/sync_driver_location_use_case.dart';

import '../../data/models/trip_model.dart';
import 'driver_active_trips_state.dart';

class DriverActiveTripsCubit extends Cubit<DriverActiveTripsState> {
  final GetDriverActiveTripsUseCase getDriverActiveTripsUseCase;
  final AcceptPassengerBookingUseCase acceptPassengerBookingUseCase;
  final RejectPassengerBookingUseCase rejectPassengerBookingUseCase;
  final CancelPassengerBookingUseCase cancelPassengerBookingUseCase;
  final ActivateDriverTripUseCase activateDriverTripUseCase;
  final CheckHasActiveTripUseCase checkHasActiveTripUseCase;
  final UpdateTripStatusUseCase updateTripStatusUseCase;
  final SyncDriverLocationUseCase syncDriverLocationUseCase;
  
  String _currentUserId = '';
  final List<TripModel> _trips = [];
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  static const int _limit = 15; 

  DriverActiveTripsCubit({
    required this.getDriverActiveTripsUseCase,
    required this.acceptPassengerBookingUseCase,
    required this.rejectPassengerBookingUseCase,
    required this.cancelPassengerBookingUseCase,
    required this.activateDriverTripUseCase,
    required this.checkHasActiveTripUseCase,
    required this.updateTripStatusUseCase,
    required this.syncDriverLocationUseCase,
  }) : super(DriverActiveTripsInitial());

  void startListeningToActiveTrips(String uid) {
    if (uid.isEmpty) return; 
    _currentUserId = uid; 
    fetchInitialActiveTrips();
  }

  Future<void> fetchInitialActiveTrips() async {
    if (_currentUserId.isEmpty) {
      emit(DriverActiveTripsError('لم يتم العثور على حساب السائق، يرجى تسجيل الدخول مجدداً.'));
      return;
    }
    
    emit(DriverActiveTripsLoading());
    _resetPagination();

    try {
      final result = await getDriverActiveTripsUseCase(uid: _currentUserId, limit: _limit);
      if (isClosed) return;
      
      result.fold(
        (failure) => emit(DriverActiveTripsError(failure.message ?? 'حدث خطأ أثناء جلب الرحلات النشطة.')),
        (trips) => _handleNewTrips(trips),
      );
    } catch (e) {
      if (!isClosed) emit(DriverActiveTripsError('حدث خطأ غير متوقع: $e'));
    }
  }

  Future<void> fetchMoreActiveTrips() async {
    if (_hasReachedMax || _isFetchingMore || _currentUserId.isEmpty) return;
    
    _isFetchingMore = true;
    if (state is DriverActiveTripsLoaded) {
      emit((state as DriverActiveTripsLoaded).copyWith(isFetchingMore: true));
    }

    try {
      final lastTrip = _trips.isNotEmpty ? _trips.last : null;
      final result = await getDriverActiveTripsUseCase(
        uid: _currentUserId, 
        limit: _limit, 
        lastTrip: lastTrip,
      );
      
      if (isClosed) return;
      
      result.fold(
        (failure) {
          _isFetchingMore = false;
          emit(DriverActiveTripsPaginationError(failure.message ?? 'فشل جلب المزيد من الرحلات'));
          emit(_buildLoadedState()); 
        },
        (newTrips) {
          _isFetchingMore = false;
          _handleNewTrips(newTrips, isPagination: true);
        },
      );
    } catch (e) {
      _isFetchingMore = false;
      if (!isClosed) {
         emit(DriverActiveTripsPaginationError('حدث خطأ في الاتصال'));
         emit(_buildLoadedState());
      }
    }
  }

  Future<void> _performAction({
    required Future<dynamic> Function() action,
    required String successMessage,
    required bool refreshAfterSuccess,
  }) async {
    emit(DriverActiveTripsActionLoading());
    
    final result = await action();
    
    if (isClosed) return;
    
    result.fold(
      (failure) {
        // حماية إضافية لو الـ failure ملوش message
        final errorMessage = (failure is dynamic && failure.message != null) 
            ? failure.message 
            : 'حدث خطأ غير متوقع';
        emit(DriverActiveTripsActionError(errorMessage));
        emit(_buildLoadedState()); 
      },
      (_) {
        emit(DriverActiveTripsActionSuccess(successMessage));
        refreshAfterSuccess ? _backgroundRefresh() : emit(_buildLoadedState());
      }
    );
  }

  Future<void> acceptBooking(String bookingId, String tripId, int seatsToDeduct) async =>
    _performAction(
      action: () => acceptPassengerBookingUseCase(bookingId: bookingId, tripId: tripId, seatsToDeduct: seatsToDeduct),
      successMessage: 'تم قبول الحجز بنجاح!',
      refreshAfterSuccess: true,
    );

  Future<void> rejectBooking(String bookingId, String tripId, String passengerId) async =>
    _performAction(
      action: () => rejectPassengerBookingUseCase(bookingId: bookingId, tripId: tripId, passengerId: passengerId),
      successMessage: 'تم رفض الطلب بنجاح',
      refreshAfterSuccess: false, 
    );

  Future<void> cancelBooking(String bookingId, String tripId, String passengerId, int seatsToReturn, bool wasAccepted) async =>
    _performAction(
      action: () => cancelPassengerBookingUseCase(bookingId: bookingId, tripId: tripId, passengerId: passengerId, seatsToReturn: seatsToReturn, wasAccepted: wasAccepted),
      successMessage: 'تم إلغاء الحجز بنجاح',
      refreshAfterSuccess: true,
    );

  Future<void> activateDriverTripFunction(String tripId) async =>
    _performAction(
      action: () => activateDriverTripUseCase(tripId, _currentUserId),
      successMessage: 'تم تفعيل الرحلة بنجاح!',
      refreshAfterSuccess: true,
    );

  Future<void> updateTripState(String tripId, String status) async =>
    _performAction(
      action: () => updateTripStatusUseCase(tripId, status),
      successMessage: 'تم تحديث حالة الرحلة بنجاح',
      refreshAfterSuccess: false,
    );

  Future<bool> checkHasActiveTrip(String driverId) async {
    if (driverId.isEmpty) return false;
    final result = await checkHasActiveTripUseCase(driverId);
    return result.fold((failure) => false, (hasActive) => hasActive);
  }

  Future<void> syncLocation(String tripId, double lat, double lng) async {
    await syncDriverLocationUseCase(tripId, GeoPoint(lat, lng));
  }

  Future<void> _backgroundRefresh() async {
    final result = await getDriverActiveTripsUseCase(uid: _currentUserId, limit: _trips.length > _limit ? _trips.length : _limit);
    if (isClosed) return;
    
    result.fold(
      (failure) => debugPrint('⚠️ فشل التحديث بالخلفية: $failure'), 
      (trips) {
        _trips.clear();
        _handleNewTrips(trips);
      },
    );
  }

  void _resetPagination() {
    _trips.clear();
    _hasReachedMax = false;
    _isFetchingMore = false;
  }

  void _handleNewTrips(List<TripModel> newTrips, {bool isPagination = false}) {
    if (newTrips.isEmpty && isPagination) {
      _hasReachedMax = true;
    } else {
      _trips.addAll(newTrips);
      _hasReachedMax = newTrips.length < _limit;
    }
    emit(_buildLoadedState());
  }

  DriverActiveTripsLoaded _buildLoadedState() {
    return DriverActiveTripsLoaded(
      trips: List.from(_trips),
      hasReachedMax: _hasReachedMax,
      isFetchingMore: _isFetchingMore,
    );
  }
}