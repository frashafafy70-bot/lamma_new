import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/usecases/update_driver_location_usecase.dart';
import 'driver_location_state.dart';

class DriverLocationCubit extends Cubit<DriverLocationState> {
  final UpdateDriverLocationUseCase updateDriverLocationUseCase;

  StreamSubscription<Position>? _positionStream;
  DateTime? _lastUpdateTime;
  String _currentUserId = '';

  DriverLocationCubit({
    required this.updateDriverLocationUseCase,
  }) : super(DriverLocationInitial());

  void startLocationTracking(String uid) {
    if (uid.isEmpty) {
      emit(DriverLocationError('السائق غير مسجل الدخول.'));
      return;
    }

    _currentUserId = uid;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );

    emit(DriverLocationTracking());

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen(_handleThrottledUpdate, onError: (error) {
      if (!isClosed)
        emit(DriverLocationError('حدث خطأ في تتبع الموقع: $error'));
    });
  }

  void _handleThrottledUpdate(Position position) {
    final now = DateTime.now();

    if (_lastUpdateTime == null ||
        now.difference(_lastUpdateTime!).inSeconds >= 10) {
      _lastUpdateTime = now;
      _syncLocationWithServer(position);
    }
  }

  Future<void> _syncLocationWithServer(Position position) async {
    final result = await updateDriverLocationUseCase(
      uid: _currentUserId,
      latitude: position.latitude,
      longitude: position.longitude,
    );

    result.fold(
      (failure) => debugPrint('🔥 خطأ أثناء تحديث الموقع: $failure'),
      (_) => debugPrint('📍 تم تحديث الموقع بنجاح (بعد الفلترة)'),
    );
  }

  @override
  Future<void> close() {
    _positionStream?.cancel();
    return super.close();
  }
}
