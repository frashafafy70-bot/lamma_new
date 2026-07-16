import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/trip_booking_repository.dart';
import '../models/trip_model.dart';
// 🟢 الاستيراد السحري اللي بيعرف الملف على TripStatus
import '../../domain/entities/trip_entity.dart';

class TripBookingRepositoryImpl implements TripBookingRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SharedPreferences _prefs; 

  TripBookingRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required SharedPreferences prefs, 
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _prefs = prefs;

  @override
  Future<Either<Failure, List<TripModel>>> searchTrips({
    required String fromCity,
    required String toCity,
  }) async {
    final String cacheKey = 'cached_trips_${fromCity}_$toCity'; 

    try {
      Query query = _firestore
          .collection('trips')
          .where('isDriverPost', isEqualTo: true)
          .where('status', isEqualTo: TripStatus.available)
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

      await _prefs.setString(cacheKey, json.encode(cacheData));

      return Right(searchResults);
      
    } on FirebaseException catch (e) {
      if (e.code == 'network-request-failed') {
        return _getCachedTrips(cacheKey); 
      }
      return Left(ServerFailure(message: 'خطأ في الاتصال بالخادم: ${e.message}'));
    } on SocketException catch (_) {
      return _getCachedTrips(cacheKey);
    } catch (e) {
      return _getCachedTrips(cacheKey, fallbackError: 'حدث خطأ غير متوقع. جرب مرة أخرى.');
    }
  }

  Either<Failure, List<TripModel>> _getCachedTrips(String cacheKey, {String? fallbackError}) {
    try {
      final cachedString = _prefs.getString(cacheKey);
      if (cachedString != null) {
        final List<dynamic> decodedData = json.decode(cachedString);
        List<TripModel> cachedTrips = decodedData.map((data) {
          final mapData = data as Map<String, dynamic>;
          final id = mapData['id'] as String;
          return TripModel.fromMap(mapData, id);
        }).toList();
        
        return Right(cachedTrips);
      } else {
        return Left(ServerFailure(message: fallbackError ?? 'لا يوجد اتصال بالإنترنت ولا توجد رحلات محفوظة مسبقاً لهذا المسار.'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'فشل في استرجاع البيانات المحلية. تحقق من اتصالك.'));
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

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(tripRef);

        if (!snapshot.exists) {
          throw Exception("عذراً، هذه الرحلة لم تعد متاحة.");
        }

        final tripData = snapshot.data()!;
        
        final int currentAvailableSeats = int.tryParse(tripData['availableSeats']?.toString() ?? '0') ?? 0;

        if (currentAvailableSeats < requestedSeats) {
          throw Exception("لا يوجد مقاعد كافية. المتاح $currentAvailableSeats فقط.");
        }

        final int newSeatsCount = currentAvailableSeats - requestedSeats;
        transaction.update(tripRef, {
          'availableSeats': newSeatsCount.toString(),
          if (newSeatsCount == 0) 'status': TripStatus.inProgress, 
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
      if (e.code == 'network-request-failed') {
        return Left(ServerFailure(message: 'يبدو أنك غير متصل بالإنترنت. لا يمكن إتمام الحجز الآن.'));
      }
      return Left(ServerFailure(message: 'فشل في الحجز. حاول مرة أخرى.'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString().replaceAll('Exception: ', '').trim()));
    }
  }
}