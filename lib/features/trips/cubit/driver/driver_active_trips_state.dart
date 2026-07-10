import 'package:flutter/foundation.dart';
import '../../data/models/trip_model.dart';

@immutable
abstract class DriverActiveTripsState {}

class DriverActiveTripsInitial extends DriverActiveTripsState {}

class DriverActiveTripsLoading extends DriverActiveTripsState {}

class DriverActiveTripsLoaded extends DriverActiveTripsState {
  final List<TripModel> trips;
  final bool hasReachedMax;
  final bool isFetchingMore;

  DriverActiveTripsLoaded({
    required this.trips,
    this.hasReachedMax = false,
    this.isFetchingMore = false,
  });

  DriverActiveTripsLoaded copyWith({
    List<TripModel>? trips,
    bool? hasReachedMax,
    bool? isFetchingMore,
  }) {
    return DriverActiveTripsLoaded(
      trips: trips ?? this.trips,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }
}

class DriverActiveTripsError extends DriverActiveTripsState {
  final String message;
  DriverActiveTripsError(this.message);
}

class DriverActiveTripsActionLoading extends DriverActiveTripsState {}

class DriverActiveTripsActionSuccess extends DriverActiveTripsState {
  final String message;
  DriverActiveTripsActionSuccess(this.message);
}

class DriverActiveTripsActionError extends DriverActiveTripsState {
  final String message;
  DriverActiveTripsActionError(this.message);
}