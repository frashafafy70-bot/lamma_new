import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'family_tracking_state.dart';

class FamilyTrackingCubit extends Cubit<FamilyTrackingState> {
  FamilyTrackingCubit() : super(FamilyTrackingInitial());
  
  StreamSubscription? _tripSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void startTracking(String childUid) {
    emit(FamilyTrackingLoading());
    _tripSubscription?.cancel();

    // الاستعلام عن الرحلات النشطة الخاصة بالابن
    _tripSubscription = _firestore
        .collection('trips')
        .where('passengerId', isEqualTo: childUid)
        .where('status', whereIn: ['accepted', 'arrived', 'in_progress'])
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        // إذا كان هناك رحلة نشطة، نأخذ أول رحلة
        final tripData = snapshot.docs.first.data();
        
        final double? lat = tripData['driverLat'];
        final double? lng = tripData['driverLng'];
        
        emit(FamilyTrackingActive(
          tripData: tripData,
          driverLat: lat,
          driverLng: lng,
        ));
      } else {
        // لا توجد رحلة نشطة حالياً
        emit(FamilyTrackingNoActiveTrip());
      }
    }, onError: (error) {
      emit(FamilyTrackingError('حدث خطأ أثناء جلب الرحلة: $error'));
    });
  }

  @override
  Future<void> close() {
    _tripSubscription?.cancel();
    return super.close();
  }
}