import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';
import '../../domain/usecases/get_available_travels_usecase.dart';
import '../../domain/usecases/book_seat_in_driver_post_usecase.dart'; // 🟢 الـ UseCase الصحيحة
import 'available_travels_state.dart'; 

class AvailableTravelsCubit extends Cubit<AvailableTravelsState> {
  final GetAvailableTravelsUseCase _getAvailableTravelsUseCase;
  final BookSeatInDriverPostUseCase _bookSeatInDriverPostUseCase; // 🟢 تمرير الـ UseCase هنا

  Position? _passengerPosition;
  bool _showOnlyNearby = false;
  final double _nearbyRadiusInMeters = 20000;
  String _currentUserId = '';

  List<TripEntity> _rawTrips = [];
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  final int _limit = 20;

  AvailableTravelsCubit(
    this._getAvailableTravelsUseCase,
    this._bookSeatInDriverPostUseCase,
  ) : super(AvailableTravelsInitial());

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

    for (TripEntity trip in _rawTrips) {
      if (trip.driverId == _currentUserId) continue;

      int availableSeats = trip.availableSeats ?? 0;
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

  // 🟢 دالة الحجز المربوطة بالدومين الصحيح
  Future<bool> bookDriverPost(String tripId, {int seatsToBook = 1}) async {
    String targetDriverId = '';
    
    // استخراج معرّف السائق من الرحلة المحفوظة في القائمة
    try {
      // ⚠️ استبدل `.id` بـ `.docId` لو ده اسم المتغير عندك في TripEntity
      final trip = _rawTrips.firstWhere((t) => t.id == tripId); 
      targetDriverId = trip.driverId ?? '';
    } catch (e) {
      emit(AvailableTravelsError('الرحلة غير موجودة أو تم حذفها', trips: state.trips));
      return false;
    }

    final result = await _bookSeatInDriverPostUseCase(
      tripId: tripId,
      driverId: targetDriverId,
      passengerId: _currentUserId,
      seatsToBook: seatsToBook,
    );
    
    return result.fold(
      (failure) {
        emit(AvailableTravelsError('حدث خطأ أثناء الحجز، يرجى المحاولة مرة أخرى', trips: state.trips));
        return false;
      },
      (_) => true,
    );
  }
}