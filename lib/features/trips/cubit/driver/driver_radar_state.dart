import 'package:flutter/foundation.dart';
import '../../data/models/trip_model.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';
@immutable
abstract class DriverRadarState {}

class DriverRadarInitial extends DriverRadarState {}

class DriverRadarLoading extends DriverRadarState {}

class DriverRadarLoaded extends DriverRadarState {
  final List<TripEntity> radarTrips; 
  final bool hasReachedMax;     
  final bool isFetchingMore;    

  DriverRadarLoaded({
    required this.radarTrips,
    this.hasReachedMax = false,
    this.isFetchingMore = false,
  });

  DriverRadarLoaded copyWith({
    List<TripEntity>? radarTrips,
    bool? hasReachedMax,
    bool? isFetchingMore,
  }) {
    return DriverRadarLoaded(
      radarTrips: radarTrips ?? this.radarTrips,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }
}

class DriverRadarError extends DriverRadarState {
  final String message;
  DriverRadarError(this.message);
}

class DriverRadarActionLoading extends DriverRadarState {}

class DriverRadarActionSuccess extends DriverRadarState {
  final String message;
  DriverRadarActionSuccess(this.message);
}

class DriverRadarActionError extends DriverRadarState {
  final String message;
  DriverRadarActionError(this.message);
}