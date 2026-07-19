import 'package:geolocator/geolocator.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';

// 🟢 كلاس مساعد لربط الرحلة بالمسافة بتاعتها
class ProcessedTrip {
  final TripEntity trip;
  final double distance;

  ProcessedTrip({required this.trip, required this.distance});
}

abstract class AvailableTravelsState {
  final List<ProcessedTrip> trips;
  const AvailableTravelsState({this.trips = const []});
}

class AvailableTravelsInitial extends AvailableTravelsState {}

class AvailableTravelsLoading extends AvailableTravelsState {
  const AvailableTravelsLoading({super.trips});
}

class AvailableTravelsLoaded extends AvailableTravelsState {
  final bool showOnlyNearby;
  final Position? passengerPosition;
  final bool hasReachedMax;
  final bool isFetchingMore;

  const AvailableTravelsLoaded({
    required super.trips,
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
  const AvailableTravelsError(this.message, {super.trips});
}
