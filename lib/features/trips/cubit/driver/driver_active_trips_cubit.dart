import 'dart:async';
import 'package:flutter/foundation.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:audioplayers/audioplayers.dart'; 

import '../../domain/usecases/get_driver_active_trips_usecase.dart'; 
import '../../data/models/trip_model.dart';
import 'driver_active_trips_state.dart';

class DriverActiveTripsCubit extends Cubit<DriverActiveTripsState> {
  final GetDriverActiveTripsUseCase _getDriverActiveTripsUseCase;
  
  StreamSubscription<RemoteMessage>? _notificationSubscription;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 🟢 متغيرات التحكم في الـ Pagination
  List<TripModel> _trips = [];
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  final int _limit = 15;

  DriverActiveTripsCubit(this._getDriverActiveTripsUseCase) : super(DriverActiveTripsInitial()) {
    _listenToForegroundNotifications(); 
  }

  void _listenToForegroundNotifications() {
    _notificationSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("🔔 [ActiveTripsCubit] إشعار لايف وصل للكابتن: ${message.notification?.title}");
      
      try {
        String type = message.data['type'] ?? '';
        
        if (type == 'passenger_offer' || type == 'negotiating' || type == 'passenger_action') {
          await _audioPlayer.play(AssetSource('audio/ping_pong.mp3'));
        } 
        else if (type == 'new_request' || type == 'trip_accepted' || type == 'new_booking') {
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
        debugPrint("مشكلة في تشغيل الصوت للكابتن: $e");
      }
    });
  }

  void startListeningToActiveTrips() {
    fetchInitialActiveTrips();
  }

  Future<void> fetchInitialActiveTrips() async {
    if (currentUserId.isEmpty) {
      emit(DriverActiveTripsError('لم يتم العثور على حساب السائق، يرجى تسجيل الدخول مجدداً.'));
      return;
    }

    emit(DriverActiveTripsLoading());
    
    _trips.clear();
    _hasReachedMax = false;
    _isFetchingMore = false;

    try {
      final result = await _getDriverActiveTripsUseCase(uid: currentUserId, limit: _limit);

      if (isClosed) return;

      result.fold(
        (failure) {
          emit(DriverActiveTripsError('حدث خطأ أثناء جلب الرحلات النشطة.'));
        },
        (trips) {
          _trips = trips;
          _hasReachedMax = trips.length < _limit;
          
          emit(DriverActiveTripsLoaded(
            trips: List.from(_trips),
            hasReachedMax: _hasReachedMax,
            isFetchingMore: false,
          ));
        },
      );
    } catch (e) {
      if (!isClosed) emit(DriverActiveTripsError('حدث خطأ غير متوقع: $e'));
    }
  }

  Future<void> fetchMoreActiveTrips() async {
    if (_hasReachedMax || _isFetchingMore || currentUserId.isEmpty) return;

    _isFetchingMore = true;
    if (state is DriverActiveTripsLoaded) {
      emit((state as DriverActiveTripsLoaded).copyWith(isFetchingMore: true));
    }

    try {
      final lastTrip = _trips.isNotEmpty ? _trips.last : null;
      final result = await _getDriverActiveTripsUseCase(
        uid: currentUserId, 
        limit: _limit, 
        lastTrip: lastTrip
      );

      if (isClosed) return;

      result.fold(
        (failure) {
          _isFetchingMore = false;
          if (state is DriverActiveTripsLoaded) {
            emit((state as DriverActiveTripsLoaded).copyWith(isFetchingMore: false));
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
          
          emit(DriverActiveTripsLoaded(
            trips: List.from(_trips),
            hasReachedMax: _hasReachedMax,
            isFetchingMore: false,
          ));
        },
      );
    } catch (e) {
      _isFetchingMore = false;
      if (state is DriverActiveTripsLoaded && !isClosed) {
        emit((state as DriverActiveTripsLoaded).copyWith(isFetchingMore: false));
      }
    }
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

      fetchInitialActiveTrips();
    } catch (e) {
      if (isClosed) return; 
      emit(DriverActiveTripsError('حدث خطأ أثناء تفعيل وظيفة الرحلة النشطة.'));
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel(); 
    _audioPlayer.dispose();
    return super.close();
  }
}