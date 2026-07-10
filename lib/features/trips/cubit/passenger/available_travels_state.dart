import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
// تأكد من استدعاء موديل مخصص للواجهة يجمع الرحلة مع مسافتها
import '../../data/models/trip_model.dart';

// موديل مساعد للواجهة عشان نربط الرحلة بالمسافة
class ProcessedTrip {
  final TripModel trip;
  final double distance;
  ProcessedTrip({required this.trip, required this.distance});
}

@immutable
abstract class AvailableTravelsState {}

class AvailableTravelsInitial extends AvailableTravelsState {}

class AvailableTravelsLoading extends AvailableTravelsState {}

class AvailableTravelsLoaded extends AvailableTravelsState {
  final List<ProcessedTrip> trips;
  final bool showOnlyNearby;
  final Position? passengerPosition;
  
  // متغيرات الـ Pagination
  final bool hasReachedMax;
  final bool isFetchingMore;

  AvailableTravelsLoaded({
    required this.trips,
    required this.showOnlyNearby,
    this.passengerPosition,
    this.hasReachedMax = false,
    this.isFetchingMore = false,
  });

  AvailableTravelsLoaded copyWith({
    List<ProcessedTrip>? trips,
    bool? showOnlyNearby,
    Position? passengerPosition,
    bool? hasReachedMax,
    bool? isFetchingMore,
  }) {
    return AvailableTravelsLoaded(
      trips: trips ?? this.trips,
      showOnlyNearby: showOnlyNearby ?? this.showOnlyNearby,
      passengerPosition: passengerPosition ?? this.passengerPosition,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }
}

class AvailableTravelsError extends AvailableTravelsState {
  final String message;
  AvailableTravelsError(this.message);
}