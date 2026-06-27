import 'package:cloud_firestore/cloud_firestore.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// دالة إنشاء طلب رحلة أو أوردر جديد في الفايربيز بالبيانات الكاملة بدون أي نقص
  Future<void> createNewTripRequest(Map<String, dynamic> tripData) async {
    try {
      await _firestore.collection('trips').add(tripData);
    } catch (e) {
      throw 'FIREBASE_ERROR: $e';
    }
  }
}