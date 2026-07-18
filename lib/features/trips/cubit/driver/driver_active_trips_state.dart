import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/trip_model.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';
@immutable
abstract class DriverActiveTripsState extends Equatable {
  const DriverActiveTripsState();

  @override
  List<Object?> get props => [];
}

// --- حالات تهيئة الشاشة وجلب البيانات ---

class DriverActiveTripsInitial extends DriverActiveTripsState {}

class DriverActiveTripsLoading extends DriverActiveTripsState {}

class DriverActiveTripsLoaded extends DriverActiveTripsState {
  final List<TripEntity> trips;
  final bool hasReachedMax;
  final bool isFetchingMore;

  const DriverActiveTripsLoaded({
    required this.trips,
    this.hasReachedMax = false,
    this.isFetchingMore = false,
  });

  DriverActiveTripsLoaded copyWith({
    List<TripEntity>? trips,
    bool? hasReachedMax,
    bool? isFetchingMore,
  }) {
    return DriverActiveTripsLoaded(
      trips: trips ?? this.trips,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }

  @override
  List<Object?> get props => [trips, hasReachedMax, isFetchingMore];
}

class DriverActiveTripsError extends DriverActiveTripsState {
  final String message;
  const DriverActiveTripsError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- حالة خطأ التمرير (لعدم تدمير القائمة المعروضة) ---
class DriverActiveTripsPaginationError extends DriverActiveTripsState {
  final String message;
  // أضفنا الطابع الزمني لضمان انطلاق الـ Listener لو تكرر نفس الخطأ مرتين متتاليتين
  final int timestamp; 

  DriverActiveTripsPaginationError(this.message) 
      : timestamp = DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object?> get props => [message, timestamp];
}

// --- حالات الإجراءات (Actions) ---

class DriverActiveTripsActionLoading extends DriverActiveTripsState {}

class DriverActiveTripsActionSuccess extends DriverActiveTripsState {
  final String message;
  final int timestamp;

  DriverActiveTripsActionSuccess(this.message)
      : timestamp = DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object?> get props => [message, timestamp];
}

class DriverActiveTripsActionError extends DriverActiveTripsState {
  final String message;
  final int timestamp;

  DriverActiveTripsActionError(this.message)
      : timestamp = DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object?> get props => [message, timestamp];
}