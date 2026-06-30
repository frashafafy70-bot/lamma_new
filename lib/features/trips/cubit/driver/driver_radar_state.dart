import 'package:cloud_firestore/cloud_firestore.dart';

abstract class DriverRadarState {}

class DriverRadarInitial extends DriverRadarState {}
class DriverRadarLoading extends DriverRadarState {}

class DriverRadarLoaded extends DriverRadarState {
  final List<DocumentSnapshot> trips;
  DriverRadarLoaded(this.trips);
}

class DriverRadarError extends DriverRadarState {
  final String message;
  DriverRadarError(this.message);
}

class DriverRadarAcceptingTrip extends DriverRadarState {}
class DriverRadarAcceptSuccess extends DriverRadarState {}
class DriverRadarAcceptFailed extends DriverRadarState {
  final String message;
  DriverRadarAcceptFailed(this.message);
}