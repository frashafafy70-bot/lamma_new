import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

// 🟢 استيراد الـ UseCases النظيفة
import '../../domain/usecases/get_driver_radar_trips_usecase.dart';
import '../../domain/usecases/accept_radar_trip_usecase.dart';
import '../../domain/usecases/negotiate_radar_trip_usecase.dart';

import '../../data/models/trip_model.dart';
import 'driver_radar_state.dart';

class DriverRadarCubit extends Cubit<DriverRadarState> {
  final GetDriverRadarTripsUseCase getDriverRadarTripsUseCase;
  final AcceptRadarTripUseCase acceptRadarTripUseCase;
  final NegotiateRadarTripUseCase negotiateRadarTripUseCase;
  
  final List<TripModel> _trips = [];
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  static const int _limit = 20;

  DriverRadarCubit({
    required this.getDriverRadarTripsUseCase, 
    required this.acceptRadarTripUseCase,
    required this.negotiateRadarTripUseCase,
  }) : super(DriverRadarInitial());

  // ==========================================
  // 🟢 نظام الـ Pagination
  // ==========================================
  Future<void> fetchInitialRadarTrips() async {
    emit(DriverRadarLoading());
    _resetPagination();

    try {
      final result = await getDriverRadarTripsUseCase(limit: _limit);

      if (isClosed) return;

      result.fold(
        (failure) => emit(DriverRadarError('حدث خطأ في معالجة الطلبات.')),
        (trips) => _handleNewTrips(trips),
      );
    } catch (e) {
      if (!isClosed) emit(DriverRadarError('حدث خطأ غير متوقع: $e'));
    }
  }

  Future<void> fetchMoreRadarTrips() async {
    if (_hasReachedMax || _isFetchingMore) return;

    _isFetchingMore = true;
    if (state is DriverRadarLoaded) {
      emit((state as DriverRadarLoaded).copyWith(isFetchingMore: true));
    }

    try {
      final lastTrip = _trips.isNotEmpty ? _trips.last : null;
      final result = await getDriverRadarTripsUseCase(
        limit: _limit,
        lastTrip: lastTrip,
      );

      if (isClosed) return;

      result.fold(
        (failure) {
          _isFetchingMore = false;
          emit(_buildLoadedState()); 
        },
        (newTrips) {
          _isFetchingMore = false;
          _handleNewTrips(newTrips, isPagination: true);
        },
      );
    } catch (e) {
      _isFetchingMore = false;
      if (!isClosed) emit(_buildLoadedState());
    }
  }

  // ==========================================
  // 🟢 الأكشنز (تم النقل للـ UseCases)
  // ==========================================
  Future<void> acceptTrip(String tripId, {String? negotiatedPrice}) async {
    emit(DriverRadarActionLoading());
    
    final result = await acceptRadarTripUseCase(tripId, negotiatedPrice: negotiatedPrice);
    
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(DriverRadarActionError(_mapAcceptTripError(failure.toString())));
        emit(_buildLoadedState());
      },
      (_) {
        emit(DriverRadarActionSuccess('تم قبول الرحلة بنجاح'));
        emit(_buildLoadedState()); 
      }
    );
  }

  Future<void> negotiateTrip(String tripId, String offer) async {
    emit(DriverRadarActionLoading());
    
    final result = await negotiateRadarTripUseCase(tripId, offer);
    
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(DriverRadarActionError('حدث خطأ أثناء التفاوض: $failure'));
        emit(_buildLoadedState());
      },
      (_) {
        emit(DriverRadarActionSuccess('تم إرسال عرض السعر بنجاح'));
        emit(_buildLoadedState());
      }
    );
  }

  // ==========================================
  // 🛠️ دوال مساعدة (Helpers)
  // ==========================================
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

  DriverRadarLoaded _buildLoadedState() {
    return DriverRadarLoaded(
      radarTrips: List.from(_trips),
      hasReachedMax: _hasReachedMax,
      isFetchingMore: _isFetchingMore,
    );
  }

  String _mapAcceptTripError(String error) {
    if (error.contains('TRIP_NOT_FOUND')) return 'عذراً، هذه الرحلة لم تعد متوفرة';
    if (error.contains('TRIP_ALREADY_TAKEN')) return 'عذراً، تم التقاط هذه الرحلة بواسطة سائق آخر';
    return 'حدث خطأ غير متوقع';
  }
}