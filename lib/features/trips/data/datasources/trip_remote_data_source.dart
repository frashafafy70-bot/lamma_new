import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

abstract class TripRemoteDataSource {
  Stream<List<TripModel>> getTrips();
  Stream<List<TripModel>> getUserTrips(String userId);
  Future<TripModel?> getTripById(String tripId);
  Future<void> addTrip(TripModel trip);
  Future<void> updateTrip(TripModel trip);
  Future<void> updateTripStatus(String tripId, String newStatus);
  Future<void> deleteTrip(String tripId);
}

class TripRemoteDataSourceImpl implements TripRemoteDataSource {
  final FirebaseFirestore firestore;

  TripRemoteDataSourceImpl({required this.firestore});

  final String collectionName = 'trips';

  @override
  Stream<List<TripModel>> getTrips() {
    return firestore.collection(collectionName).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TripModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Stream<List<TripModel>> getUserTrips(String userId) {
    return firestore
        .collection(collectionName)
        .where(
          Filter.or(
            Filter('driverId', isEqualTo: userId),
            Filter('passengerId', isEqualTo: userId),
          ),
        )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TripModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<TripModel?> getTripById(String tripId) async {
    final doc = await firestore.collection(collectionName).doc(tripId).get();
    if (doc.exists && doc.data() != null) {
      return TripModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  Future<void> addTrip(TripModel trip) async {
    await firestore.collection(collectionName).add(trip.toMap());
  }

  @override
  Future<void> updateTrip(TripModel trip) async {
    if (trip.id == null) throw Exception("لا يمكن تحديث رحلة بدون ID");
    await firestore
        .collection(collectionName)
        .doc(trip.id)
        .update(trip.toMap());
  }

  @override
  Future<void> updateTripStatus(String tripId, String newStatus) async {
    await firestore
        .collection(collectionName)
        .doc(tripId)
        .update({'status': newStatus});
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    await firestore.collection(collectionName).doc(tripId).delete();
  }
}
