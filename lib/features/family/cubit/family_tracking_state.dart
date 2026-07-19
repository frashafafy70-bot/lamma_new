abstract class FamilyTrackingState {}

class FamilyTrackingInitial extends FamilyTrackingState {}

class FamilyTrackingLoading extends FamilyTrackingState {}

class FamilyTrackingNoActiveTrip extends FamilyTrackingState {}

class FamilyTrackingActive extends FamilyTrackingState {
  final Map<String, dynamic> tripData;
  final double? driverLat;
  final double? driverLng;

  FamilyTrackingActive({
    required this.tripData,
    this.driverLat,
    this.driverLng,
  });
}

class FamilyTrackingError extends FamilyTrackingState {
  final String message;
  FamilyTrackingError(this.message);
}
