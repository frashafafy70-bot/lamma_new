import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rxdart/rxdart.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/trip_repository.dart';
import '../models/trip_model.dart';
import '../../domain/entities/trip_entity.dart';

class TripRepositoryImpl implements TripRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String collectionName = 'trips';

  TripRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  TripModel _toModel(TripEntity trip) {
    return TripModel(
      id: trip.id,
      isDriverPost: trip.isDriverPost,
      driverId: trip.driverId,
      driverName: trip.driverName,
      passengerId: trip.passengerId,
      passengerName: trip.passengerName,
      tripCategory: trip.tripCategory,
      vehicleType: trip.vehicleType,
      pickup: trip.pickup,
      destination: trip.destination,
      pickupLocation: trip.pickupLocation,
      destinationLocation: trip.destinationLocation,
      fromCity: trip.fromCity,
      toCity: trip.toCity,
      fromLocation: trip.fromLocation,
      toLocation: trip.toLocation,
      time: trip.time,
      travelDate: trip.travelDate,
      tripType: trip.tripType,
      availableSeats: trip.availableSeats,
      suggestedPrice: trip.suggestedPrice,
      price: trip.price,
      seatPrice: trip.seatPrice,
      fullCarPrice: trip.fullCarPrice,
      finalPrice: trip.finalPrice,
      negotiationPrice: trip.negotiationPrice,
      lastNegotiator: trip.lastNegotiator,
      errandDetails: trip.errandDetails,
      errandCost: trip.errandCost,
      audioUrl: trip.audioUrl,
      status: trip.status,
      createdAt: trip.createdAt,
    );
  }

  @override
  Stream<List<TripEntity>> getTrips() {
    return _firestore.collection(collectionName).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TripModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  @override
  Stream<List<TripEntity>> getUserTrips(String userId) {
    return _firestore.collection(collectionName).where(
      Filter.or(Filter('driverId', isEqualTo: userId), Filter('passengerId', isEqualTo: userId))
    ).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TripModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  @override
  Future<TripEntity?> getTripById(String tripId) async {
    final doc = await _firestore.collection(collectionName).doc(tripId).get();
    if (doc.exists && doc.data() != null) {
      return TripModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  Future<Either<Failure, void>> addTrip(TripEntity trip) async {
    try {
      await _firestore.collection(collectionName).add(_toModel(trip).toMap());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء إضافة الرحلة: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTrip(TripEntity trip) async {
    try {
      if (trip.id == null) return Left(ServerFailure(message: "لا يمكن تحديث رحلة بدون ID"));
      await _firestore.collection(collectionName).doc(trip.id).update(_toModel(trip).toMap());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء تحديث الرحلة: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTrip(String tripId) async {
    try {
      await _firestore.collection(collectionName).doc(tripId).update({
        'isDeletedForDriver': true,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء مسح الرحلة: $e'));
    }
  }

  @override
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
        final String fileName = 'trips_audio/${DateTime.now().millisecondsSinceEpoch}.m4a';
        final Reference ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(orderAudioFile);
        audioUrl = await ref.getDownloadURL();
      }

      final String currentUserId = _auth.currentUser?.uid ?? '';
      final String currentUserName = _auth.currentUser?.displayName ?? 'عميل';
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
        'pickupLocation': pickupLat != null && pickupLng != null ? GeoPoint(pickupLat, pickupLng) : null,
        'destinationLocation': destinationLat != null && destinationLng != null ? GeoPoint(destinationLat, destinationLng) : null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      DocumentReference docRef = await _firestore.collection(collectionName).add(tripData);
      return Right(docRef.id);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء إرسال الطلب: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> submitTripRequest({
    required String pickupAddress,
    required String dropoffAddress,
    required String price,
    required GeoPoint pickupLocation,
  }) async {
    try {
      String passengerId = _auth.currentUser!.uid;
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(passengerId).get();
      String clientName = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['name'] : 'عميل لَمَّة';

      await _firestore.collection(collectionName).add({
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
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء الطلب: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addTravelTrip(TripModel trip) async {
    try {
      await _firestore.collection(collectionName).add(trip.toMap());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء نشر رحلة السفر: $e'));
    }
  }

  @override
  Stream<List<TripModel>> getTripsStream(String userId, {bool isPassenger = true}) {
    try {
      Query query = _firestore.collection(collectionName);
      if (isPassenger) {
        query = query.where('passengerId', isEqualTo: userId);
      } else {
        query = query.where('driverId', isEqualTo: userId);
      }
      query = query.orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => TripModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      });
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب الرحلات: $e');
    }
  }

  @override
  Stream<int> getDriverActiveOrdersCountStream(String uid) {
    var bookingsStream = _firestore.collection('trip_bookings')
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'accepted', 'negotiating']).snapshots();

    var tripsStream = _firestore.collection(collectionName)
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['available', 'accepted', 'negotiating', 'arrived', 'started', 'in_progress']).snapshots();

    return Rx.combineLatest2(
      bookingsStream,
      tripsStream,
      (QuerySnapshot bookings, QuerySnapshot trips) => bookings.docs.length + trips.docs.length,
    );
  }

  @override
  Stream<int> getPassengerActiveOrdersCountStream(String uid) {
    var tripsStream = _firestore.collection(collectionName)
        .where('passengerId', isEqualTo: uid)
        .where('isDriverPost', isEqualTo: false).snapshots();

    var bookingsStream = _firestore.collection('trip_bookings')
        .where('passengerId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'accepted', 'negotiating']).snapshots();

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

  @override
  Future<Either<Failure, List<TripModel>>> getDriverActiveTrips({
    required String uid,
    required int limit,
    TripModel? lastTrip,
  }) async {
    try {
      Query query = _firestore.collection(collectionName)
          .where('driverId', isEqualTo: uid)
          .where('status', whereIn: ['available', 'accepted', 'negotiating', 'arrived', 'started', 'in_progress']);

      final snapshot = await query.get();
      List<TripModel> trips = snapshot.docs.map((doc) => TripModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

      trips.sort((a, b) {
        final bTime = (b.createdAt as DateTime?) ?? DateTime.now();
        final aTime = (a.createdAt as DateTime?) ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      return Right(trips);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TripModel>>> getPassengerActiveTrips({
    required String uid,
    required int limit,
    TripModel? lastTrip,
  }) async {
    try {
      Query query = _firestore.collection(collectionName)
          .where('passengerId', isEqualTo: uid)
          .where('isDriverPost', isEqualTo: false);

      final snapshot = await query.get();
      List<TripModel> trips = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        bool isDeleted = data['isDeletedForPassenger'] == true || data['isDeleted'] == true;
        String status = data['status'] ?? '';
        bool isFinished = status == 'cancelled' || status == 'canceled' || status == 'completed';
        
        if (!isDeleted && !isFinished) {
          trips.add(TripModel.fromMap(data, doc.id));
        }
      }

      trips.sort((a, b) {
        final bTime = (b.createdAt as DateTime?) ?? DateTime.now();
        final aTime = (a.createdAt as DateTime?) ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      return Right(trips);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TripModel>>> getDriverHistoryTrips({
    required String uid,
    required int limit,
    TripModel? lastTrip,
  }) async {
    try {
      Query query = _firestore.collection(collectionName)
          .where('driverId', isEqualTo: uid)
          .where('status', whereIn: ['completed', 'canceled', 'cancelled']);

      final snapshot = await query.get();
      List<TripModel> historyTrips = [];
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['isDeletedForDriver'] == true) continue;
        historyTrips.add(TripModel.fromMap(data, doc.id));
      }

      historyTrips.sort((a, b) {
        final bTime = (b.createdAt as DateTime?) ?? DateTime.now();
        final aTime = (a.createdAt as DateTime?) ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      return Right(historyTrips);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e')); 
    }
  }

  @override
  Future<Either<Failure, List<TripModel>>> getAvailableTravels({
    required int limit,
    TripModel? lastTrip,
  }) async {
    try {
      Query query = _firestore.collection(collectionName)
          .where('isDriverPost', isEqualTo: true)
          .where('status', isEqualTo: 'available');

      final snapshot = await query.get();
      List<TripModel> availableTrips = snapshot.docs.map((doc) => TripModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

      availableTrips.sort((a, b) {
        final bTime = (b.createdAt as DateTime?) ?? DateTime.now();
        final aTime = (a.createdAt as DateTime?) ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      return Right(availableTrips);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e')); 
    }
  }

  @override
  Future<Either<Failure, void>> acceptPassengerBooking({
    required String bookingId,
    required String tripId,
    required int seatsToDeduct,
  }) async {
    try {
      final tripRef = _firestore.collection(collectionName).doc(tripId);
      final bookingRef = _firestore.collection('trip_bookings').doc(bookingId);

      await _firestore.runTransaction((transaction) async {
        final tripSnapshot = await transaction.get(tripRef);
        if (!tripSnapshot.exists) throw Exception('الرحلة غير موجودة');

        var tripData = tripSnapshot.data() as Map<String, dynamic>;
        int currentSeats = int.tryParse(tripData['availableSeats']?.toString() ?? '0') ?? 0;

        if (currentSeats < seatsToDeduct) throw Exception('لا يوجد مقاعد كافية متاحة الآن');
        
        transaction.update(bookingRef, {'status': 'accepted'});
        transaction.update(tripRef, {'availableSeats': (currentSeats - seatsToDeduct).toString()});
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectPassengerBooking({
    required String bookingId,
    required String tripId,
    required String passengerId,
  }) async {
    try {
      await _firestore.collection('trip_bookings').doc(bookingId).delete();
      await _firestore.collection(collectionName).doc(tripId).update({
        'bookedPassengersIds': FieldValue.arrayRemove([passengerId])
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelPassengerBooking({
    required String bookingId,
    required String tripId,
    required String passengerId,
    required int seatsToReturn,
    required bool wasAccepted,
  }) async {
    try {
      await _firestore.collection('trip_bookings').doc(bookingId).delete();
      if (wasAccepted) {
        await _firestore.runTransaction((transaction) async {
          final tripRef = _firestore.collection(collectionName).doc(tripId);
          final tripSnapshot = await transaction.get(tripRef);
          if (tripSnapshot.exists) {
             var tripData = tripSnapshot.data() as Map<String, dynamic>;
             int currentSeats = int.tryParse(tripData['availableSeats']?.toString() ?? '0') ?? 0;
             transaction.update(tripRef, {
                'availableSeats': (currentSeats + seatsToReturn).toString(),
                'bookedPassengersIds': FieldValue.arrayRemove([passengerId])
             });
          }
        });
      } else {
        await _firestore.collection(collectionName).doc(tripId).update({
          'bookedPassengersIds': FieldValue.arrayRemove([passengerId]),
        });
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateBookingSeats({
    required String bookingId,
    required int newSeats,
    required DateTime travelDate,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference bookingRef = _firestore.collection('trip_bookings').doc(bookingId);
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

  @override
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
      if (isDriver) updates['driverId'] = _auth.currentUser?.uid ?? '';
      await _firestore.collection(collectionName).doc(docId).update(updates);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e'));
    }
  }

  @override
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

      await _firestore.collection(collectionName).doc(tripId).update(updates);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء قبول العرض: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> rejectTripOffer({
    required String tripId,
  }) async {
    try {
      await _firestore.collection(collectionName).doc(tripId).update({
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

  @override
  Future<Either<Failure, void>> activateDriverTripFunction(String tripId, String driverId) async {
    try {
      await _firestore.collection(collectionName).doc(tripId).update({
        'status': 'in_progress',
        'driverActiveTripEnabled': true, 
        'startedAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('users').doc(driverId).update({'isBusy': true});
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTripStatus(String tripId, String status) async {
    try {
      await _firestore.collection(collectionName).doc(tripId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> syncDriverLocation(String tripId, double lat, double lng) async {
    try {
      await _firestore.collection(collectionName).doc(tripId).update({
        'driverLocation': GeoPoint(lat, lng),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkHasActiveTrip(String driverId) async {
    try {
      final snapshot = await _firestore.collection(collectionName).where('driverId', isEqualTo: driverId).get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        bool isNotDeleted = data['isDeletedForDriver'] != true;
        bool isActiveStatus = data['status'] == 'available' || data['status'] == 'negotiating' || data['status'] == 'accepted' || data['status'] == 'arrived' || data['status'] == 'in_progress';
        if (isNotDeleted && isActiveStatus) return const Right(true);
      }
      return const Right(false);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ أثناء التحقق: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelTrip({
    required String tripId, 
    required bool isDriver,
  }) async {
    try {
      List<WriteBatch> batches = [];
      WriteBatch currentBatch = _firestore.batch();
      int operationCount = 0;

      DocumentReference tripRef = _firestore.collection(collectionName).doc(tripId);
      currentBatch.update(tripRef, {
        'status': 'cancelled',
        'cancelledBy': isDriver ? 'driver' : 'passenger',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      operationCount++;

      if (isDriver) {
        QuerySnapshot bookingsSnapshot = await _firestore.collection('trip_bookings')
            .where('tripId', isEqualTo: tripId).get();

        for (var doc in bookingsSnapshot.docs) {
          if (operationCount >= 500) {
            batches.add(currentBatch);
            currentBatch = _firestore.batch();
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

  @override
  Future<Either<Failure, void>> startTrip(String tripId) async {
    try {
      await _firestore.collection(collectionName).doc(tripId).update({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء بدء الرحلة: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> completeTrip(String tripId) async {
    try {
      await _firestore.collection(collectionName).doc(tripId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء إنهاء الرحلة: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> submitTripRating({
    required String tripId,
    required double rating,
    required String comment,
  }) async {
    try {
      await _firestore.collection(collectionName).doc(tripId).update({
        'passengerRating': rating,
        'passengerComment': comment,
        'isRatedByPassenger': true,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء إرسال التقييم: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> publishTravelTrip(TripModel trip) async {
    try {
      await _firestore.collection(collectionName).add(trip.toMap());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء نشر الرحلة: $e'));
    }
  }

  // 🟢 الدالة الجديدة: حجز مقعد في رحلة سفر
  @override
  Future<Either<Failure, void>> bookSeatInDriverPost({
    required String tripId,
    required String driverId,
    required String passengerId,
    required int seatsToBook,
  }) async {
    try {
      WriteBatch batch = _firestore.batch();

      DocumentReference tripRef = _firestore.collection(collectionName).doc(tripId);
      batch.update(tripRef, {
        'bookedPassengersIds': FieldValue.arrayUnion([passengerId]),
      });

      DocumentReference bookingRef = _firestore.collection('trip_bookings').doc();
      batch.set(bookingRef, {
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
      return Left(ServerFailure(message: 'حدث خطأ أثناء حجز المقعد: $e'));
    }
  }
}