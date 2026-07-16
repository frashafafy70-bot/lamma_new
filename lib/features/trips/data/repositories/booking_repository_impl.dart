import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final FirebaseFirestore _firestore;

  BookingRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, void>> acceptPassengerBooking({
    required String bookingId,
    required String tripId,
    required int seatsToDeduct,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final tripRef = _firestore.collection('trips').doc(tripId);
        final bookingRef = _firestore.collection('trip_bookings').doc(bookingId);

        final tripSnapshot = await transaction.get(tripRef);
        if (!tripSnapshot.exists) throw Exception('الرحلة غير موجودة');

        var tripData = tripSnapshot.data() as Map<String, dynamic>;
        int currentSeats = int.tryParse(tripData['availableSeats']?.toString() ?? '0') ?? 0;

        if (currentSeats < seatsToDeduct) throw Exception('لا يوجد مقاعد كافية');

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
      await _firestore.runTransaction((transaction) async {
        transaction.delete(_firestore.collection('trip_bookings').doc(bookingId));
        transaction.update(_firestore.collection('trips').doc(tripId), {
          'bookedPassengersIds': FieldValue.arrayRemove([passengerId])
        });
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ أثناء الرفض: $e'));
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
      await _firestore.runTransaction((transaction) async {
        transaction.delete(_firestore.collection('trip_bookings').doc(bookingId));
        
        final tripRef = _firestore.collection('trips').doc(tripId);
        final updateData = <String, dynamic>{
          'bookedPassengersIds': FieldValue.arrayRemove([passengerId])
        };

        if (wasAccepted) {
          final tripSnapshot = await transaction.get(tripRef);
          if (tripSnapshot.exists) {
            int currentSeats = int.tryParse((tripSnapshot.data() as Map)['availableSeats']?.toString() ?? '0') ?? 0;
            updateData['availableSeats'] = (currentSeats + seatsToReturn).toString();
          }
        }
        transaction.update(tripRef, updateData);
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في إلغاء الحجز: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> submitNegotiation({
    required String docId,
    required double offerPrice,
    required bool isDriver,
  }) async {
    try {
      await _firestore.collection('trips').doc(docId).update({
        'status': 'negotiating',
        'negotiationPrice': offerPrice,
        'lastNegotiator': isDriver ? 'driver' : 'passenger'
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في التفاوض: $e'));
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
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'accepted',
        'finalPrice': finalPrice,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في قبول العرض: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> rejectTripOffer({required String tripId}) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'pending',
        'negotiationPrice': FieldValue.delete(),
        'lastNegotiator': FieldValue.delete(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في رفض العرض: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> bookSeatInDriverPost({
    required String tripId,
    required String driverId,
    required String passengerId,
    required int seatsToBook,
  }) async {
    try {
      WriteBatch batch = _firestore.batch();
      batch.update(_firestore.collection('trips').doc(tripId), {
        'bookedPassengersIds': FieldValue.arrayUnion([passengerId]),
      });
      batch.set(_firestore.collection('trip_bookings').doc(), {
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
}