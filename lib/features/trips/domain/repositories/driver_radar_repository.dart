import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart'; // تأكد إن ده المسار الصحيح لملف الـ Failures عندك
import '../../data/models/trip_model.dart';

abstract class DriverRadarRepository {
  /// الاستماع لطلبات الرادار المتاحة وتصفيتها وإرجاعها كـ TripModel
  Stream<List<TripModel>> getRadarTripsStream();
  
  /// القبول الآمن للرحلة 
  Future<void> acceptTripSecurely(String tripId, String? negotiatedPrice);
  
  /// التفاوض على الرحلة
  Future<void> negotiateTrip(String tripId, String offer);

  // --------------------------------------------------
  // 🔥 دالة الـ Pagination الجديدة
  // --------------------------------------------------
  
  /// جلب طلبات الرادار مع دعم الـ Pagination (لتقليل الضغط على الذاكرة)
  Future<Either<Failure, List<TripModel>>> getPaginatedRadarTrips({
    required int limit,
    TripModel? lastTrip,
  });
}