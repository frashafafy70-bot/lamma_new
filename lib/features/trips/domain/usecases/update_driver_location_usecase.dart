import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

class UpdateDriverLocationUseCase {
  final FirebaseFirestore firestore;

  UpdateDriverLocationUseCase(this.firestore);

  Future<Either<dynamic, void>> call({
    required String uid,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await firestore.collection('drivers_locations').doc(uid).set({
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const Right(null);
    } catch (e) {
      return Left(e); 
    }
  }
}