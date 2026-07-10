import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audioplayers/audioplayers.dart'; 

import '../../domain/usecases/get_passenger_active_trips_usecase.dart'; // 🟢 تأكد من المسار
import '../../data/models/trip_model.dart';
import 'passenger_my_requests_state.dart';

class PassengerMyRequestsCubit extends Cubit<PassengerMyRequestsState> {
  final GetPassengerActiveTripsUseCase _getPassengerActiveTripsUseCase;
  
  StreamSubscription<RemoteMessage>? _notificationSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 🟢 متغيرات التحكم في الـ Pagination
  List<TripModel> _trips = [];
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  final int _limit = 15;

  PassengerMyRequestsCubit(this._getPassengerActiveTripsUseCase) : super(PassengerMyRequestsInitial()) {
    _listenToPassengerNotifications();
  }

  // --------------------------------------------------
  // 🔥 1. نظام الإشعارات والأصوات (كما هو)
  // --------------------------------------------------
  void _listenToPassengerNotifications() {
    _notificationSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("🔔 [PassengerCubit] إشعار لايف وصل للعميل: ${message.notification?.title}");
      
      try {
        String type = message.data['type'] ?? '';
        
        if (type == 'driver_offer' || type == 'negotiating') {
          await _audioPlayer.play(AssetSource('audio/ping_pong.mp3'));
        } 
        else if (type == 'trip_accepted' || type == 'booking_accepted') {
          await _audioPlayer.play(AssetSource('audio/edite.mp3'));
        } 
        else if (type == 'trip_cancelled' || type == 'canceled') {
          await _audioPlayer.play(AssetSource('audio/cancell.mp3'));
        } 
        else if (type == 'chat') {
          await _audioPlayer.play(AssetSource('audio/ping_pong.mp3'));
        }
        else {
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

  // --------------------------------------------------
  // 🔥 2. نظام الـ Pagination لجلب الطلبات
  // --------------------------------------------------
  void startListeningToMyRequests() {
    fetchInitialPassengerTrips();
  }

  Future<void> fetchInitialPassengerTrips() async {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) {
      emit(PassengerMyRequestsError('لم يتم العثور على حساب المستخدم.'));
      return;
    }

    emit(PassengerMyRequestsLoading());
    
    _trips.clear();
    _hasReachedMax = false;
    _isFetchingMore = false;

    try {
      final result = await _getPassengerActiveTripsUseCase(uid: currentUserId, limit: _limit);

      if (isClosed) return;

      result.fold(
        (failure) => emit(PassengerMyRequestsError('حدث خطأ في تحميل البيانات')),
        (trips) {
          _trips = trips;
          _hasReachedMax = trips.length < _limit;
          
          emit(PassengerMyRequestsLoaded(
            requests: List.from(_trips),
            hasReachedMax: _hasReachedMax,
            isFetchingMore: false,
          ));
        },
      );
    } catch (e) {
      if (!isClosed) emit(PassengerMyRequestsError('حدث خطأ غير متوقع: $e'));
    }
  }

  Future<void> fetchMorePassengerTrips() async {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (_hasReachedMax || _isFetchingMore || currentUserId.isEmpty) return;

    _isFetchingMore = true;
    if (state is PassengerMyRequestsLoaded) {
      emit((state as PassengerMyRequestsLoaded).copyWith(isFetchingMore: true));
    }

    try {
      final lastTrip = _trips.isNotEmpty ? _trips.last : null;
      final result = await _getPassengerActiveTripsUseCase(
        uid: currentUserId, 
        limit: _limit, 
        lastTrip: lastTrip
      );

      if (isClosed) return;

      result.fold(
        (failure) {
          _isFetchingMore = false;
          if (state is PassengerMyRequestsLoaded) {
            emit((state as PassengerMyRequestsLoaded).copyWith(isFetchingMore: false));
          }
        },
        (newTrips) {
          _isFetchingMore = false;
          if (newTrips.isEmpty) {
            _hasReachedMax = true;
          } else {
            _trips.addAll(newTrips);
            _hasReachedMax = newTrips.length < _limit;
          }
          
          emit(PassengerMyRequestsLoaded(
            requests: List.from(_trips),
            hasReachedMax: _hasReachedMax,
            isFetchingMore: false,
          ));
        },
      );
    } catch (e) {
      _isFetchingMore = false;
      if (state is PassengerMyRequestsLoaded && !isClosed) {
        emit((state as PassengerMyRequestsLoaded).copyWith(isFetchingMore: false));
      }
    }
  }

  // --------------------------------------------------
  // 🔥 3. الأكشنز والتفاعلات (كما هي تماماً)
  // --------------------------------------------------
  Future<void> deleteRequest(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(docId).update({
        'isDeletedForPassenger': true,
      });
      fetchInitialPassengerTrips(); // تحديث بعد الحذف
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
      fetchInitialPassengerTrips(); // تحديث القائمة
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
      fetchInitialPassengerTrips(); // تحديث القائمة
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
      fetchInitialPassengerTrips(); // تحديث القائمة
    } catch (e) {
      debugPrint('خطأ في التفاوض: $e');
    }
  }

  void resetCubit() {
    _notificationSubscription?.cancel();
    emit(PassengerMyRequestsInitial());
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}