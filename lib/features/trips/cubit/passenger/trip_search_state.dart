import 'package:equatable/equatable.dart';
import '../../data/models/trip_model.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';

abstract class TripSearchState extends Equatable {
  const TripSearchState();

  @override
  List<Object?> get props => [];
}

class TripSearchInitial extends TripSearchState {}

class TripSearchLoading extends TripSearchState {}

class TripSearchLoaded extends TripSearchState {
  final List<TripEntity> trips;

  const TripSearchLoaded(this.trips);

  @override
  List<Object?> get props => [trips];
}

class TripSearchError extends TripSearchState {
  final String message;

  const TripSearchError(this.message);

  @override
  List<Object?> get props => [message];
}