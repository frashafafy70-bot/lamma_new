import 'dart:async';
import 'package:flutter/foundation.dart'; // 🟢 لإضافة debugPrint
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🟢 استدعاء الإشعارات
import 'driver_active_trips_state.dart';

class DriverActiveTripsCubit extends Cubit<DriverActiveTripsState> {
  // 🟢 اشتراك الإشعارات
  StreamSubscription<RemoteMessage>? _notificationSubscription;
  StreamSubscription? _tripsSubscription;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  DriverActiveTripsCubit() : super(DriverActiveTripsInitial()) {
    _listenToForegroundNotifications(); // 🟢 تفعيل مستمع الإشعارات فوراً
  }

  // =======================================================
  // 🟢 اللوجيك الجديد: الاستماع للإشعارات الخاصة بالرحلات النشطة
  // =======================================================
  void _listenToForegroundNotifications() {
    _notificationSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("🔔 [ActiveTripsCubit] إشعار لايف وصل: ${message.notification?.title}");
      
      // إذا كان الإشعار يخص رسالة جديدة أو تحديث في رحلة السائق الحالية
      if (message.data['type'] == 'chat' || message.data['type'] == 'active_trip') {
        // بما إن Firestore بيحدث نفسه، نقدر نستخدم دي لإصدار State فرعي
        // مثلاً لو حابين نعرض SnackBar سريع للسائق أو نشغل اهتزاز
        // emit(DriverActiveTripsNotificationReceived(message.notification?.title));
      }
    });
  }
  // =======================================================

  void startListeningToActiveTrips() {
    if (currentUserId.isEmpty) {
      emit(DriverActiveTripsError('لم يتم العثور على حساب السائق، يرجى تسجيل الدخول مجدداً.'));
      return;
    }

    if (state is! DriverActiveTripsLoaded) {
      emit(DriverActiveTripsLoading());
    }

    _tripsSubscription?.cancel();

    _tripsSubscription = FirebaseFirestore.instance
        .collection('trips')
        .where('driverId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
          
      var validTrips = snapshot.docs.where((doc) {
        var data = doc.data(); 
        bool isNotDeleted = data['isDeletedForDriver'] != true;
        
        // فلترة الرحلات النشطة فقط
        bool isActiveStatus = data['status'] == 'negotiating' || 
                              data['status'] == 'accepted' || 
                              data['status'] == 'in_progress';
                             
        return isNotDeleted && isActiveStatus;
      }).toList();

      validTrips.sort((a, b) {
        var dataA = a.data();
        var dataB = b.data();
        Timestamp? timeA = dataA['createdAt'];
        Timestamp? timeB = dataB['createdAt'];
        
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA); 
      });

      emit(DriverActiveTripsLoaded(validTrips));
      
    }, onError: (error) {
      emit(DriverActiveTripsError('حدث خطأ في تحميل الرحلات النشطة.'));
    });
  }

  // 🟢 الوظيفة الإضافية للسائق: تفعيل الرحلة النشطة
  Future<void> activateDriverTripFunction(String tripId) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'status': 'in_progress',
        'driverActiveTripEnabled': true, // علامة تأكيد تفعيل الوظيفة الإضافية
        'startedAt': FieldValue.serverTimestamp(),
      });
      
      // تحديث حالة السائق لـ "مشغول" عشان الرادار يوقف استقبال طلبات جديدة
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'isBusy': true,
      });
    } catch (e) {
      emit(DriverActiveTripsError('حدث خطأ أثناء تفعيل وظيفة الرحلة النشطة.'));
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel(); // 🟢 تنظيف ذاكرة مستمع الإشعارات
    _tripsSubscription?.cancel();
    return super.close();
  }
}