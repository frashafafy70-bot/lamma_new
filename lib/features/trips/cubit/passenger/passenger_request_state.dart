part of 'passenger_request_cubit.dart';

abstract class PassengerRequestState {}

class PassengerRequestInitial extends PassengerRequestState {}

class LocationLoading extends PassengerRequestState {}
class LocationLoaded extends PassengerRequestState {
  final LatLng position;
  LocationLoaded(this.position);
}
class LocationError extends PassengerRequestState {
  final String message;
  LocationError(this.message);
}
class LocationPermissionDenied extends PassengerRequestState {}

class AddressLoading extends PassengerRequestState {}
class AddressLoaded extends PassengerRequestState {
  final String address;
  AddressLoaded(this.address);
}
class AddressError extends PassengerRequestState {
  final String message;
  AddressError(this.message);
}

class PlacesSearchLoaded extends PassengerRequestState {
  final List<PlaceSearchEntity> predictions;
  PlacesSearchLoaded(this.predictions);
}

class PlaceDetailsLoaded extends PassengerRequestState {
  final LatLng location;
  final String description;
  PlaceDetailsLoaded(this.location, this.description);
}

class TripSubmitting extends PassengerRequestState {}

// 🟢 التعديل الأهم: الحالة دي أصبحت تحمل معها معرف الرحلة
class TripSubmitSuccess extends PassengerRequestState {
  final String tripId;
  TripSubmitSuccess(this.tripId);
}

class TripSubmitError extends PassengerRequestState {
  final String message;
  TripSubmitError(this.message);
}

// 🟢 الحالة الجديدة لرسم المسار
class RouteCoordinatesLoaded extends PassengerRequestState {
  final List<LatLng> routePoints;
  RouteCoordinatesLoaded(this.routePoints);
}