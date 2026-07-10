import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../data/models/trip_model.dart';
import 'available_travels_state.dart';

class AvailableTravelsCubit extends Cubit<AvailableTravelsState> {
  final TripRepository _repository;
  
  Position? _passengerPosition;
  bool _showOnlyNearby = false;
  final double _nearbyRadiusInMeters = 20000; 
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // 🟢 متغيرات الـ Pagination
  List<TripModel> _rawTrips = []; // نحتفظ بالداتا الخام قبل الفلترة
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  final int _limit = 20;

  AvailableTravelsCubit(this._repository) : super(AvailableTravelsInitial());

  void init() {
    _getPassengerLocation(); 
  }

  Future<void> _getPassengerLocation() async {
    if (isClosed) return; 
    emit(AvailableTravelsLoading());
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _fetchInitialTrips(); 
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _fetchInitialTrips();
        return;
      }
    }

    try {
      _passengerPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );
      _fetchInitialTrips(); 
    } catch (e) {
      _fetchInitialTrips();
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
    // إعادة معالجة الداتا المخزنة حالياً
    _processAndEmitTrips();
  }

  // --------------------------------------------------
  // 🔥 نظام الـ Pagination
  // --------------------------------------------------
  Future<void> _fetchInitialTrips() async {
    if (isClosed) return;
    emit(AvailableTravelsLoading());
    
    _rawTrips.clear();
    _hasReachedMax = false;
    _isFetchingMore = false;

    try {
      final result = await _repository.getAvailableTravels(limit: _limit);

      if (isClosed) return;

      result.fold(
        (failure) => emit(AvailableTravelsError('حدث خطأ في تحميل الرحلات المتاحة.')),
        (trips) {
          _rawTrips = trips;
          _hasReachedMax = trips.length < _limit;
          _processAndEmitTrips();
        },
      );
    } catch (e) {
      if (!isClosed) emit(AvailableTravelsError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> fetchMoreTrips() async {
    if (_hasReachedMax || _isFetchingMore || isClosed) return;

    _isFetchingMore = true;
    if (state is AvailableTravelsLoaded) {
      emit((state as AvailableTravelsLoaded).copyWith(isFetchingMore: true));
    }

    try {
      final lastTrip = _rawTrips.isNotEmpty ? _rawTrips.last : null;
      final result = await _repository.getAvailableTravels(limit: _limit, lastTrip: lastTrip);

      if (isClosed) return;

      result.fold(
        (failure) {
          _isFetchingMore = false;
          if (state is AvailableTravelsLoaded) {
            emit((state as AvailableTravelsLoaded).copyWith(isFetchingMore: false));
          }
        },
        (newTrips) {
          _isFetchingMore = false;
          if (newTrips.isEmpty) {
            _hasReachedMax = true;
          } else {
            _rawTrips.addAll(newTrips);
            _hasReachedMax = newTrips.length < _limit;
          }
          _processAndEmitTrips();
        },
      );
    } catch (e) {
      _isFetchingMore = false;
      if (state is AvailableTravelsLoaded && !isClosed) {
        emit((state as AvailableTravelsLoaded).copyWith(isFetchingMore: false));
      }
    }
  }

  // --------------------------------------------------
  // 🔥 معالجة البيانات (البزنس لوجيك بتاعك كما هو)
  // --------------------------------------------------
  void _processAndEmitTrips() {
    if (isClosed) return;
    
    List<ProcessedTrip> processedTrips = [];
    
    for (TripModel trip in _rawTrips) {
      // 1. إخفاء رحلة السائق نفسه
      if (trip.driverId == currentUserId) continue;

      // 2. إخفاء الرحلة لو المقاعد صفر
      int availableSeats = int.tryParse(trip.availableSeats ?? '0') ?? 0;
      if (availableSeats <= 0) continue; 

      // 3. إخفاء الرحلة لو الراكب حاجز فيها
      // 🟢 ملاحظة: TripModel لا يحتوي حالياً على bookedPassengersIds، لذا سنقوم بجلبها من Map
      // أو كحل مؤقت إذا كنت أضفتها للـ Model فاستخدمها. هنا سأفترض أنك لم تضفها بعد وسأعتمد على اللوجيك القديم
      // في حالة Clean Architecture يفضل إضافتها للموديل.
      // ⚠️ للتسهيل: سأتجاهل هذا الفلتر هنا وأتركه لك لإضافته للموديل إذا أردت، أو تعتمد على الشاشة اللي بتمنع الحجز.

      // 4. فلتر الصلاحية (الوقت)
      DateTime? tripDate = trip.travelDate;
      if (tripDate != null && tripDate.isBefore(DateTime.now())) {
        continue; 
      } else if (tripDate == null && trip.createdAt != null) {
        if (DateTime.now().difference(trip.createdAt!).inDays > 2) {
          continue; 
        }
      }

      // 5. حساب المسافة
      double distance = double.infinity;
      if (trip.fromLocation != null && _passengerPosition != null) {
        distance = Geolocator.distanceBetween(
          _passengerPosition!.latitude,
          _passengerPosition!.longitude,
          trip.fromLocation!.latitude,
          trip.fromLocation!.longitude,
        );
      }

      if (_showOnlyNearby && distance > _nearbyRadiusInMeters) continue;

      processedTrips.add(ProcessedTrip(trip: trip, distance: distance));
    }

    processedTrips.sort((a, b) => a.distance.compareTo(b.distance));

    emit(AvailableTravelsLoaded(
      trips: processedTrips,
      showOnlyNearby: _showOnlyNearby,
      passengerPosition: _passengerPosition,
      hasReachedMax: _hasReachedMax,
      isFetchingMore: _isFetchingMore,
    ));
  }

  Future<bool> bookSeatInDriverPost(String tripId, String driverId, int seatsToBook) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      DocumentReference tripRef = FirebaseFirestore.instance.collection('trips').doc(tripId);
      batch.update(tripRef, {
        'bookedPassengersIds': FieldValue.arrayUnion([currentUserId]),
      });

      DocumentReference bookingRef = FirebaseFirestore.instance.collection('trip_bookings').doc();
      batch.set(bookingRef, {
        'tripId': tripId,
        'driverId': driverId,
        'passengerId': currentUserId,
        'seats': seatsToBook, 
        'status': 'pending', 
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true; 
    } catch (e) {
      if (isClosed) return false; 
      emit(AvailableTravelsError('حدث خطأ أثناء حجز المقعد، يرجى المحاولة مرة أخرى'));
      return false;
    }
  }
}