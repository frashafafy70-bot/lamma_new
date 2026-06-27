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

  Future<bool> bookDriverPost(String tripId) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'status': 'accepted',
        'passengerId': currentUserId,
      });
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