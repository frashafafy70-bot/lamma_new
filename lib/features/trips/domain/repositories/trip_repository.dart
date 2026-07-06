import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/trip_model.dart';

abstract class TripRepository {
  /// دالة لإنشاء طلب رحلة جديد باستخدام Map (كما يطلب الكيوبت الحالي)
  Future<void> createNewTripRequest(Map<String, dynamic> tripData);
  
  /// دالة بديلة لإرسال طلب الرحلة بالمتغيرات المباشرة (احتياطية)
  Future<void> submitTripRequest({
    required String pickupAddress,
    required String dropoffAddress,
    required String price,
    required GeoPoint pickupLocation,
  });
  
  /// دالة إضافة رحلة السفر باستخدام الـ Model
  Future<void> addTravelTrip(TripModel trip);
  
  /// ستريم لحساب طلبات السائق النشطة بالكامل
  Stream<int> getDriverActiveOrdersCountStream(String uid);
  
  /// ستريم لحساب طلبات العميل النشطة بالكامل
  Stream<int> getPassengerActiveOrdersCountStream(String uid);
}