import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/trip_model.dart';

abstract class TripBookingRepository {
  // دالة البحث عن رحلات بناءً على مدينة الانطلاق والوصول
  Future<Either<Failure, List<TripModel>>> searchTrips({
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