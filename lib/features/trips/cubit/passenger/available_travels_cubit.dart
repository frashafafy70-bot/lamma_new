import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/usecases/get_available_travels_usecase.dart';
import '../../data/models/trip_model.dart';
import 'available_travels_state.dart'; 

class AvailableTravelsCubit extends Cubit<AvailableTravelsState> {
  final GetAvailableTravelsUseCase _getAvailableTravelsUseCase;

  Position? _passengerPosition;
  bool _showOnlyNearby = false;
  final double _nearbyRadiusInMeters = 20000;
  String _currentUserId = '';

  List<TripModel> _rawTrips = [];
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  final int _limit = 20;

  AvailableTravelsCubit(this._getAvailableTravelsUseCase) : super(AvailableTravelsInitial());

  void init(String userId) {
    _currentUserId = userId;
    _getPassengerLocation();
  }

  Future<void> _getPassengerLocation() async {
    if (isClosed) return;
    emit(AvailableTravelsLoading(trips: state.trips));

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _fetchInitialTrips();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _fetchInitialTrips();
        return;
      }
    }

    try {
      _passengerPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );
      _fetchInitialTrips();
    } catch (e) {
      _fetchInitialTrips();
    }
  }

  void toggleNearby(bool val) {
    if (_passengerPosition == null && val) {
      if (isClosed) return;
      emit(AvailableTravelsError('يرجى تفعيل الموقع (GPS) لاستخدام هذه الميزة', trips: state.trips));
      _getPassengerLocation();
      return;
    }
    _showOnlyNearby = val;
    _processAndEmitTrips();
  }

  Future<void> _fetchInitialTrips() async {
    if (isClosed) return;
    emit(AvailableTravelsLoading(trips: state.trips));

    _rawTrips.clear();
    _hasReachedMax = false;
    _isFetchingMore = false;

    try {
      final result = await _getAvailableTravelsUseCase(limit: _limit);

      if (isClosed) return;

      result.fold(
        (failure) => emit(AvailableTravelsError('حدث خطأ في تحميل الرحلات المتاحة.', trips: state.trips)),
        (trips) {
          _rawTrips = trips;
          _hasReachedMax = trips.length < _limit;
          _processAndEmitTrips();
        },
      );
    } catch (e) {
      if (!isClosed) emit(AvailableTravelsError('حدث خطأ غير متوقع', trips: state.trips));
    }
  }

  Future<void> fetchMoreTrips() async {
    if (_hasReachedMax || _isFetchingMore || isClosed) return;

    _isFetchingMore = true;
    if (state is AvailableTravelsLoaded) {
      emit((state as AvailableTravelsLoaded).copyWith(isFetchingMore: true));
    }

    try {
      final lastTrip = _rawTrips.isNotEmpty ? _rawTrips.last : null;
      final result = await _getAvailableTravelsUseCase(limit: _limit, lastTrip: lastTrip);

      if (isClosed) return;

      result.fold(
        (failure) {
          _isFetchingMore = false;
          if (state is AvailableTravelsLoaded) {
            emit((state as AvailableTravelsLoaded).copyWith(isFetchingMore: false));
          }
        },
        (newTrips) {
          _isFetchingMore = false;
          if (newTrips.isEmpty) {
            _hasReachedMax = true;
          } else {
            _rawTrips.addAll(newTrips);
            _hasReachedMax = newTrips.length < _limit;
          }
          _processAndEmitTrips();
        },
      );
    } catch (e) {
      _isFetchingMore = false;
      if (state is AvailableTravelsLoaded && !isClosed) {
        emit((state as AvailableTravelsLoaded).copyWith(isFetchingMore: false));
      }
    }
  }

  void _processAndEmitTrips() {
    if (isClosed) return;

    List<ProcessedTrip> processedTrips = [];

    for (TripModel trip in _rawTrips) {
      if (trip.driverId == _currentUserId) continue;

      int availableSeats = int.tryParse(trip.availableSeats ?? '0') ?? 0;
      if (availableSeats <= 0) continue;

      DateTime? tripDate = trip.travelDate;
      if (tripDate != null && tripDate.isBefore(DateTime.now())) {
        continue;
      } else if (tripDate == null && trip.createdAt != null) {
        if (DateTime.now().difference(trip.createdAt!).inDays > 2) {
          continue;
        }
      }

      double distance = double.infinity;
      if (trip.fromLocation != null && _passengerPosition != null) {
        distance = Geolocator.distanceBetween(
          _passengerPosition!.latitude,
          _passengerPosition!.longitude,
          trip.fromLocation!.latitude,
          trip.fromLocation!.longitude,
        );
      }

      if (_showOnlyNearby && distance > _nearbyRadiusInMeters) continue;

      processedTrips.add(ProcessedTrip(trip: trip, distance: distance));
    }

    processedTrips.sort((a, b) => a.distance.compareTo(b.distance));

    emit(AvailableTravelsLoaded(
      trips: processedTrips,
      showOnlyNearby: _showOnlyNearby,
      passengerPosition: _passengerPosition,
      hasReachedMax: _hasReachedMax,
      isFetchingMore: _isFetchingMore,
    ));
  }
}