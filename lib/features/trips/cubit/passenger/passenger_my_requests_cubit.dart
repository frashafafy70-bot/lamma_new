import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🟢 تم الإضافة
import 'package:lamma_new/features/trips/cubit/passenger/passenger_my_requests_state.dart';

class PassengerMyRequestsCubit extends Cubit<PassengerMyRequestsState> {
  // 🟢 اشتراك الإشعارات للعميل
  StreamSubscription<RemoteMessage>? _notificationSubscription;
  StreamSubscription? _requestsSubscription;

  PassengerMyRequestsCubit() : super(PassengerMyRequestsInitial()) {
    _listenToPassengerNotifications(); // 🟢 تشغيل المستمع فوراً
  }

  // =======================================================
  // 🟢 اللوجيك الجديد: الاستماع اللحظي لتحديثات الكباتن (عروض/قبول)
  // =======================================================
  void _listenToPassengerNotifications() {
    _notificationSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'driver_offer' || message.data['type'] == 'trip_accepted' || message.data['channel_id'] == 'lamma_final_sound') {
        debugPrint("🔔 [PassengerCubit] تحديث لايف لطلب العميل: ${message.notification?.title}");
        // الواجهة بتتحدث من الـ snapshots بالفعل، بس المستمع ده ممكن يفيد لو حابب تظهر SnackBar
      }
    });
  }
  // =======================================================

  void startListeningToMyRequests() {
    emit(PassengerMyRequestsLoading());

    // نقلنا الـ ID هنا عشان يجيب الـ UID الطازة بتاع العميل الحالي كل مرة الدالة تشتغل
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    _requestsSubscription = FirebaseFirestore.instance
        .collection('trips')
        .where('passengerId', isEqualTo: currentUserId) // 🔒 الفلترة المظبوطة
        .where('isDriverPost', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          
      List<QueryDocumentSnapshot> docs = snapshot.docs.where((doc) {
        final data = (doc.data() as Map<String, dynamic>?) ?? {}; 
        bool isDeleted = data['isDeletedForPassenger'] == true || data['isDeleted'] == true;
        String status = data['status'] ?? '';
        bool isFinished = status == 'canceled' || status == 'completed';
        return !isDeleted && !isFinished;
      }).toList();

      docs.sort((a, b) {
        final dataA = (a.data() as Map<String, dynamic>?) ?? {};
        final dataB = (b.data() as Map<String, dynamic>?) ?? {};
        Timestamp? timeA = dataA['createdAt'];
        Timestamp? timeB = dataB['createdAt'];
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA); 
      });

      emit(PassengerMyRequestsLoaded(docs));
      
    }, onError: (error) {
      emit(PassengerMyRequestsError('حدث خطأ في تحميل البيانات'));
    });
  }

  Future<void> deleteRequest(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(docId).update({
        'isDeletedForPassenger': true,
      });
    } catch (e) {
      debugPrint('خطأ في حذف الطلب: $e');
      rethrow;
    }
  }

  Future<void> acceptOffer(String docId, String acceptedPrice) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(docId).update({
        'status': 'accepted', 
        'finalPrice': acceptedPrice
      });
    } catch (e) {
      debugPrint('خطأ في قبول العرض: $e');
    }
  }

  Future<void> rejectTrip(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(docId).update({
        'status': 'canceled', 
        'canceledBy': 'passenger'
      });
    } catch (e) {
      debugPrint('خطأ في رفض الرحلة: $e');
    }
  }

  Future<void> negotiateTrip(String docId, String offer) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(docId).update({
        'status': 'negotiating', 
        'negotiationPrice': offer, 
        'lastNegotiator': 'passenger'
      });
    } catch (e) {
      debugPrint('خطأ في التفاوض: $e');
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel(); // 🟢 تنظيف المستمع
    _requestsSubscription?.cancel();
    return super.close();
  }
}