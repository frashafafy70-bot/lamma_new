import 'package:cloud_firestore/cloud_firestore.dart';

abstract class DriverActiveTripsState {}

class DriverActiveTripsInitial extends DriverActiveTripsState {}

class DriverActiveTripsLoading extends DriverActiveTripsState {}

class DriverActiveTripsLoaded extends DriverActiveTripsState {
  final List<QueryDocumentSnapshot> trips;

  DriverActiveTripsLoaded(this.trips);
}

class DriverActiveTripsError extends DriverActiveTripsState {
  final String message;

  DriverActiveTripsError(this.message);
}