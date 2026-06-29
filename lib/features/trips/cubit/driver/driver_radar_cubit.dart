import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamma_new/core/constants/firebase_constants.dart';

import '../../data/services/driver_radar_service.dart';
import 'driver_radar_state.dart';

class DriverRadarCubit extends Cubit<DriverRadarState> {
  final DriverRadarService _radarService;
  StreamSubscription? _radarSubscription;

  // 🟢 بنستقبل الـ Service في الـ Constructor
  DriverRadarCubit(this._radarService) : super(DriverRadarInitial());

  void startListeningToRadar() {
    emit(DriverRadarLoading());

    _radarSubscription?.cancel(); // إغلاق أي استماع قديم
    
    _radarSubscription = _radarService.getRadarTripsStream().listen((snapshot) {
      
      var trips = snapshot.docs.where((doc) {
        var data = doc.data() as Map<String, dynamic>;
        String status = data[FirebaseConstants.fieldStatus] ?? FirebaseConstants.statusPending;
        
        return status == 'available' || 
               status == FirebaseConstants.statusPending || 
               (status == FirebaseConstants.statusNegotiating && data['driverId'] == _radarService.currentUserId);
      }).toList();

      trips.sort((a, b) {
        var dataA = a.data() as Map<String, dynamic>;
        var dataB = b.data() as Map<String, dynamic>;
        Timestamp? timeA = dataA['createdAt'];
        Timestamp? timeB = dataB['createdAt'];
        
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA); 
      });

      emit(DriverRadarLoaded(trips));
      
    }, onError: (error) {
      emit(DriverRadarError(error.toString()));
    });
  }

  Future<void> acceptTrip(String docId, String agreedPrice) async {
    try {
      await _radarService.acceptTrip(docId, agreedPrice);
      // 🟢 بنبعت حالة نجاح عشان الواجهة تقفل الديالوج أو تنقل التابة
      emit(DriverRadarActionSuccess('تم قبول الرحلة بنجاح! 🚗'));
    } catch (e) {
      emit(DriverRadarActionError('حدث خطأ أثناء القبول: $e'));
    }
  }

  Future<void> negotiateTrip(String docId, String offer) async {
    try {
      await _radarService.negotiateTrip(docId, offer);
      emit(DriverRadarActionSuccess('تم إرسال عرض السعر للعميل! 🤝'));
    } catch (e) {
      emit(DriverRadarActionError('حدث خطأ أثناء التفاوض: $e'));
    }
  }

  @override
  Future<void> close() {
    _radarSubscription?.cancel();
    return super.close();
  }
}