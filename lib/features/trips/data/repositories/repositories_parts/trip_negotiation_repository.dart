part of 'trip_repository_impl.dart';

mixin TripNegotiationRepository on TripRepositoryBase {

  Future<Either<Failure, void>> submitNegotiation({
    required String docId,
    required double offerPrice,
    required bool isDriver,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'status': 'negotiating',
        'negotiationPrice': offerPrice,
        'lastNegotiator': isDriver ? 'driver' : 'passenger'
      };
      if (isDriver) updates['driverId'] = auth.currentUser?.uid ?? '';
      await firestore.collection(collectionName).doc(docId).update(updates);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في التفاوض: $e'));
    }
  }

  Future<Either<Failure, void>> acceptTripOffer({
    required String tripId,
    required String finalPrice,
    required bool isDriver,
    required String currentUserId,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'status': 'accepted',
        'finalPrice': finalPrice,
        'acceptedAt': FieldValue.serverTimestamp(),
      };
      if (isDriver) updates['driverId'] = currentUserId;

      await firestore.collection(collectionName).doc(tripId).update(updates);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء قبول العرض: $e'));
    }
  }

  Future<Either<Failure, void>> rejectTripOffer({
    required String tripId,
  }) async {
    try {
      await firestore.collection(collectionName).doc(tripId).update({
        'status': 'pending',
        'negotiationPrice': FieldValue.delete(),
        'lastNegotiator': FieldValue.delete(),
        'driverId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء رفض العرض: $e'));
    }
  }
}