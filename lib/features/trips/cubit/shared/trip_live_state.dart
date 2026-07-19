import 'package:lamma_new/features/trips/data/models/trip_model.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';

abstract class TripLiveState {}

class TripLiveInitial extends TripLiveState {}

class TripLiveLoading extends TripLiveState {}

class TripLiveLoaded extends TripLiveState {
  final Map<String, dynamic> rawData;
  final TripEntity trip;
  final String status;

  TripLiveLoaded({
    required this.rawData,
    required this.trip,
    required this.status,
  });
}

class TripLiveError extends TripLiveState {
  final String message;
  TripLiveError(this.message);
}
