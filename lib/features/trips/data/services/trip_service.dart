import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. 🟢 الدالة دي هي اللي الكيوبت (passenger_request_cubit) محتاجها وبيدور عليها
  Future<void> createNewTripRequest(Map<String, dynamic> tripData) async {
    try {
      await _firestore.collection('trips').add(tripData);
    } catch (e) {
      throw Exception('حدث خطأ أثناء إرسال الطلب: $e');
    }
  }

  // 2. الدالة دي القديمة بتاعتك، هنسيبها احتياطي لو بتستخدمها في مكان تاني مباشر
  Future<void> submitTripRequest({
    required String pickupAddress,
    required String dropoffAddress,
    required String price,
    required GeoPoint pickupLocation,
  }) async {
    try {
      String passengerId = _auth.currentUser!.uid;
      
      // جلب اسم العميل من قاعدة البيانات
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(passengerId).get();
      String clientName = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['name'] : 'عميل لَمَّة';

      // إرسال الطلب لمجموعة trips بحالة pending
      await _firestore.collection('trips').add({
        'passengerId': passengerId,
        'clientName': clientName,
        'tripCategory': 'رحلة وتوصيل',
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'price': price,
        'status': 'pending', // الحالة التي يسمع عليها الرادار
        'createdAt': FieldValue.serverTimestamp(),
        'pickupLocation': pickupLocation,
      });
    } catch (e) {
      throw Exception('حدث خطأ أثناء الطلب: $e');
    }
  }
}