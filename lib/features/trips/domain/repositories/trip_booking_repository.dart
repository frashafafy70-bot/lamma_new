import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/trip_model.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';
abstract class TripBookingRepository {
  // دالة البحث عن رحلات بناءً على مدينة الانطلاق والوصول
  Future<Either<Failure, List<TripEntity>>> searchTrips({
    required String fromCity,
    required String toCity,
  });

  // دالة الحجز اللحظي عبر Transactions
  Future<Either<Failure, void>> bookTripSeat({
    required String tripId,
    required String driverId,
    required int requestedSeats,
  });
}