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
  Stream<int> getDriverActiveOrdersCountStream(String uid) {
    var bookingsStream = _firestore
        .collection('trip_bookings')
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'accepted', 'negotiating'])
        .snapshots();

    var tripsStream = _firestore
        .collection('trips')
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['available', 'accepted', 'negotiating', 'arrived', 'started'])
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
      // 🟢 شيلنا الـ orderBy اللي بتعمل مشكلة الفهرس
      Query query = _firestore
          .collection('trips')
          .where('driverId', isEqualTo: uid)
          .where('status', whereIn: ['available', 'accepted', 'negotiating', 'arrived', 'started']);
          // .limit(limit); شلناها مؤقتاً عشان نرتب كل الداتا عندنا صح

      final snapshot = await query.get();
      
      List<TripModel> trips = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TripModel.fromMap(data, doc.id); 
      }).toList();

      // 🟢 الترتيب بيتم محلياً عن طريق الدارت (من الأحدث للأقدم)
      trips.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      // 🟢 تطبيق الـ Pagination محلياً لو عايز
      // int start = 0;
      // if (lastTrip != null) {
      //   start = trips.indexWhere((t) => t.id == lastTrip.id) + 1;
      // }
      // trips = trips.skip(start).take(limit).toList();

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
      // 🟢 شيلنا الـ orderBy اللي بتعمل مشكلة الفهرس
      Query query = _firestore
          .collection('trips')
          .where('passengerId', isEqualTo: uid)
          .where('isDriverPost', isEqualTo: false);
          // .limit(limit);

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

      // 🟢 الترتيب بيتم محلياً عن طريق الدارت (من الأحدث للأقدم)
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
      // 🟢 شيلنا الـ orderBy اللي بتعمل مشكلة الفهرس
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

      // 🟢 الترتيب بيتم محلياً عن طريق الدارت (من الأحدث للأقدم)
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
      // 🟢 شيلنا الـ orderBy اللي بتعمل مشكلة الفهرس
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

      // 🟢 الترتيب بيتم محلياً عن طريق الدارت (من الأحدث للأقدم)
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
}