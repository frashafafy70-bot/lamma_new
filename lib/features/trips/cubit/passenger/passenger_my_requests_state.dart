import '../../data/models/trip_model.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';

abstract class PassengerMyRequestsState {}

class PassengerMyRequestsInitial extends PassengerMyRequestsState {}

class PassengerMyRequestsLoading extends PassengerMyRequestsState {}

class PassengerMyRequestsLoaded extends PassengerMyRequestsState {
  final List<TripEntity> requests;
  final bool hasReachedMax;
  final bool isFetchingMore;

  PassengerMyRequestsLoaded({
    required this.requests,
    required this.hasReachedMax,
    required this.isFetchingMore,
  });

  PassengerMyRequestsLoaded copyWith({
    List<TripEntity>? requests,
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
