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
    // 🟢 الحل الجذري 1: استدعاء دالة واحدة فقط تظبط الموقع وبعدين تفتح الـ Stream
    _getPassengerLocation(); 
  }

  Future<void> _getPassengerLocation() async {
    if (isClosed) return; // 🟢 تأمين
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
      if (isClosed) return;
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
    if (isClosed) return;
    
    List<Map<String, dynamic>> processedTrips = [];
    String activeUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    Iterable docs = rawDocs is List<QueryDocumentSnapshot> 
        ? rawDocs 
        : rawDocs as List<Map<String, dynamic>>;

    for (var doc in docs) {
      var data = doc is QueryDocumentSnapshot ? doc.data() as Map<String, dynamic> : doc['data'] as Map<String, dynamic>;
      String docId = doc is QueryDocumentSnapshot ? doc.id : doc['docId'];
      
      // 🟢 1. إخفاء الرحلة لو المقاعد المتاحة بقت صفر 
      int availableSeats = 0;
      if (data['availableSeats'] != null) {
        availableSeats = int.tryParse(data['availableSeats'].toString()) ?? 0;
      }
      if (availableSeats <= 0) continue; 

      // 🟢 2. إخفاء الرحلة لو الراكب الحالي حاجز فيها
      List<dynamic> bookedPassengers = data['bookedPassengersIds'] ?? [];
      if (bookedPassengers.contains(activeUserId)) {
        continue; 
      }

      // 🟢 3. الحل الجذري 2: الاعتماد على travelDate زي ما الكابتن بيحفظها بالضبط لمنع تعليق الرحلات
      DateTime? tripDate;
      if (data['travelDate'] != null && data['travelDate'] is Timestamp) {
        tripDate = (data['travelDate'] as Timestamp).toDate();
      } else if (data['departureTime'] != null && data['departureTime'] is Timestamp) {
        tripDate = (data['departureTime'] as Timestamp).toDate(); // Fallback للبيانات القديمة
      }

      // لو تاريخ الرحلة أقدم من وقتنا الحالي، اخفيها فوراً!
      if (tripDate != null && tripDate.isBefore(DateTime.now())) {
        continue; 
      } 
      // لو ملهاش تاريخ خالص بس عدى على إنشائها يومين، اخفيها
      else if (tripDate == null && data['createdAt'] != null && data['createdAt'] is Timestamp) {
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

  Future<bool> bookSeatInDriverPost(String tripId, String driverId, int seatsToBook) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      String activeUid = FirebaseAuth.instance.currentUser?.uid ?? '';

      DocumentReference tripRef = FirebaseFirestore.instance.collection('trips').doc(tripId);
      batch.update(tripRef, {
        'bookedPassengersIds': FieldValue.arrayUnion([activeUid]),
      });

      DocumentReference bookingRef = FirebaseFirestore.instance.collection('trip_bookings').doc();
      batch.set(bookingRef, {
        'tripId': tripId,
        'driverId': driverId,
        'passengerId': activeUid,
        'seats': seatsToBook, 
        'status': 'pending', 
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true; 
    } catch (e) {
      if (isClosed) return false; // 🟢 تأمين
      emit(AvailableTravelsError('حدث خطأ أثناء حجز المقعد، يرجى المحاولة مرة أخرى'));
      return false;
    }
  }

  @override
  Future<void> close() {
    _tripsSubscription?.cancel();
    return super.close();
  }
}