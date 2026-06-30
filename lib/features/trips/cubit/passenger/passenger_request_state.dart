part of 'passenger_request_cubit.dart';

@immutable
abstract class PassengerRequestState {}

class PassengerRequestInitial extends PassengerRequestState {}

// 🟢 حالات جلب الموقع الحالي (Geolocator)
class LocationLoading extends PassengerRequestState {}

class LocationLoaded extends PassengerRequestState {
  final LatLng position;
  LocationLoaded(this.position);
}

class LocationPermissionDenied extends PassengerRequestState {}

class LocationError extends PassengerRequestState {
  final String message;
  LocationError(this.message);
}

// 🟢 حالات جلب العنوان (Reverse Geocoding)
class AddressLoading extends PassengerRequestState {}

class AddressLoaded extends PassengerRequestState {
  final String address;
  AddressLoaded(this.address);
}

class AddressError extends PassengerRequestState {
  final String message;
  AddressError(this.message);
}

// 🟢 حالات البحث عن أماكن (Autocomplete)
class PlacesSearchLoaded extends PassengerRequestState {
  final List<dynamic> predictions;
  PlacesSearchLoaded(this.predictions);
}

// 🟢 حالة جلب تفاصيل مكان معين
class PlaceDetailsLoaded extends PassengerRequestState {
  final LatLng location;
  final String description;
  PlaceDetailsLoaded(this.location, this.description);
}

// 🟢 حالات إرسال الطلب لقاعدة البيانات (Submit Trip)
class TripSubmitting extends PassengerRequestState {}

class TripSubmitSuccess extends PassengerRequestState {}

class TripSubmitError extends PassengerRequestState {
  final String message;
  TripSubmitError(this.message);
}