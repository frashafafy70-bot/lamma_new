import 'dart:async';
import 'package:flutter/foundation.dart'; // تمت إضافة هذا السطر عشان الـ debugPrint
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'driver_location_state.dart';

class DriverLocationCubit extends Cubit<DriverLocationState> {
  DriverLocationCubit() : super(DriverLocationInitial());

  StreamSubscription<Position>? _positionStream;
  DateTime? _lastUpdateTime;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void startLocationTracking() {
    if (currentUserId.isEmpty) {
      emit(DriverLocationError('الكابتن غير مسجل الدخول.'));
      return;
    }

    // الفلترة الأولى (المسافة): عدم إرسال أي داتا من المستشعر إلا لو تحرك الكابتن 20 متر
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20, 
    );

    emit(DriverLocationTracking());

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _handleThrottledUpdate(position);
      },
      onError: (error) {
        emit(DriverLocationError('حدث خطأ في تتبع الموقع: $error'));
      }
    );
  }

  void _handleThrottledUpdate(Position position) {
    final now = DateTime.now();

    // الفلترة الثانية (الوقت): التأكد من مرور 10 ثوانٍ على الأقل قبل الرفع للفايربيز
    if (_lastUpdateTime == null || now.difference(_lastUpdateTime!).inSeconds >= 10) {
      _lastUpdateTime = now;
      _updateLocationInFirestore(position);
    }
  }

  Future<void> _updateLocationInFirestore(Position position) async {
    try {
      await FirebaseFirestore.instance
          .collection('drivers_locations')
          .doc(currentUserId)
          .set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('📍 تم تحديث الموقع بنجاح في فايربيز (بعد الفلترة)');
    } catch (e) {
      debugPrint('🔥 خطأ أثناء تحديث الموقع في Firestore: $e');
    }
  }

  @override
  Future<void> close() {
    _positionStream?.cancel();
    return super.close();
  }
}