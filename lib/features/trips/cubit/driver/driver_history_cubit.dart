import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_driver_history_trips_usecase.dart'; 
import '../../domain/usecases/cancel_trip_use_case.dart';
import '../../domain/usecases/delete_trip_usecase.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';
import '../../data/models/trip_model.dart';
import 'driver_history_state.dart';

class DriverHistoryCubit extends Cubit<DriverHistoryState> {
  final GetDriverHistoryTripsUseCase getDriverHistoryTripsUseCase;
  final CancelTripUseCase cancelTripUseCase;
  final DeleteTripUseCase deleteTripUseCase;

  String _currentUserId = '';
  final List<TripEntity> _trips = [];
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  static const int _limit = 15;

  DriverHistoryCubit({
    required this.getDriverHistoryTripsUseCase,
    required this.cancelTripUseCase,
    required this.deleteTripUseCase,
  }) : super(DriverHistoryInitial());

  void startListeningToHistoryTrips(String uid) {
    if (uid.isEmpty) return;
    _currentUserId = uid;
    fetchInitialHistoryTrips();
  }

  Future<void> fetchInitialHistoryTrips() async {
    if (_currentUserId.isEmpty) {
      emit(DriverHistoryError('لم يتم العثور على حساب السائق، يرجى تسجيل الدخول مجدداً.'));
      return;
    }

    emit(DriverHistoryLoading());
    
    _trips.clear();
    _hasReachedMax = false;
    _isFetchingMore = false;

    try {
      final result = await getDriverHistoryTripsUseCase(uid: _currentUserId, limit: _limit);

      if (isClosed) return;

      result.fold(
        (failure) => emit(DriverHistoryError(failure.message ?? 'حدث خطأ في تحميل السجل.')),
        (trips) {
          _trips.addAll(trips);
          _hasReachedMax = trips.length < _limit;
          emit(_buildLoadedState());
        },
      );
    } catch (e) {
      if (!isClosed) emit(DriverHistoryError('حدث خطأ غير متوقع: $e'));
    }
  }

  Future<void> fetchMoreHistoryTrips() async {
    if (_hasReachedMax || _isFetchingMore || _currentUserId.isEmpty) return;

    _isFetchingMore = true;
    if (state is DriverHistoryLoaded) {
      emit((state as DriverHistoryLoaded).copyWith(isFetchingMore: true));
    }

    try {
      final lastTrip = _trips.isNotEmpty ? _trips.last : null;
      final result = await getDriverHistoryTripsUseCase(
        uid: _currentUserId, 
        limit: _limit, 
        lastTrip: lastTrip,
      );

      if (isClosed) return;

      result.fold(
        (failure) {
          _isFetchingMore = false;
          emit(DriverHistoryError(failure.message ?? 'فشل جلب المزيد من الرحلات'));
          emit(_buildLoadedState()); 
        },
        (newTrips) {
          _isFetchingMore = false;
          if (newTrips.isEmpty) {
            _hasReachedMax = true;
          } else {
            _trips.addAll(newTrips);
            _hasReachedMax = newTrips.length < _limit;
          }
          emit(_buildLoadedState());
        },
      );
    } catch (e) {
      _isFetchingMore = false;
      if (!isClosed) {
        emit(DriverHistoryError('حدث خطأ في الاتصال'));
        emit(_buildLoadedState());
      }
    }
  }

  Future<void> cancelDriverTrip(String tripId) async {
    await _performAction(
      action: () => cancelTripUseCase(tripId: tripId, isDriver: true),
      successMessage: 'تم إلغاء الرحلة بنجاح',
      refreshAfterSuccess: true,
    );
  }

  Future<void> deleteTripFromHistory(String docId) async {
    await _performAction(
      action: () => deleteTripUseCase(docId),
      successMessage: 'تم مسح الرحلة من السجل بنجاح',
      refreshAfterSuccess: true,
    );
  }

  Future<void> _performAction({
    required Future<dynamic> Function() action,
    required String successMessage,
    required bool refreshAfterSuccess,
  }) async {
    emit(DriverHistoryActionLoading());
    
    final result = await action();
    
    if (isClosed) return;
    
    result.fold(
      (failure) {
        emit(DriverHistoryActionError(failure.message ?? 'حدث خطأ غير متوقع'));
        emit(_buildLoadedState()); 
      },
      (_) {
        emit(DriverHistoryActionSuccess(successMessage));
        if (refreshAfterSuccess) {
          _backgroundRefresh();
        } else {
          emit(_buildLoadedState());
        }
      }
    );
  }

  Future<void> _backgroundRefresh() async {
    final result = await getDriverHistoryTripsUseCase(
      uid: _currentUserId, 
      limit: _trips.length > _limit ? _trips.length : _limit
    );
    
    if (isClosed) return;
    
    result.fold(
      (failure) {
        debugPrint('⚠️ فشل التحديث بالخلفية للسجل: ${failure.message}');
      }, 
      (trips) {
        _trips.clear();
        _trips.addAll(trips);
        emit(_buildLoadedState());
      },
    );
  }

  DriverHistoryLoaded _buildLoadedState() {
    return DriverHistoryLoaded(
      trips: List.from(_trips),
      hasReachedMax: _hasReachedMax,
      isFetchingMore: _isFetchingMore,
    );
  }
}