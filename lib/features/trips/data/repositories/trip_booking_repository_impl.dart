import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/trip_booking_repository.dart';
import '../models/trip_model.dart';

class TripBookingRepositoryImpl implements TripBookingRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TripBookingRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<Either<Failure, List<TripModel>>> searchTrips({
    required String fromCity,
    required String toCity,
  }) async {
    try {
      // بنبحث عن رحلات السفر المتاحة فقط اللي الكباتن نشروها
      Query query = _firestore
          .collection('trips')
          .where('isDriverPost', isEqualTo: true)
          .where('status', isEqualTo: TripStatus.available)
          .where('fromCity', isEqualTo: fromCity)
          .where('toCity', isEqualTo: toCity);

      final snapshot = await query.get();
      List<TripModel> searchResults = [];

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        searchResults.add(TripModel.fromMap(data, doc.id));
      }

      // ترتيب زمني محلي للأحدث
      searchResults.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return Right(searchResults);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء البحث: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> bookTripSeat({
    required String tripId,
    required String driverId,
    required int requestedSeats,
  }) async {
    try {
      final passengerId = _auth.currentUser?.uid;
      final passengerName = _auth.currentUser?.displayName ?? 'عميل لَمَّة';

      if (passengerId == null) throw Exception("يجب تسجيل الدخول أولاً");

      final tripRef = _firestore.collection('trips').doc(tripId);
      final bookingRef = _firestore.collection('trip_bookings').doc();

      // Transaction عشان نمنع الـ Overbooking تماماً
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(tripRef);

        if (!snapshot.exists) {
          throw Exception("عذراً، هذه الرحلة لم تعد متاحة.");
        }

        final tripData = snapshot.data()!;
        
        // لأنك عامل availableSeats كـ String في الموديل بنهندلها هنا
        final int currentAvailableSeats = int.tryParse(tripData['availableSeats']?.toString() ?? '0') ?? 0;

        if (currentAvailableSeats < requestedSeats) {
          throw Exception("لا يوجد مقاعد كافية. المتاح $currentAvailableSeats فقط.");
        }

        // 1. خصم المقاعد وتحديث الرحلة (بنرجعها String عشان توافق الموديل بتاعك)
        final int newSeatsCount = currentAvailableSeats - requestedSeats;
        transaction.update(tripRef, {
          'availableSeats': newSeatsCount.toString(),
          // لو حابب تقفل الرحلة لو المقاعد خلصت
          if (newSeatsCount == 0) 'status': TripStatus.inProgress, 
        });

        // 2. إنشاء طلب في collection الـ bookings عشان يظهر للسائق
        transaction.set(bookingRef, {
          'tripId': tripId,
          'driverId': driverId,
          'passengerId': passengerId,
          'passengerName': passengerName,
          'requestedSeats': requestedSeats.toString(), // برضه String تحسباً
          'price': tripData['seatPrice'] ?? tripData['price'] ?? '0',
          'status': 'pending', // السائق هيشوف الطلب معلق ويقبله
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString().replaceAll('Exception:', '').trim()));
    }
  }
}