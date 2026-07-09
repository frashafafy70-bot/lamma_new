import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audioplayers/audioplayers.dart'; // 🟢 مكتبة الصوت
import 'package:lamma_new/features/trips/cubit/passenger/passenger_my_requests_state.dart';

class PassengerMyRequestsCubit extends Cubit<PassengerMyRequestsState> {
  StreamSubscription<RemoteMessage>? _notificationSubscription;
  StreamSubscription? _requestsSubscription;
  
  // 🟢 مشغل الصوت
  final AudioPlayer _audioPlayer = AudioPlayer();

  PassengerMyRequestsCubit() : super(PassengerMyRequestsInitial()) {
    _listenToPassengerNotifications();
  }

  void _listenToPassengerNotifications() {
    _notificationSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("🔔 [PassengerCubit] إشعار لايف وصل للعميل: ${message.notification?.title}");
      
      try {
        String type = message.data['type'] ?? '';
        
        // 🟢 التعديل هنا: شملنا حالات قبول الحجز والشات
        if (type == 'driver_offer' || type == 'negotiating') {
          // الكابتن بعت عرض
          await _audioPlayer.play(AssetSource('audio/ping_pong.mp3'));
        } 
        else if (type == 'trip_accepted' || type == 'booking_accepted') {
          // الكابتن وافق على الرحلة أو الحجز
          await _audioPlayer.play(AssetSource('audio/edite.mp3'));
        } 
        else if (type == 'trip_cancelled' || type == 'canceled') {
          // الكابتن ألغى
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
        debugPrint("مشكلة في تشغيل صوت العميل: $e");
      }
    });
  }

  Future<void> _notifyDriver(String tripId, String title, String body) async {
    try {
      var tripDoc = await FirebaseFirestore.instance.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) return;
      String driverId = tripDoc.data()?['driverId'] ?? '';
      
      if (driverId.isEmpty) return;

      var userDoc = await FirebaseFirestore.instance.collection('users').doc(driverId).get();
      String? fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        String serverKey = dotenv.env['FCM_SERVER_KEY'] ?? ''; 
        await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$serverKey',
          },
          body: jsonEncode({
            'to': fcmToken,
            'notification': {'title': title, 'body': body, 'sound': 'default'},
            'data': {'tripId': tripId, 'type': 'passenger_action', 'channel_id': 'lamma_final_sound'}
          }),
        );
        debugPrint("🔔 تم إرسال إشعار للسائق بنجاح");
      }
    } catch (e) {
      debugPrint("FCM Error in Passenger Cubit: $e");
    }
  }

  void startListeningToMyRequests() {
    if (!isClosed) emit(PassengerMyRequestsLoading());
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    _requestsSubscription = FirebaseFirestore.instance
        .collection('trips')
        .where('passengerId', isEqualTo: currentUserId)
        .where('isDriverPost', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          
      if (isClosed) return;

      List<QueryDocumentSnapshot> docs = snapshot.docs.where((doc) {
        final data = (doc.data() as Map<String, dynamic>?) ?? {}; 
        bool isDeleted = data['isDeletedForPassenger'] == true || data['isDeleted'] == true;
        String status = data['status'] ?? '';
        
        bool isFinished = status == 'canceled'; 
        
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

      if (!isClosed) emit(PassengerMyRequestsLoaded(docs));
      
    }, onError: (error) {
      if (!isClosed) emit(PassengerMyRequestsError('حدث خطأ في تحميل البيانات'));
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
      await _notifyDriver(docId, 'تم قبول الرحلة! ✅', 'العميل وافق على السعر، الرحلة جاهزة للبدء.');
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
      await _notifyDriver(docId, 'تم إلغاء الطلب ❌', 'قام العميل بإلغاء الطلب أو رفض العرض.');
    } catch (e) {
      debugPrint('خطأ في رفض الرحلة: $e');
    }
  }

  Future<void> negotiateTrip(String docId, String offer, String type) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(docId).update({
        'status': 'negotiating', 
        'negotiationPrice': offer, 
        'negotiationType': type,
        'lastNegotiator': 'passenger'
      });
      await _notifyDriver(docId, 'عرض سعر جديد 👤', 'العميل يطلب تعديل السعر إلى $offer ج.م');
    } catch (e) {
      debugPrint('خطأ في التفاوض: $e');
    }
  }

  void resetCubit() {
    _notificationSubscription?.cancel();
    _requestsSubscription?.cancel();
    emit(PassengerMyRequestsInitial());
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    _requestsSubscription?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}