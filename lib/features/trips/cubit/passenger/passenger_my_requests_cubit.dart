import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audioplayers/audioplayers.dart'; 
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';
// 🟢 استيراد المعمارية النظيفة (Use Cases)
import '../../domain/usecases/get_passenger_active_trips_usecase.dart'; 
import '../../domain/usecases/send_notification_usecase.dart';
import '../../domain/usecases/manage_passenger_request_usecase.dart';

import '../../data/models/trip_model.dart';
import 'passenger_my_requests_state.dart';

class PassengerMyRequestsCubit extends Cubit<PassengerMyRequestsState> {
  final GetPassengerActiveTripsUseCase getPassengerActiveTripsUseCase;
  final SendNotificationUseCase sendNotificationUseCase;
  final ManagePassengerRequestUseCase managePassengerRequestUseCase;
  
  StreamSubscription<RemoteMessage>? _notificationSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<TripEntity> _trips = [];
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  static const int _limit = 15;

  PassengerMyRequestsCubit({
    required this.getPassengerActiveTripsUseCase,
    required this.sendNotificationUseCase,
    required this.managePassengerRequestUseCase,
  }) : super(PassengerMyRequestsInitial()) {
    _listenToPassengerNotifications();
  }

  // ==========================================
  // 🔥 1. نظام الإشعارات والأصوات
  // ==========================================
  void _listenToPassengerNotifications() {
    _notificationSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("🔔 [PassengerCubit] إشعار لايف وصل للعميل: ${message.notification?.title}");
      
      try {
        String type = message.data['type'] ?? '';
        
        if (type == 'driver_offer' || type == 'negotiating') {
          await _audioPlayer.play(AssetSource('audio/ping_pong.mp3'));
        } else if (type == 'trip_accepted' || type == 'booking_accepted') {
          await _audioPlayer.play(AssetSource('audio/edite.mp3'));
        } else if (type == 'trip_cancelled' || type == 'canceled') {
          await _audioPlayer.play(AssetSource('audio/cancell.mp3'));
        } else if (type == 'chat') {
          await _audioPlayer.play(AssetSource('audio/ping_pong.mp3'));
        } else {
          await _audioPlayer.play(AssetSource('audio/notification.mp3'));
        }
      } catch (e) {
        debugPrint("⚠️ مشكلة في تشغيل صوت العميل: $e");
      }
    });
  }

  Future<void> _notifyDriver(String tripId, String title, String body) async {
    final result = await sendNotificationUseCase(tripId: tripId, title: title, body: body);
    result.fold(
      (failure) => debugPrint("🔥 FCM Error in Passenger Cubit: $failure"),
      (_) => debugPrint("🔔 تم إرسال إشعار للسائق بنجاح"),
    );
  }

  // ==========================================
  // 🟢 2. اللوجيك النظيف (جلب الطلبات)
  // ==========================================
  void startListeningToMyRequests() => fetchInitialPassengerTrips();

  Future<void> fetchInitialPassengerTrips() async {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) {
      emit(PassengerMyRequestsError('لم يتم العثور على حساب المستخدم.'));
      return;
    }

    emit(PassengerMyRequestsLoading());
    _resetPagination();

    try {
      final result = await getPassengerActiveTripsUseCase(uid: currentUserId, limit: _limit);

      if (isClosed) return;

      result.fold(
        (failure) {
          debugPrint("🔥 فايربيز زعلان: ${failure.message}");
          emit(PassengerMyRequestsError(failure.message ?? 'حدث خطأ غير متوقع'));
        },
        (trips) => _handleNewTrips(trips),
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
      final result = await getPassengerActiveTripsUseCase(
        uid: currentUserId, 
        limit: _limit, 
        lastTrip: lastTrip
      );

      if (isClosed) return;

      result.fold(
        (failure) {
          _isFetchingMore = false;
          debugPrint("🔥 فايربيز زعلان في المزيد: ${failure.message}");
          emit(_buildLoadedState());
        },
        (newTrips) {
          _isFetchingMore = false;
          _handleNewTrips(newTrips, isPagination: true);
        },
      );
    } catch (e) {
      _isFetchingMore = false;
      if (!isClosed) emit(_buildLoadedState());
    }
  }

  // ==========================================
  // 🟠 3. الأكشنز والتفاعلات
  // ==========================================
  Future<void> deleteRequest(String docId) async {
    final result = await managePassengerRequestUseCase.deleteRequest(docId);
    result.fold(
      (failure) => debugPrint('❌ خطأ في حذف الطلب: $failure'),
      (_) => fetchInitialPassengerTrips(),
    );
  }

  Future<void> acceptOffer(String docId, String acceptedPrice) async {
    final result = await managePassengerRequestUseCase.acceptOffer(docId, acceptedPrice);
    result.fold(
      (failure) => debugPrint('❌ خطأ في قبول العرض: $failure'),
      (_) async {
        await _notifyDriver(docId, 'تم قبول الرحلة! ✅', 'العميل وافق على السعر، الرحلة جاهزة للبدء.');
        fetchInitialPassengerTrips();
      },
    );
  }

  Future<void> rejectTrip(String docId) async {
    final result = await managePassengerRequestUseCase.rejectTrip(docId);
    result.fold(
      (failure) => debugPrint('❌ خطأ في رفض الرحلة: $failure'),
      (_) async {
        await _notifyDriver(docId, 'تم إلغاء الطلب ❌', 'قام العميل بإلغاء الطلب أو رفض العرض.');
        fetchInitialPassengerTrips();
      },
    );
  }

  Future<void> negotiateTrip(String docId, String offer, String type) async {
    final result = await managePassengerRequestUseCase.negotiateTrip(docId, offer, type);
    result.fold(
      (failure) => debugPrint('❌ خطأ في التفاوض: $failure'),
      (_) async {
        await _notifyDriver(docId, 'عرض سعر جديد 👤', 'العميل يطلب تعديل السعر إلى $offer ج.م');
        fetchInitialPassengerTrips();
      },
    );
  }

  // ==========================================
  // 🛠️ دوال مساعدة (Helpers)
  // ==========================================
  void _resetPagination() {
    _trips.clear();
    _hasReachedMax = false;
    _isFetchingMore = false;
  }

  void _handleNewTrips(List<TripEntity> newTrips, {bool isPagination = false}) {
    if (newTrips.isEmpty && isPagination) {
      _hasReachedMax = true;
    } else {
      _trips.addAll(newTrips);
      _hasReachedMax = newTrips.length < _limit;
    }
    emit(_buildLoadedState());
  }

  PassengerMyRequestsLoaded _buildLoadedState() {
    return PassengerMyRequestsLoaded(
      requests: List.from(_trips),
      hasReachedMax: _hasReachedMax,
      isFetchingMore: _isFetchingMore,
    );
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