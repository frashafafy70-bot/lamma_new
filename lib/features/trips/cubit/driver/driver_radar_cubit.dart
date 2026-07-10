import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/driver_radar_repository.dart';
import '../../data/models/trip_model.dart';
import 'driver_radar_state.dart';

class DriverRadarCubit extends Cubit<DriverRadarState> {
  final DriverRadarRepository _repository;
  
  // 🟢 متغيرات التحكم في الـ Pagination
  List<TripModel> _trips = [];
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  final int _limit = 20;

  DriverRadarCubit(this._repository) : super(DriverRadarInitial());

  /// 🟢 جلب الصفحة الأولى من الرادار
  Future<void> fetchInitialRadarTrips() async {
    emit(DriverRadarLoading());
    
    _trips.clear();
    _hasReachedMax = false;
    _isFetchingMore = false;

    try {
      final result = await _repository.getPaginatedRadarTrips(limit: _limit);

      if (isClosed) return;

      result.fold(
        (failure) {
          emit(DriverRadarError('حدث خطأ في معالجة الطلبات.'));
        },
        (trips) {
          _trips = trips;
          _hasReachedMax = trips.length < _limit;
          
          emit(DriverRadarLoaded(
            radarTrips: List.from(_trips),
            hasReachedMax: _hasReachedMax,
            isFetchingMore: false,
          ));
        },
      );
    } catch (e) {
      if (!isClosed) emit(DriverRadarError('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  /// 🟢 جلب الصفحات الإضافية
  Future<void> fetchMoreRadarTrips() async {
    if (_hasReachedMax || _isFetchingMore) return;

    _isFetchingMore = true;
    final currentState = state;
    
    if (currentState is DriverRadarLoaded) {
      emit(currentState.copyWith(isFetchingMore: true));
    }

    try {
      final lastTrip = _trips.isNotEmpty ? _trips.last : null;
      
      final result = await _repository.getPaginatedRadarTrips(
        limit: _limit,
        lastTrip: lastTrip,
      );

      if (isClosed) return;

      result.fold(
        (failure) {
          _isFetchingMore = false;
          if (state is DriverRadarLoaded) {
            emit((state as DriverRadarLoaded).copyWith(isFetchingMore: false));
          }
        },
        (newTrips) {
          _isFetchingMore = false;
          
          if (newTrips.isEmpty) {
            _hasReachedMax = true;
          } else {
            _trips.addAll(newTrips);
            _hasReachedMax = newTrips.length < _limit;
          }
          
          emit(DriverRadarLoaded(
            radarTrips: List.from(_trips),
            hasReachedMax: _hasReachedMax,
            isFetchingMore: false,
          ));
        },
      );
    } catch (e) {
      _isFetchingMore = false;
      if (state is DriverRadarLoaded && !isClosed) {
        emit((state as DriverRadarLoaded).copyWith(isFetchingMore: false));
      }
    }
  }

  Future<void> acceptTrip(String tripId, {String? negotiatedPrice}) async {
    emit(DriverRadarActionLoading());
    try {
      await _repository.acceptTripSecurely(tripId, negotiatedPrice);
      if (isClosed) return;
      emit(DriverRadarActionSuccess('تم قبول الرحلة بنجاح'));
    } catch (e) {
      if (isClosed) return;
      String errorMessage = 'حدث خطأ غير متوقع';
      if (e.toString().contains('TRIP_NOT_FOUND')) {
        errorMessage = 'عذراً، هذه الرحلة لم تعد متوفرة';
      } else if (e.toString().contains('TRIP_ALREADY_TAKEN')) {
        errorMessage = 'عذراً، تم التقاط هذه الرحلة بواسطة سائق آخر';
      }
      emit(DriverRadarActionError(errorMessage));
    }
  }

  Future<void> negotiateTrip(String tripId, String offer) async {
    emit(DriverRadarActionLoading());
    try {
      await _repository.negotiateTrip(tripId, offer);
      if (isClosed) return;
      emit(DriverRadarActionSuccess('تم إرسال عرض السعر بنجاح'));
    } catch (e) {
      if (isClosed) return;
      emit(DriverRadarActionError('حدث خطأ أثناء التفاوض: ${e.toString()}'));
    }
  }
}