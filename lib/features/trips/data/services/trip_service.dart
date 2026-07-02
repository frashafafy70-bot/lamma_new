import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:lamma_new/features/trips/data/models/trip_model.dart'; // مسار الموديل

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. الدالة دي هي اللي الكيوبت (passenger_request_cubit) محتاجها وبيدور عليها
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
        'status': 'pending', 
        'createdAt': FieldValue.serverTimestamp(),
        'pickupLocation': pickupLocation,
      });
    } catch (e) {
      throw Exception('حدث خطأ أثناء الطلب: $e');
    }
  }

  // 3. 🟢 دالة إضافة رحلة السفر (نقلناها هنا عشان الـ Cubit ينضف)
  Future<void> addTravelTrip(TripModel trip) async {
    try {
      await _firestore.collection('trips').add(trip.toMap());
    } catch (e) {
      throw Exception('حدث خطأ أثناء نشر رحلة السفر: $e');
    }
  }

  // 4. 🟢 ستريم لحساب طلبات الكابتن النشطة بالكامل
  Stream<int> getCaptainActiveOrdersCountStream(String uid) {
    var bookingsStream = _firestore
        .collection('trip_bookings')
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'accepted', 'negotiating'])
        .snapshots();

    var tripsStream = _firestore
        .collection('trips')
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['accepted', 'negotiating', 'arrived', 'started'])
        .snapshots();

    return Rx.combineLatest2(
      bookingsStream,
      tripsStream,
      (QuerySnapshot bookings, QuerySnapshot trips) => bookings.docs.length + trips.docs.length,
    );
  }

  // 5. 🟢 ستريم لحساب طلبات العميل النشطة بالكامل
  Stream<int> getPassengerActiveOrdersCountStream(String uid) {
    var tripsStream = _firestore
        .collection('trips')
        .where('passengerId', isEqualTo: uid)
        .where('isDriverPost', isEqualTo: false)
        .snapshots();

    var bookingsStream = _firestore
        .collection('trip_bookings')
        .where('passengerId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'accepted', 'negotiating'])
        .snapshots();

    return Rx.combineLatest2(
      tripsStream,
      bookingsStream,
      (QuerySnapshot trips, QuerySnapshot bookings) {
        int validTrips = 0;
        for (var doc in trips.docs) {
          final data = (doc.data() as Map<String, dynamic>?) ?? {}; 
          bool isDeleted = data['isDeletedForPassenger'] == true || data['isDeleted'] == true;
          String status = data['status'] ?? '';
          bool isFinished = status == 'canceled' || status == 'completed';
          if (!isDeleted && !isFinished) validTrips++;
        }
        return validTrips + bookings.docs.length;
      }
    );
  }
}