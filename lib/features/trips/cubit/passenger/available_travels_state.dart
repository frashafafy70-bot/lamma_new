import '../../data/models/trip_model.dart'; 

class ProcessedTrip {
  final TripModel trip;
  final double distance;

  ProcessedTrip({required this.trip, required this.distance});
}

abstract class AvailableTravelsState {
  final List<ProcessedTrip> trips; 
  AvailableTravelsState({this.trips = const []});
}

class AvailableTravelsInitial extends AvailableTravelsState {
  AvailableTravelsInitial() : super(trips: []);
}

class AvailableTravelsLoading extends AvailableTravelsState {
  AvailableTravelsLoading({super.trips}); 
}

class AvailableTravelsLoaded extends AvailableTravelsState {
  final bool showOnlyNearby;
  final dynamic passengerPosition;
  final bool hasReachedMax;
  final bool isFetchingMore;

  AvailableTravelsLoaded({
    required super.trips,
    this.showOnlyNearby = false,
    this.passengerPosition,
    this.hasReachedMax = false,
    this.isFetchingMore = false,
  });

  AvailableTravelsLoaded copyWith({
    List<ProcessedTrip>? trips,
    bool? showOnlyNearby,
    dynamic passengerPosition,
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
  AvailableTravelsError(this.message, {super.trips});
}