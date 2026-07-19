import 'package:equatable/equatable.dart';
import '../../data/models/trip_model.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';

abstract class DriverHistoryState extends Equatable {
  const DriverHistoryState();

  @override
  List<Object> get props => [];
}

class DriverHistoryInitial extends DriverHistoryState {}

class DriverHistoryLoading extends DriverHistoryState {}

class DriverHistoryLoaded extends DriverHistoryState {
  final List<TripEntity> trips;
  final bool hasReachedMax;
  final bool isFetchingMore;

  const DriverHistoryLoaded({
    required this.trips,
    required this.hasReachedMax,
    required this.isFetchingMore,
  });

  DriverHistoryLoaded copyWith({
    List<TripEntity>? trips,
    bool? hasReachedMax,
    bool? isFetchingMore,
  }) {
    return DriverHistoryLoaded(
      trips: trips ?? this.trips,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }

  @override
  List<Object> get props => [trips, hasReachedMax, isFetchingMore];
}

class DriverHistoryError extends DriverHistoryState {
  final String message;

  const DriverHistoryError(this.message);

  @override
  List<Object> get props => [message];
}

// 🟢 الحالات الجديدة الخاصة بتنفيذ الأوامر (مسح، إلغاء)
class DriverHistoryActionLoading extends DriverHistoryState {}

class DriverHistoryActionSuccess extends DriverHistoryState {
  final String message;

  const DriverHistoryActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class DriverHistoryActionError extends DriverHistoryState {
  final String message;

  const DriverHistoryActionError(this.message);

  @override
  List<Object> get props => [message];
}
