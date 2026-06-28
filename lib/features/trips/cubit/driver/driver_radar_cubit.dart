import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🟢 استدعاء الثوابت لحماية الكود من الأخطاء الإملائية
import 'package:lamma_new/core/constants/firebase_constants.dart';
import 'driver_radar_state.dart';

class DriverRadarCubit extends Cubit<DriverRadarState> {
  DriverRadarCubit() : super(DriverRadarInitial());

  StreamSubscription? _radarSubscription;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void startListeningToRadar() {
    emit(DriverRadarLoading());

    _radarSubscription = FirebaseFirestore.instance
        .collection(FirebaseConstants.tripsCollection)
        .where('isDriverPost', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          
      var trips = snapshot.docs.where((doc) {
        var data = doc.data();
        String status = data[FirebaseConstants.fieldStatus] ?? FirebaseConstants.statusPending;
        
        return status == 'available' || 
               status == FirebaseConstants.statusPending || 
               (status == FirebaseConstants.statusNegotiating && data['driverId'] == currentUserId);
      }).toList();

      trips.sort((a, b) {
        var dataA = a.data();
        var dataB = b.data();
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
      await FirebaseFirestore.instance.collection(FirebaseConstants.tripsCollection).doc(docId).update({
        FirebaseConstants.fieldStatus: FirebaseConstants.statusAccepted, 
        'driverId': currentUserId, 
        'driverName': FirebaseAuth.instance.currentUser?.displayName ?? 'كابتن لمة',
        FirebaseConstants.fieldFinalPrice: agreedPrice
      });
    } catch (e) {
      emit(DriverRadarError('حدث خطأ أثناء القبول'));
    }
  }

  Future<void> negotiateTrip(String docId, String offer) async {
    try {
      await FirebaseFirestore.instance.collection(FirebaseConstants.tripsCollection).doc(docId).update({
        FirebaseConstants.fieldStatus: FirebaseConstants.statusNegotiating, 
        'driverId': currentUserId, 
        FirebaseConstants.fieldNegotiationPrice: offer,
        FirebaseConstants.fieldLastNegotiator: 'driver'
      });
    } catch (e) {
      emit(DriverRadarError('حدث خطأ أثناء التفاوض'));
    }
  }

  @override
  Future<void> close() {
    _radarSubscription?.cancel();
    return super.close();
  }
}