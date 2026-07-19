import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trip_entity.dart';

abstract class DriverRadarRepository {
  /// الاستماع لطلبات الرادار المتاحة وتصفيتها وإرجاعها كـ TripEntity
  Stream<List<TripEntity>> getRadarTripsStream();

  /// القبول الآمن للرحلة
  Future<Either<Failure, void>> acceptTripSecurely(
      String tripId, String? negotiatedPrice);

  /// التفاوض على الرحلة
  Future<Either<Failure, void>> negotiateTrip(String tripId, String offer);

  // --------------------------------------------------
  // 🔥 دالة الـ Pagination الجديدة
  // --------------------------------------------------

  /// جلب طلبات الرادار مع دعم الـ Pagination (لتقليل الضغط على الذاكرة)
  Future<Either<Failure, List<TripEntity>>> getPaginatedRadarTrips({
    required int limit,
    TripEntity? lastTrip,
  });
}
