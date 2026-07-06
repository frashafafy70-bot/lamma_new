import '../../data/models/trip_model.dart';

abstract class DriverRadarRepository {
  /// الاستماع لطلبات الرادار المتاحة وتصفيتها وإرجاعها كـ TripModel
  Stream<List<TripModel>> getRadarTripsStream();
  
  /// القبول الآمن للرحلة 
  Future<void> acceptTripSecurely(String tripId, String? negotiatedPrice);
  
  /// التفاوض على الرحلة
  Future<void> negotiateTrip(String tripId, String offer);
}