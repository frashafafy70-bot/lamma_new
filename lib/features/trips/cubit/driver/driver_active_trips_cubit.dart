import 'dart:async';
import 'package:flutter/foundation.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:audioplayers/audioplayers.dart'; // 🟢 مكتبة الصوت
import 'driver_active_trips_state.dart';

class DriverActiveTripsCubit extends Cubit<DriverActiveTripsState> {
  StreamSubscription<RemoteMessage>? _notificationSubscription;
  StreamSubscription? _tripsSubscription;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  // 🟢 مشغل الصوت
  final AudioPlayer _audioPlayer = AudioPlayer();

  DriverActiveTripsCubit() : super(DriverActiveTripsInitial()) {
    _listenToForegroundNotifications(); 
  }

  void _listenToForegroundNotifications() {
    _notificationSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("🔔 [ActiveTripsCubit] إشعار لايف وصل للكابتن: ${message.notification?.title}");
      
      try {
        String type = message.data['type'] ?? '';
        
        // 🟢 التعديل هنا: شملنا كل الحالات اللي جاية من الباك اند
        if (type == 'passenger_offer' || type == 'negotiating' || type == 'passenger_action') {
          // العميل بعت سعر جديد
          await _audioPlayer.play(AssetSource('audio/ping_pong.mp3'));
        } 
        else if (type == 'new_request' || type == 'trip_accepted' || type == 'new_booking') {
          // طلب جديد أو حجز مقعد جديد أو العميل وافق
          await _audioPlayer.play(AssetSource('audio/edite.mp3'));
        } 
        else if (type == 'trip_cancelled' || type == 'canceled') {
          // العميل ألغى
          await _audioPlayer.play(AssetSource('audio/cancell.mp3'));
        } 
        else if (type == 'chat') {
          // رسالة شات جديدة
          await _audioPlayer.play(AssetSource('audio/ping_pong.mp3'));
        }
        else {
          // إشعار عام
          await _audioPlayer.play(AssetSource('audio/notification.mp3'));
        }
      } catch (e) {
        debugPrint("مشكلة في تشغيل الصوت للكابتن: $e");
      }
    });
  }

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
          
      if (isClosed) return; 

      var validTrips = snapshot.docs.where((doc) {
        var data = doc.data(); 
        bool isNotDeleted = data['isDeletedForDriver'] != true;
        
        bool isActiveStatus = data['status'] == 'available' || 
                              data['status'] == 'negotiating' || 
                              data['status'] == 'accepted' || 
                              data['status'] == 'arrived' ||
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
      if (isClosed) return;
      emit(DriverActiveTripsError('حدث خطأ في تحميل الرحلات النشطة.'));
    });
  }

  Future<bool> checkHasActiveTrip() async {
    if (currentUserId.isEmpty) return false;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('driverId', isEqualTo: currentUserId)
          .get();

      if (isClosed) return false; 

      for (var doc in snapshot.docs) {
        final data = doc.data();
        bool isNotDeleted = data['isDeletedForDriver'] != true;
        
        bool isActiveStatus = data['status'] == 'available' || 
                              data['status'] == 'negotiating' || 
                              data['status'] == 'accepted' || 
                              data['status'] == 'arrived' ||
                              data['status'] == 'in_progress';

        if (isNotDeleted && isActiveStatus) {
          return true; 
        }
      }
      return false; 
    } catch (e) {
      return false; 
    }
  }

  Future<void> activateDriverTripFunction(String tripId) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'status': 'in_progress',
        'driverActiveTripEnabled': true, 
        'startedAt': FieldValue.serverTimestamp(),
      });
      
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'isBusy': true,
      });
    } catch (e) {
      if (isClosed) return; 
      emit(DriverActiveTripsError('حدث خطأ أثناء تفعيل وظيفة الرحلة النشطة.'));
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel(); 
    _tripsSubscription?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}