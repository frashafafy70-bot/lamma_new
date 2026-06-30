import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverRadarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get currentUserName => _auth.currentUser?.displayName ?? 'كابتن لَمَّة';

  // 1. الاستماع لطلبات الرادار
  Stream<QuerySnapshot> getRadarTripsStream() {
    return _firestore
        .collection('trips')
        .where('isDriverPost', isEqualTo: false)
        .snapshots();
  }

  // 2. القبول الآمن للرحلة 
  Future<void> acceptTripSecurely(String tripId, String? negotiatedPrice) async {
    final tripRef = _firestore.collection('trips').doc(tripId);
    final userRef = _firestore.collection('users').doc(currentUserId);

    DocumentSnapshot driverDoc = await userRef.get();
    String driverName = driverDoc.exists 
        ? (driverDoc.data() as Map<String, dynamic>)['name'] ?? currentUserName 
        : currentUserName;

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot tripSnapshot = await transaction.get(tripRef);

      if (!tripSnapshot.exists) {
        throw Exception('TRIP_NOT_FOUND');
      }

      var tripData = tripSnapshot.data() as Map<String, dynamic>;
      String status = tripData['status'] ?? '';
      String? existingDriverId = tripData['driverId'];

      bool isPending = status == 'pending';
      bool isNegotiatingWithMe = status == 'negotiating' && existingDriverId == currentUserId;
      bool isNegotiatingWithoutDriver = status == 'negotiating' && (existingDriverId == null || existingDriverId.isEmpty);

      if (!(isPending || isNegotiatingWithMe || isNegotiatingWithoutDriver)) {
        throw Exception('TRIP_ALREADY_TAKEN');
      }

      Map<String, dynamic> updateData = {
        'status': 'accepted',
        'driverId': currentUserId,
        'driverName': driverName,
        'acceptedAt': FieldValue.serverTimestamp(),
      };

      if (negotiatedPrice != null) {
        updateData['price'] = negotiatedPrice;
      }

      transaction.update(tripRef, updateData);
    });
  }

  // 3. التفاوض على الرحلة
  Future<void> negotiateTrip(String docId, String offer) async {
    await _firestore.collection('trips').doc(docId).update({
      'status': 'negotiating',
      'driverId': currentUserId,
      'negotiationPrice': offer,
      'lastNegotiator': 'driver'
    });
  }
}