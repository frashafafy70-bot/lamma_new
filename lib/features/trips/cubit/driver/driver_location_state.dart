abstract class DriverLocationState {}

class DriverLocationInitial extends DriverLocationState {}

class DriverLocationTracking extends DriverLocationState {}

class DriverLocationError extends DriverLocationState {
  final String message;

  DriverLocationError(this.message);
}
