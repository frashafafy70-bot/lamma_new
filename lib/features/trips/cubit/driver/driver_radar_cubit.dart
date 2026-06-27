import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'driver_radar_state.dart';

class DriverRadarCubit extends Cubit<DriverRadarState> {
  DriverRadarCubit() : super(DriverRadarInitial());

  StreamSubscription? _radarSubscription;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // دالة الاستماع للطلبات (Real-time)
  void startListeningToRadar() {
    emit(DriverRadarLoading());

    _radarSubscription = FirebaseFirestore.instance
        .collection('trips')
        .where('isDriverPost', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          
      var trips = snapshot.docs.where((doc) {
        var data = doc.data();
        String status = data['status'] ?? 'pending';
        // الفلترة بتجيب الطلبات المتاحة أو اللي الكابتن بيتفاوض عليها
        return status == 'available' || status == 'pending' || (status == 'negotiating' && data['driverId'] == currentUserId);
      }).toList();

      // ترتيب الطلبات من الأحدث للأقدم
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

  // دالة قبول الرحلة
  Future<void> acceptTrip(String docId, String agreedPrice) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(docId).update({
        'status': 'accepted', 
        'driverId': currentUserId, 
        'driverName': FirebaseAuth.instance.currentUser?.displayName ?? 'كابتن لمة',
        'finalPrice': agreedPrice
      });
    } catch (e) {
      emit(DriverRadarError('حدث خطأ أثناء القبول'));
    }
  }

  // دالة إرسال عرض التفاوض
  Future<void> negotiateTrip(String docId, String offer) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(docId).update({
        'status': 'negotiating', 
        'driverId': currentUserId, 
        'negotiationPrice': offer,
        'lastNegotiator': 'driver'
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