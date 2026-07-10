import 'package:flutter/foundation.dart';
import '../../data/models/trip_model.dart';

@immutable
abstract class PassengerMyRequestsState {}

class PassengerMyRequestsInitial extends PassengerMyRequestsState {}

class PassengerMyRequestsLoading extends PassengerMyRequestsState {}

class PassengerMyRequestsLoaded extends PassengerMyRequestsState {
  final List<TripModel> requests;
  final bool hasReachedMax;
  final bool isFetchingMore;

  PassengerMyRequestsLoaded({
    required this.requests,
    this.hasReachedMax = false,
    this.isFetchingMore = false,
  });

  PassengerMyRequestsLoaded copyWith({
    List<TripModel>? requests,
    bool? hasReachedMax,
    bool? isFetchingMore,
  }) {
    return PassengerMyRequestsLoaded(
      requests: requests ?? this.requests,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }
}

class PassengerMyRequestsError extends PassengerMyRequestsState {
  final String message;
  PassengerMyRequestsError(this.message);
}