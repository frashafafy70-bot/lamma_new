import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/trip_repository.dart';
import '../models/trip_model.dart';

class TripRepositoryImpl implements TripRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TripRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<void> createNewTripRequest(Map<String, dynamic> tripData) async {
    try {
      await _firestore.collection('trips').add(tripData);
    } catch (e) {
      throw Exception('حدث خطأ أثناء إرسال الطلب: $e');
    }
  }

  @override
  Future<void> submitTripRequest({
    required String pickupAddress,
    required String dropoffAddress,
    required String price,
    required GeoPoint pickupLocation,
  }) async {
    try {
      String passengerId = _auth.currentUser!.uid;
      
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(passengerId).get();
      String clientName = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['name'] : 'عميل لَمَّة';

      await _firestore.collection('trips').add({
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
    } catch (e) {
      throw Exception('حدث خطأ أثناء الطلب: $e');
    }
  }

  @override
  Future<void> addTravelTrip(TripModel trip) async {
    try {
      await _firestore.collection('trips').add(trip.toMap());
    } catch (e) {
      throw Exception('حدث خطأ أثناء نشر رحلة السفر: $e');
    }
  }

  @override
  Stream<List<TripModel>> getTripsStream(String userId, {bool isPassenger = true}) {
    try {
      Query query = _firestore.collection('trips');

      if (isPassenger) {
        query = query.where('passengerId', isEqualTo: userId);
      } else {
        query = query.where('driverId', isEqualTo: userId);
      }

      query = query.orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return TripModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      });
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب الرحلات: $e');
    }
  }

  @override
  Stream<int> getDriverActiveOrdersCountStream(String uid) {
    var bookingsStream = _firestore
        .collection('trip_bookings')
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'accepted', 'negotiating'])
        .snapshots();

    var tripsStream = _firestore
        .collection('trips')
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['available', 'accepted', 'negotiating', 'arrived', 'started', 'in_progress'])
        .snapshots();

    return Rx.combineLatest2(
      bookingsStream,
      tripsStream,
      (QuerySnapshot bookings, QuerySnapshot trips) => bookings.docs.length + trips.docs.length,
    );
  }

  @override
  Stream<int> getPassengerActiveOrdersCountStream(String uid) {
    var tripsStream = _firestore
        .collection('trips')
        .where('passengerId', isEqualTo: uid)
        .where('isDriverPost', isEqualTo: false)
        .snapshots();

    var bookingsStream = _firestore
        .collection('trip_bookings')
        .where('passengerId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'accepted', 'negotiating'])
        .snapshots();

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
      Query query = _firestore
          .collection('trips')
          .where('driverId', isEqualTo: uid)
          .where('status', whereIn: ['available', 'accepted', 'negotiating', 'arrived', 'started', 'in_progress']);

      final snapshot = await query.get();
      
      List<TripModel> trips = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TripModel.fromMap(data, doc.id); 
      }).toList();

      trips.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return Right(trips);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TripModel>>> getPassengerActiveTrips({
    required String uid,
    required int limit,
    TripModel? lastTrip,
  }) async {
    try {
      Query query = _firestore
          .collection('trips')
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
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return Right(trips);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TripModel>>> getDriverHistoryTrips({
    required String uid,
    required int limit,
    TripModel? lastTrip,
  }) async {
    try {
      Query query = _firestore
          .collection('trips')
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
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return Right(historyTrips);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: ${e.toString()}')); 
    }
  }

  @override
  Future<Either<Failure, List<TripModel>>> getAvailableTravels({
    required int limit,
    TripModel? lastTrip,
  }) async {
    try {
      Query query = _firestore
          .collection('trips')
          .where('isDriverPost', isEqualTo: true)
          .where('status', isEqualTo: 'available');

      final snapshot = await query.get();
      List<TripModel> availableTrips = [];
      
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        availableTrips.add(TripModel.fromMap(data, doc.id));
      }

      availableTrips.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return Right(availableTrips);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: ${e.toString()}')); 
    }
  }

  @override
  Future<Either<Failure, void>> acceptPassengerBooking({
    required String bookingId,
    required String tripId,
    required int seatsToDeduct,
  }) async {
    try {
      final tripRef = _firestore.collection('trips').doc(tripId);
      final bookingRef = _firestore.collection('trip_bookings').doc(bookingId);

      await _firestore.runTransaction((transaction) async {
        final tripSnapshot = await transaction.get(tripRef);
        if (!tripSnapshot.exists) throw Exception('الرحلة غير موجودة');

        var tripData = tripSnapshot.data() as Map<String, dynamic>;
        int currentSeats = int.tryParse(tripData['availableSeats']?.toString() ?? '0') ?? 0;

        if (currentSeats < seatsToDeduct) {
          throw Exception('لا يوجد مقاعد كافية متاحة الآن');
        }

        int newSeats = currentSeats - seatsToDeduct;
        
        transaction.update(bookingRef, {'status': 'accepted'});
        transaction.update(tripRef, {'availableSeats': newSeats.toString()});
      });

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString().replaceAll('Exception: ', '')));
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
      await _firestore.collection('trips').doc(tripId).update({
        'bookedPassengersIds': FieldValue.arrayRemove([passengerId])
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء الرفض: $e'));
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
          final tripRef = _firestore.collection('trips').doc(tripId);
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
        await _firestore.collection('trips').doc(tripId).update({
          'bookedPassengersIds': FieldValue.arrayRemove([passengerId]),
        });
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء الإلغاء: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> activateDriverTripFunction(String tripId, String driverId) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'in_progress',
        'driverActiveTripEnabled': true, 
        'startedAt': FieldValue.serverTimestamp(),
      });
      
      await _firestore.collection('users').doc(driverId).update({
        'isBusy': true,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء التفعيل: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTripStatus(String tripId, String status) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في تحديث حالة الرحلة: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> syncDriverLocation(String tripId, GeoPoint location) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'driverLocation': location,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في مزامنة الموقع: $e'));
    }
  }

  // ==========================================
  // 🌟 الدوال الجديدة (Clean Architecture 10/10)
  // ==========================================

  @override
  Future<Either<Failure, void>> cancelTrip({
    required String tripId, 
    required bool isDriver,
  }) async {
    try {
      List<WriteBatch> batches = [];
      WriteBatch currentBatch = _firestore.batch();
      int operationCount = 0;

      DocumentReference tripRef = _firestore.collection('trips').doc(tripId);
      currentBatch.update(tripRef, {
        'status': 'cancelled',
        'cancelledBy': isDriver ? 'driver' : 'passenger',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      operationCount++;

      if (isDriver) {
        QuerySnapshot bookingsSnapshot = await _firestore
            .collection('trip_bookings')
            .where('tripId', isEqualTo: tripId)
            .get();

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
    } on FirebaseException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'حدث خطأ في قاعدة البيانات'));
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء إلغاء الرحلة: $e'));
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
    } on FirebaseException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'حدث خطأ في الخادم'));
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء تعديل الحجز: $e'));
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
      
      if (isDriver) {
        updates['driverId'] = _auth.currentUser?.uid ?? '';
      }
      
      await _firestore.collection('trips').doc(docId).update(updates);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'حدث خطأ في الخادم'));
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء التفاوض: $e'));
    }
  }
}