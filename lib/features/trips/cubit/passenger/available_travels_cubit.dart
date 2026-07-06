import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'available_travels_state.dart';

class AvailableTravelsCubit extends Cubit<AvailableTravelsState> {
  AvailableTravelsCubit() : super(AvailableTravelsInitial());

  StreamSubscription<QuerySnapshot>? _tripsSubscription;
  Position? _passengerPosition;
  bool _showOnlyNearby = false;
  final double _nearbyRadiusInMeters = 20000; 
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void init() {
    _getPassengerLocation();
    _listenToTrips();
  }

  Future<void> _getPassengerLocation() async {
    emit(AvailableTravelsLoading());
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _listenToTrips(); 
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _listenToTrips();
        return;
      }
    }

    try {
      _passengerPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );
      _listenToTrips(); 
    } catch (e) {
      _listenToTrips();
    }
  }

  void toggleNearby(bool val) {
    if (_passengerPosition == null && val) {
      emit(AvailableTravelsError('يرجى تفعيل الموقع (GPS) لاستخدام هذه الميزة'));
      _getPassengerLocation();
      return;
    }
    _showOnlyNearby = val;
    if (state is AvailableTravelsLoaded) {
      _processAndEmitTrips((state as AvailableTravelsLoaded).trips, forceReprocess: true);
    }
  }

  void _listenToTrips() {
    _tripsSubscription?.cancel();
    _tripsSubscription = FirebaseFirestore.instance
        .collection('trips')
        .where('isDriverPost', isEqualTo: true)
        .where('status', isEqualTo: 'available')
        .snapshots()
        .listen((snapshot) {
      _processAndEmitTrips(snapshot.docs);
    });
  }

  void _processAndEmitTrips(dynamic rawDocs, {bool forceReprocess = false}) {
    List<Map<String, dynamic>> processedTrips = [];
    
    Iterable docs = rawDocs is List<QueryDocumentSnapshot> 
        ? rawDocs 
        : rawDocs as List<Map<String, dynamic>>;

    for (var doc in docs) {
      var data = doc is QueryDocumentSnapshot ? doc.data() as Map<String, dynamic> : doc['data'] as Map<String, dynamic>;
      String docId = doc is QueryDocumentSnapshot ? doc.id : doc['docId'];
      
      if (data['departureTime'] != null && data['departureTime'] is Timestamp) {
        DateTime tripDate = (data['departureTime'] as Timestamp).toDate();
        if (tripDate.isBefore(DateTime.now())) {
          continue; 
        }
      } else if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
        DateTime createdDate = (data['createdAt'] as Timestamp).toDate();
        if (DateTime.now().difference(createdDate).inDays > 2) {
          continue; 
        }
      }

      double distance = double.infinity;
      bool hasLocation = data['fromLocation'] != null;

      if (hasLocation && _passengerPosition != null) {
        GeoPoint geo = data['fromLocation'];
        distance = Geolocator.distanceBetween(
          _passengerPosition!.latitude,
          _passengerPosition!.longitude,
          geo.latitude,
          geo.longitude,
        );
      }

      if (_showOnlyNearby && distance > _nearbyRadiusInMeters) continue;

      processedTrips.add({
        'docId': docId,
        'data': data,
        'distance': distance,
      });
    }

    processedTrips.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    emit(AvailableTravelsLoaded(
      trips: processedTrips,
      showOnlyNearby: _showOnlyNearby,
      passengerPosition: _passengerPosition,
    ));
  }

  // 🟢 دالة الحجز المحدثة (تعمل Batch Write لغلق الرحلة وإنشاء الحجز معاً)
  Future<bool> bookDriverPost(String tripId, String driverId) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. تحديث الرحلة الأساسية عشان تختفي من المتاح وتتقفل
      DocumentReference tripRef = FirebaseFirestore.instance.collection('trips').doc(tripId);
      batch.update(tripRef, {
        'status': 'accepted',
        'passengerId': currentUserId,
      });

      // 2. تسجيل الحجز في جدول الحجوزات عشان يظهر في "متابعة طلباتي"
      DocumentReference bookingRef = FirebaseFirestore.instance.collection('trip_bookings').doc();
      batch.set(bookingRef, {
        'tripId': tripId,
        'driverId': driverId,
        'passengerId': currentUserId,
        'seats': 1, 
        'status': 'accepted', 
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true; 
    } catch (e) {
      emit(AvailableTravelsError('حدث خطأ أثناء الحجز، يرجى المحاولة مرة أخرى'));
      return false;
    }
  }

  @override
  Future<void> close() {
    _tripsSubscription?.cancel();
    return super.close();
  }
}