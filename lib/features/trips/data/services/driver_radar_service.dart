import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lamma_new/core/constants/firebase_constants.dart';

class DriverRadarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get currentUserName => _auth.currentUser?.displayName ?? 'كابتن لَمَّة';

  // 1. الاستماع لطلبات الرادار
  Stream<QuerySnapshot> getRadarTripsStream() {
    return _firestore
        .collection(FirebaseConstants.tripsCollection)
        .where('isDriverPost', isEqualTo: false)
        .snapshots();
  }

  // 2. قبول الرحلة
  Future<void> acceptTrip(String docId, String agreedPrice) async {
    // هنجيب اسم الكابتن الفعلي من قاعدة بيانات المستخدمين (لو مش متسجل في الـ Auth)
    DocumentSnapshot driverDoc = await _firestore.collection('users').doc(currentUserId).get();
    String driverName = driverDoc.exists ? (driverDoc.data() as Map<String, dynamic>)['name'] : currentUserName;

    await _firestore.collection(FirebaseConstants.tripsCollection).doc(docId).update({
      FirebaseConstants.fieldStatus: 'accepted', // أو FirebaseConstants.statusAccepted لو موجودة
      'driverId': currentUserId, 
      'driverName': driverName,
      FirebaseConstants.fieldFinalPrice: agreedPrice,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. التفاوض على الرحلة
  Future<void> negotiateTrip(String docId, String offer) async {
    await _firestore.collection(FirebaseConstants.tripsCollection).doc(docId).update({
      FirebaseConstants.fieldStatus: FirebaseConstants.statusNegotiating, 
      'driverId': currentUserId, 
      FirebaseConstants.fieldNegotiationPrice: offer,
      FirebaseConstants.fieldLastNegotiator: 'driver'
    });
  }
}