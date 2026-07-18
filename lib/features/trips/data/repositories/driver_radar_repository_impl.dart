import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart'; 

import '../../../../core/errors/failures.dart'; 
import 'package:lamma_new/features/trips/data/models/trip_model.dart';
import '../../domain/repositories/driver_radar_repository.dart';
import '../../domain/entities/trip_entity.dart'; // 🟢 تم إضافة الـ Entity

class DriverRadarRepositoryImpl implements DriverRadarRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DriverRadarRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance; 

  String get _currentUserId => _auth.currentUser?.uid ?? '';
  String get _currentUserName => _auth.currentUser?.displayName ?? 'سائق لَمَّة';

  @override
  Stream<List<TripEntity>> getRadarTripsStream() {
    return _firestore
        .collection('trips')
        .where('isDriverPost', isEqualTo: false)
        .where('status', whereIn: ['pending', 'negotiating']) 
        .snapshots()
        .map((snapshot) {
      
      List<TripEntity> activeTrips = []; // 🟢 التعديل للـ Entity

      for (var doc in snapshot.docs) {
        var data = doc.data();
        
        if (data['isDeletedForDriver'] == true) continue;
        
        if (data['status'] == 'negotiating' && data['driverId'] == _currentUserId) continue;
        
        try {
          // 🟢 التحويل بيتم من Map لـ Model وبعدين بيتخزن كـ Entity في الليست
          activeTrips.add(TripModel.fromMap(data, doc.id));
        } catch (e) {
          if (kDebugMode) print('Error parsing trip ${doc.id}: $e');
        }
      }
      
      // 🟢 الترتيب بيتم محلياً للستريم عشان يجيب أحدث الطلبات الأول
      activeTrips.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        // افتراض إن createdAt من نوع DateTime أو Comparable
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return activeTrips;
    });
  }

  @override
  Future<Either<Failure, List<TripEntity>>> getPaginatedRadarTrips({
    required int limit,
    TripEntity? lastTrip, // 🟢 تم التعديل لتكون TripEntity
  }) async {
    try {
      // 🟢 شيلنا الـ orderBy والـ limit عشان نرتب الداتا عندنا ونتجنب خطأ الـ Index
      Query query = _firestore
          .collection('trips')
          .where('isDriverPost', isEqualTo: false)
          .where('status', whereIn: ['pending', 'negotiating']);

      final snapshot = await query.get();
      List<TripEntity> activeTrips = []; // 🟢 التعديل للـ Entity

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        
        if (data['isDeletedForDriver'] == true) continue;
        if (data['status'] == 'negotiating' && data['driverId'] == _currentUserId) continue;
        
        try {
          activeTrips.add(TripModel.fromMap(data, doc.id));
        } catch (e) {
          if (kDebugMode) print('Error parsing trip ${doc.id}: $e');
        }
      }

      // 🟢 الترتيب بيتم محلياً عن طريق الدارت (من الأحدث للأقدم)
      activeTrips.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return Right(activeTrips);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء جلب الطلبات: ${e.toString()}')); 
    }
  }

  @override
  Future<Either<Failure, void>> acceptTripSecurely(String tripId, String? negotiatedPrice) async {
    try {
      final tripRef = _firestore.collection('trips').doc(tripId);
      final userRef = _firestore.collection('users').doc(_currentUserId);

      DocumentSnapshot driverDoc = await userRef.get();
      String driverName = driverDoc.exists
          ? (driverDoc.data() as Map<String, dynamic>)['name'] ?? _currentUserName
          : _currentUserName;

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot tripSnapshot = await transaction.get(tripRef);
        if (!tripSnapshot.exists) throw Exception('الرحلة غير موجودة أو تم حذفها');

        var tripData = tripSnapshot.data() as Map<String, dynamic>;
        String status = tripData['status'] ?? '';
        
        if (status == 'accepted') throw Exception('تم قبول هذه الرحلة مسبقاً من سائق آخر');

        Map<String, dynamic> updateData = {
          'status': 'accepted',
          'driverId': _currentUserId,
          'driverName': driverName,
          'acceptedAt': FieldValue.serverTimestamp(),
        };

        if (negotiatedPrice != null) updateData['price'] = negotiatedPrice;
        transaction.update(tripRef, updateData);
      });
      return const Right(null); // 🟢 العملية نجحت
    } catch (e) {
      return Left(ServerFailure(message: e.toString())); // 🟢 إرجاع الخطأ للـ UI
    }
  }

  @override
  Future<Either<Failure, void>> negotiateTrip(String tripId, String offer) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'negotiating',
        'driverId': _currentUserId,
        'negotiationPrice': offer,
        'lastNegotiator': 'driver'
      });
      return const Right(null); // 🟢 العملية نجحت
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء إرسال العرض: $e')); // 🟢 إرجاع الخطأ
    }
  }
}