import 'package:geolocator/geolocator.dart';

abstract class AvailableTravelsState {}

class AvailableTravelsInitial extends AvailableTravelsState {}

class AvailableTravelsLoading extends AvailableTravelsState {}

class AvailableTravelsLoaded extends AvailableTravelsState {
  final List<Map<String, dynamic>> trips;
  final bool showOnlyNearby;
  final Position? passengerPosition;

  AvailableTravelsLoaded({
    required this.trips,
    required this.showOnlyNearby,
    this.passengerPosition,
  });
}

class AvailableTravelsError extends AvailableTravelsState {
  final String message;
  AvailableTravelsError(this.message);
}