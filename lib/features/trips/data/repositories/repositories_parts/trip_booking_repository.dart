part of 'trip_repository_impl.dart';

mixin TripBookingRepositoryMixin on TripRepositoryBase {
  Future<Either<Failure, List<TripEntity>>> searchTrips({
    required String fromCity,
    required String toCity,
  }) async {
    final String cacheKey = 'cached_trips_${fromCity}_$toCity';

    try {
      Query query = firestore
          .collection(collectionName)
          .where('isDriverPost', isEqualTo: true)
          .where('status', isEqualTo: 'available')
          .where('fromCity', isEqualTo: fromCity)
          .where('toCity', isEqualTo: toCity);

      final snapshot = await query.get();
      List<TripModel> searchResults = [];
      List<Map<String, dynamic>> cacheData = [];

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        searchResults.add(TripModel.fromMap(data, doc.id));
        data['id'] = doc.id;
        cacheData.add(data);
      }

      searchResults.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      await prefs.setString(cacheKey, json.encode(cacheData));
      return Right(searchResults);
    } on FirebaseException catch (e) {
      if (e.code == 'network-request-failed') {
        return _getCachedTrips(cacheKey);
      }
      return Left(
          ServerFailure(message: 'خطأ في الاتصال بالخادم: ${e.message}'));
    } on SocketException catch (_) {
      return _getCachedTrips(cacheKey);
    } catch (e) {
      return _getCachedTrips(cacheKey, fallbackError: 'حدث خطأ غير متوقع.');
    }
  }

  Either<Failure, List<TripModel>> _getCachedTrips(String cacheKey,
      {String? fallbackError}) {
    try {
      final cachedString = prefs.getString(cacheKey);
      if (cachedString != null) {
        final List<dynamic> decodedData = json.decode(cachedString);
        List<TripModel> cachedTrips = decodedData.map((data) {
          final mapData = data as Map<String, dynamic>;
          final id = mapData['id'] as String;
          return TripModel.fromMap(mapData, id);
        }).toList();
        return Right(cachedTrips);
      } else {
        return Left(ServerFailure(message: fallbackError ?? 'لا يوجد اتصال.'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'فشل في استرجاع البيانات.'));
    }
  }

  Future<Either<Failure, void>> bookTripSeat({
    required String tripId,
    required String driverId,
    required int requestedSeats,
  }) async {
    try {
      final passengerId = auth.currentUser?.uid;
      final passengerName = auth.currentUser?.displayName ?? 'عميل لَمَّة';

      if (passengerId == null) throw Exception("يجب تسجيل الدخول أولاً");

      final tripRef = firestore.collection(collectionName).doc(tripId);
      final bookingRef = firestore.collection('trip_bookings').doc();

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(tripRef);
        if (!snapshot.exists) throw Exception("عذراً، الرحلة غير متاحة.");

        final tripData = snapshot.data()!;
        final int currentAvailableSeats =
            int.tryParse(tripData['availableSeats']?.toString() ?? '0') ?? 0;

        if (currentAvailableSeats < requestedSeats) {
          throw Exception("لا يوجد مقاعد كافية.");
        }

        final int newSeatsCount = currentAvailableSeats - requestedSeats;
        transaction.update(tripRef, {
          'availableSeats': newSeatsCount.toString(),
          if (newSeatsCount == 0) 'status': 'in_progress',
        });

        transaction.set(bookingRef, {
          'tripId': tripId,
          'driverId': driverId,
          'passengerId': passengerId,
          'passengerName': passengerName,
          'requestedSeats': requestedSeats.toString(),
          'price': tripData['seatPrice'] ?? tripData['price'] ?? '0',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      return const Right(null);
    } on FirebaseException catch (e) {
      if (e.code == 'network-request-failed')
        return Left(ServerFailure(message: 'غير متصل بالإنترنت.'));
      return Left(ServerFailure(message: 'فشل في الحجز.'));
    } catch (e) {
      return Left(ServerFailure(
          message: e.toString().replaceAll('Exception: ', '').trim()));
    }
  }

  Future<Either<Failure, void>> acceptPassengerBooking({
    required String bookingId,
    required String tripId,
    required int seatsToDeduct,
  }) async {
    try {
      final tripRef = firestore.collection(collectionName).doc(tripId);
      final bookingRef = firestore.collection('trip_bookings').doc(bookingId);

      await firestore.runTransaction((transaction) async {
        final tripSnapshot = await transaction.get(tripRef);
        if (!tripSnapshot.exists) throw Exception('الرحلة غير موجودة');

        var tripData = tripSnapshot.data() as Map<String, dynamic>;
        int currentSeats =
            int.tryParse(tripData['availableSeats']?.toString() ?? '0') ?? 0;

        if (currentSeats < seatsToDeduct)
          throw Exception('لا يوجد مقاعد كافية');

        transaction.update(bookingRef, {'status': 'accepted'});
        transaction.update(tripRef,
            {'availableSeats': (currentSeats - seatsToDeduct).toString()});
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, void>> rejectPassengerBooking({
    required String bookingId,
    required String tripId,
    required String passengerId,
  }) async {
    try {
      await firestore.runTransaction((transaction) async {
        transaction
            .delete(firestore.collection('trip_bookings').doc(bookingId));
        transaction.update(firestore.collection(collectionName).doc(tripId), {
          'bookedPassengersIds': FieldValue.arrayRemove([passengerId])
        });
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ أثناء الرفض: $e'));
    }
  }

  Future<Either<Failure, void>> cancelPassengerBooking({
    required String bookingId,
    required String tripId,
    required String passengerId,
    required int seatsToReturn,
    required bool wasAccepted,
  }) async {
    try {
      await firestore.runTransaction((transaction) async {
        transaction
            .delete(firestore.collection('trip_bookings').doc(bookingId));

        final tripRef = firestore.collection(collectionName).doc(tripId);
        final updateData = <String, dynamic>{
          'bookedPassengersIds': FieldValue.arrayRemove([passengerId])
        };

        if (wasAccepted) {
          final tripSnapshot = await transaction.get(tripRef);
          if (tripSnapshot.exists) {
            int currentSeats = int.tryParse(
                    (tripSnapshot.data() as Map)['availableSeats']
                            ?.toString() ??
                        '0') ??
                0;
            updateData['availableSeats'] =
                (currentSeats + seatsToReturn).toString();
          }
        }
        transaction.update(tripRef, updateData);
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في إلغاء الحجز: $e'));
    }
  }

  Future<Either<Failure, void>> bookSeatInDriverPost({
    required String tripId,
    required String driverId,
    required String passengerId,
    required int seatsToBook,
  }) async {
    try {
      WriteBatch batch = firestore.batch();
      batch.update(firestore.collection(collectionName).doc(tripId), {
        'bookedPassengersIds': FieldValue.arrayUnion([passengerId]),
      });
      batch.set(firestore.collection('trip_bookings').doc(), {
        'tripId': tripId,
        'driverId': driverId,
        'passengerId': passengerId,
        'seats': seatsToBook,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في حجز المقعد: $e'));
    }
  }

  Future<Either<Failure, void>> updateBookingSeats({
    required String bookingId,
    required int newSeats,
    required DateTime travelDate,
  }) async {
    try {
      await firestore.runTransaction((transaction) async {
        DocumentReference bookingRef =
            firestore.collection('trip_bookings').doc(bookingId);
        transaction.update(bookingRef, {
          'requestedSeats': newSeats,
          'travelDate': Timestamp.fromDate(travelDate),
        });
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e'));
    }
  }
}
