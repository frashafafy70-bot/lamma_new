import 'package:equatable/equatable.dart';
import '../../data/models/trip_model.dart';

abstract class TripBookingState extends Equatable {
  const TripBookingState();

  @override
  List<Object> get props => [];
}

class TripBookingInitial extends TripBookingState {}

// 🟢 حالات البحث
class TripSearchLoading extends TripBookingState {}
class TripSearchLoaded extends TripBookingState {
  final List<TripModel> trips;
  const TripSearchLoaded(this.trips);
  @override
  List<Object> get props => [trips];
}
class TripSearchError extends TripBookingState {
  final String message;
  const TripSearchError(this.message);
  @override
  List<Object> get props => [message];
}

// 🟢 حالات الحجز
class TripBookingLoading extends TripBookingState {}
class TripBookingSuccess extends TripBookingState {
  final String message;
  const TripBookingSuccess(this.message);
  @override
  List<Object> get props => [message];
}
class TripBookingError extends TripBookingState {
  final String message;
  const TripBookingError(this.message);
  @override
  List<Object> get props => [message];
}