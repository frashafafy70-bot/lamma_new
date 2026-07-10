import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
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

  // =======================================================
  // 🔥 دوال الـ Pagination لجميع قوائم التطبيق
  // =======================================================
  
  /// 1. جلب قائمة رحلات السائق النشطة
  Future<Either<Failure, List<TripModel>>> getDriverActiveTrips({
    required String uid,
    required int limit,
    TripModel? lastTrip, 
  });

  /// 2. جلب قائمة طلبات العميل النشطة
  Future<Either<Failure, List<TripModel>>> getPassengerActiveTrips({
    required String uid,
    required int limit,
    TripModel? lastTrip, 
  });

  /// 3. جلب سجل رحلات السائق (المكتملة والملغية)
  Future<Either<Failure, List<TripModel>>> getDriverHistoryTrips({
    required String uid,
    required int limit,
    TripModel? lastTrip, 
  });

  /// 4. جلب الرحلات المتاحة (التي ينشرها السائقون للركاب)
  Future<Either<Failure, List<TripModel>>> getAvailableTravels({
    required int limit,
    TripModel? lastTrip, 
  });
}