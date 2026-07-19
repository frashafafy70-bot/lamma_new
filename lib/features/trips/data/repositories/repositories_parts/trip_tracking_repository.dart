part of 'trip_repository_impl.dart';

mixin TripTrackingRepository on TripRepositoryBase {
  Future<Either<Failure, void>> activateDriverTripFunction(
      String tripId, String driverId) async {
    try {
      await firestore.collection(collectionName).doc(tripId).update({
        'status': 'in_progress',
        'driverActiveTripEnabled': true,
        'startedAt': FieldValue.serverTimestamp(),
      });
      await firestore
          .collection('users')
          .doc(driverId)
          .update({'isBusy': true});
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e'));
    }
  }

  Future<Either<Failure, void>> updateTripStatus(
      String tripId, String status) async {
    try {
      await firestore.collection(collectionName).doc(tripId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e'));
    }
  }

  Future<Either<Failure, void>> syncDriverLocation(
      String tripId, double lat, double lng) async {
    try {
      await firestore.collection(collectionName).doc(tripId).update({
        'driverLocation': GeoPoint(lat, lng),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e'));
    }
  }

  Future<Either<Failure, void>> startTrip(String tripId) async {
    try {
      await firestore.collection(collectionName).doc(tripId).update({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء بدء الرحلة: $e'));
    }
  }

  Future<Either<Failure, void>> completeTrip(String tripId) async {
    try {
      await firestore.collection(collectionName).doc(tripId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء إنهاء الرحلة: $e'));
    }
  }

  Future<Either<Failure, void>> cancelTrip({
    required String tripId,
    required bool isDriver,
  }) async {
    try {
      List<WriteBatch> batches = [];
      WriteBatch currentBatch = firestore.batch();
      int operationCount = 0;

      DocumentReference tripRef =
          firestore.collection(collectionName).doc(tripId);
      currentBatch.update(tripRef, {
        'status': 'cancelled',
        'cancelledBy': isDriver ? 'driver' : 'passenger',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      operationCount++;

      if (isDriver) {
        QuerySnapshot bookingsSnapshot = await firestore
            .collection('trip_bookings')
            .where('tripId', isEqualTo: tripId)
            .get();

        for (var doc in bookingsSnapshot.docs) {
          if (operationCount >= 500) {
            batches.add(currentBatch);
            currentBatch = firestore.batch();
            operationCount = 0;
          }
          currentBatch.update(doc.reference, {
            'status': 'canceled_by_driver',
            'cancelledAt': FieldValue.serverTimestamp(),
          });
          operationCount++;
        }
      }

      batches.add(currentBatch);
      for (var batch in batches) {
        await batch.commit();
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e'));
    }
  }

  Future<Either<Failure, void>> submitTripRating({
    required String tripId,
    required double rating,
    required String comment,
  }) async {
    try {
      await firestore.collection(collectionName).doc(tripId).update({
        'passengerRating': rating,
        'passengerComment': comment,
        'isRatedByPassenger': true,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء إرسال التقييم: $e'));
    }
  }
}
