import 'package:flutter/foundation.dart';
import '../../data/models/trip_model.dart';

@immutable
abstract class DriverHistoryState {}

class DriverHistoryInitial extends DriverHistoryState {}

class DriverHistoryLoading extends DriverHistoryState {}

class DriverHistoryLoaded extends DriverHistoryState {
  final List<TripModel> trips;
  final bool hasReachedMax;
  final bool isFetchingMore;

  DriverHistoryLoaded({
    required this.trips,
    this.hasReachedMax = false,
    this.isFetchingMore = false,
  });

  DriverHistoryLoaded copyWith({
    List<TripModel>? trips,
    bool? hasReachedMax,
    bool? isFetchingMore,
  }) {
    return DriverHistoryLoaded(
      trips: trips ?? this.trips,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }
}

class DriverHistoryError extends DriverHistoryState {
  final String message;
  DriverHistoryError(this.message);
}