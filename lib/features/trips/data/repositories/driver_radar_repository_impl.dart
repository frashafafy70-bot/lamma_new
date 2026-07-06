import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lamma_new/features/trips/data/models/trip_model.dart';
import '../../domain/repositories/driver_radar_repository.dart';

class DriverRadarRepositoryImpl implements DriverRadarRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DriverRadarRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';
  String get _currentUserName => _auth.currentUser?.displayName ?? 'سائق لَمَّة';

  @override
  Stream<List<TripModel>> getRadarTripsStream() {
    return _firestore
        .collection('trips')
        .where('isDriverPost', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      
      List<TripModel> activeTrips = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        
        // 🟢 تطبيق قواعد العمل (Business Logic) والفلترة هنا بدلاً من واجهة المستخدم
        if (data['isDeletedForDriver'] == true) {
          continue; // تخطي هذه الرحلة
        }
        
        String status = data['status'] ?? '';
        String driverId = data['driverId'] ?? '';
        
        bool isPending = status == 'pending';
        bool isNegotiatingWithAnother = status == 'negotiating' && driverId != _currentUserId;
        
        if (isPending || isNegotiatingWithAnother) {
          // إذا طابقت الشروط، نقوم بتحويلها إلى TripModel وإضافتها للقائمة
          activeTrips.add(TripModel.fromMap(data, doc.id));
        }
      }
      
      return activeTrips;
    });
  }

  @override
  Future<void> acceptTripSecurely(String tripId, String? negotiatedPrice) async {
    final tripRef = _firestore.collection('trips').doc(tripId);
    final userRef = _firestore.collection('users').doc(_currentUserId);

    DocumentSnapshot driverDoc = await userRef.get();
    String driverName = driverDoc.exists
        ? (driverDoc.data() as Map<String, dynamic>)['name'] ?? _currentUserName
        : _currentUserName;

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot tripSnapshot = await transaction.get(tripRef);

      if (!tripSnapshot.exists) {
        throw Exception('TRIP_NOT_FOUND');
      }

      var tripData = tripSnapshot.data() as Map<String, dynamic>;
      String status = tripData['status'] ?? '';
      String? existingDriverId = tripData['driverId'];

      bool isPending = status == 'pending';
      bool isNegotiatingWithMe = status == 'negotiating' && existingDriverId == _currentUserId;
      bool isNegotiatingWithoutDriver = status == 'negotiating' && (existingDriverId == null || existingDriverId.isEmpty);

      if (!(isPending || isNegotiatingWithMe || isNegotiatingWithoutDriver)) {
        throw Exception('TRIP_ALREADY_TAKEN');
      }

      Map<String, dynamic> updateData = {
        'status': 'accepted',
        'driverId': _currentUserId,
        'driverName': driverName,
        'acceptedAt': FieldValue.serverTimestamp(),
      };

      if (negotiatedPrice != null) {
        updateData['price'] = negotiatedPrice;
      }

      transaction.update(tripRef, updateData);
    });
  }

  @override
  Future<void> negotiateTrip(String tripId, String offer) async {
    await _firestore.collection('trips').doc(tripId).update({
      'status': 'negotiating',
      'driverId': _currentUserId,
      'negotiationPrice': offer,
      'lastNegotiator': 'driver'
    });
  }
}