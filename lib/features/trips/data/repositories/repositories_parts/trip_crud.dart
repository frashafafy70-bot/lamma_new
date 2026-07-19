part of 'trip_repository_impl.dart';

mixin TripCoreRepository on TripRepositoryBase {
  Future<Either<Failure, void>> addTrip(TripEntity trip) async {
    try {
      await firestore.collection(collectionName).add(toModel(trip).toMap());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء إضافة الرحلة: $e'));
    }
  }

  Future<Either<Failure, void>> addTravelTrip(TripEntity trip) async {
    try {
      await firestore.collection(collectionName).add(toModel(trip).toMap());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء إضافة الرحلة: $e'));
    }
  }

  Future<Either<Failure, void>> updateTrip(TripEntity trip) async {
    try {
      if (trip.id == null)
        return Left(ServerFailure(message: "لا يمكن تحديث رحلة بدون ID"));
      await firestore
          .collection(collectionName)
          .doc(trip.id)
          .update(toModel(trip).toMap());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء تحديث الرحلة: $e'));
    }
  }

  Future<Either<Failure, void>> deleteTrip(String tripId) async {
    try {
      await firestore.collection(collectionName).doc(tripId).update({
        'isDeletedForDriver': true,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء مسح الرحلة: $e'));
    }
  }

  Future<TripEntity?> getTripById(String tripId) async {
    final doc = await firestore.collection(collectionName).doc(tripId).get();
    if (doc.exists && doc.data() != null) {
      return TripModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<Either<Failure, String>> createPassengerTrip({
    required String tripCategory,
    required String vehicleType,
    required String pickup,
    required String destination,
    required String price,
    String? errandDetails,
    String? errandCost,
    File? orderAudioFile,
    double? pickupLat,
    double? pickupLng,
    double? destinationLat,
    double? destinationLng,
  }) async {
    try {
      String? audioUrl;
      if (orderAudioFile != null) {
        final String fileName =
            'trips_audio/${DateTime.now().millisecondsSinceEpoch}.m4a';
        final Reference ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(orderAudioFile);
        audioUrl = await ref.getDownloadURL();
      }

      final String currentUserId = auth.currentUser?.uid ?? '';
      final String currentUserName = auth.currentUser?.displayName ?? 'عميل';
      bool isErrand = tripCategory == 'طلبات';

      Map<String, dynamic> tripData = {
        'isDriverPost': false,
        'passengerId': currentUserId,
        'passengerName': currentUserName,
        'tripCategory': tripCategory,
        'vehicleType': isErrand ? 'موتوسيكل' : vehicleType,
        'pickup': pickup,
        'destination': destination,
        'suggestedPrice': price,
        'price': price,
        'errandDetails': isErrand ? errandDetails : null,
        'errandCost': isErrand ? errandCost : null,
        'audioUrl': audioUrl,
        'pickupLocation': pickupLat != null && pickupLng != null
            ? GeoPoint(pickupLat, pickupLng)
            : null,
        'destinationLocation': destinationLat != null && destinationLng != null
            ? GeoPoint(destinationLat, destinationLng)
            : null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      DocumentReference docRef =
          await firestore.collection(collectionName).add(tripData);
      return Right(docRef.id);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء إرسال الطلب: $e'));
    }
  }

  Future<Either<Failure, void>> submitTripRequest({
    required String pickupAddress,
    required String dropoffAddress,
    required String price,
    required double pickupLat,
    required double pickupLng,
  }) async {
    try {
      String passengerId = auth.currentUser!.uid;
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(passengerId).get();
      String clientName = userDoc.exists
          ? (userDoc.data() as Map<String, dynamic>)['name']
          : 'عميل لَمَّة';

      await firestore.collection(collectionName).add({
        'passengerId': passengerId,
        'clientName': clientName,
        'tripCategory': 'رحلة وتوصيل',
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'price': price,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'pickupLocation': GeoPoint(pickupLat, pickupLng),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء الطلب: $e'));
    }
  }

  Future<Either<Failure, void>> publishTravelTrip(TripEntity trip) async {
    try {
      await firestore.collection(collectionName).add(toModel(trip).toMap());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء نشر الرحلة: $e'));
    }
  }
}
