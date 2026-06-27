import 'package:cloud_firestore/cloud_firestore.dart';

abstract class DriverRadarState {}

class DriverRadarInitial extends DriverRadarState {}

class DriverRadarLoading extends DriverRadarState {}

class DriverRadarLoaded extends DriverRadarState {
  final List<QueryDocumentSnapshot> trips;
  DriverRadarLoaded(this.trips);
}

class DriverRadarError extends DriverRadarState {
  final String message;
  DriverRadarError(this.message);
}