import 'package:flutter/foundation.dart';
import '../../data/models/trip_model.dart';

@immutable
abstract class DriverRadarState {}

class DriverRadarInitial extends DriverRadarState {}
class DriverRadarLoading extends DriverRadarState {}

class DriverRadarLoaded extends DriverRadarState {
  final List<TripModel> radarTrips; 
  DriverRadarLoaded(this.radarTrips);
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