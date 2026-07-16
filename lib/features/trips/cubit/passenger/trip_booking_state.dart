import 'package:equatable/equatable.dart';

abstract class TripBookingState extends Equatable {
  const TripBookingState();

  @override
  List<Object?> get props => [];
}

class TripBookingInitial extends TripBookingState {}

class TripBookingLoading extends TripBookingState {}

class TripBookingSuccess extends TripBookingState {
  final String message;

  const TripBookingSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class TripBookingError extends TripBookingState {
  final String message;

  const TripBookingError(this.message);

  @override
  List<Object?> get props => [message];
}