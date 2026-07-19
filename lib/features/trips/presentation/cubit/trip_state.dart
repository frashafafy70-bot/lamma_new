import '../../domain/entities/trip_entity.dart';

abstract class TripState {}

// 🟢 الحالة المبدئية
class TripInitial extends TripState {}

// 🟢 حالات التحميل العام (مثلاً عند الإضافة أو الحذف)
class TripLoading extends TripState {}

// 🟢 حالات النجاح والفشل للعمليات العامة
class TripOperationSuccess extends TripState {
  final String message;
  TripOperationSuccess(this.message);
}

class TripOperationFailure extends TripState {
  final String error;
  TripOperationFailure(this.error);
}

// 🟢 حالات خاصة بجلب الرحلات (Stream)
class TripsLoading extends TripState {}

class TripsLoaded extends TripState {
  final List<TripEntity> trips;
  TripsLoaded(this.trips);
}

class TripsError extends TripState {
  final String error;
  TripsError(this.error);
}

// 🟢 حالة خاصة بتحديث حالة رحلة معينة (للتفاوض أو القبول)
class TripStatusUpdated extends TripState {
  final String tripId;
  final String newStatus;
  TripStatusUpdated(this.tripId, this.newStatus);
}
