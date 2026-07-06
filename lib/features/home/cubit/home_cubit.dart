import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'home_state.dart';
import 'package:lamma_new/core/constants/app_strings.dart';
import 'package:lamma_new/core/constants/firebase_constants.dart';
import 'package:lamma_new/features/trips/data/models/trip_model.dart';

// 🟢 استيراد الـ Use Cases من طبقة الـ Domain
import 'package:lamma_new/features/trips/domain/usecases/get_driver_active_orders_usecase.dart';
import 'package:lamma_new/features/trips/domain/usecases/get_passenger_active_orders_usecase.dart';
import 'package:lamma_new/features/trips/domain/usecases/add_travel_trip_usecase.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetDriverActiveOrdersCountUseCase _getDriverActiveOrders;
  final GetPassengerActiveOrdersCountUseCase _getPassengerActiveOrders;
  final AddTravelTripUseCase _addTravelTripUseCase;

  StreamSubscription<RemoteMessage>? _notificationSubscription;
  StreamSubscription<QuerySnapshot>? _unreadNotificationsSub;
  StreamSubscription<int>? _activeOrdersSub;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _cachedRoleKey = 'CACHED_ACTIVE_ROLE';

  HomeCubit({
    required GetDriverActiveOrdersCountUseCase getDriverActiveOrders,
    required GetPassengerActiveOrdersCountUseCase getPassengerActiveOrders,
    required AddTravelTripUseCase addTravelTripUseCase,
  })  : _getDriverActiveOrders = getDriverActiveOrders,
        _getPassengerActiveOrders = getPassengerActiveOrders,
        _addTravelTripUseCase = addTravelTripUseCase,
        super(HomeState()) {
    _listenToForegroundNotifications();
  }

  String _normalizeRole(String role) {
    final cleanRole = role.trim().toLowerCase();
    if (cleanRole == 'customer' || cleanRole == 'client') return 'client';
    if (cleanRole == 'captain' || cleanRole == 'driver') return 'driver';
    return cleanRole;
  }

  void _listenToForegroundNotifications() {
    _notificationSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'new_trip' || message.data['channel_id'] == 'lamma_final_sound') {
        emit(state.copyWith(hasNewNotification: true));
      }
    });
  }

  void _listenToUnreadNotifications(String uid) {
    _unreadNotificationsSub?.cancel();
    _unreadNotificationsSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      emit(state.copyWith(unreadNotificationsCount: snapshot.docs.length));
    });
  }

  void _listenToActiveOrders(String uid, String role) {
    _activeOrdersSub?.cancel();

    final normalizedRole = _normalizeRole(role);

    if (normalizedRole == 'driver') {
      _activeOrdersSub = _getDriverActiveOrders(uid).listen((count) {
        emit(state.copyWith(activeOrdersCount: count));
      }, onError: (e) {
        debugPrint("❌ خطأ: $e");
      });
    } else {
      _activeOrdersSub = _getPassengerActiveOrders(uid).listen((count) {
        emit(state.copyWith(activeOrdersCount: count));
      }, onError: (e) {
        debugPrint("❌ خطأ: $e");
      });
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    var unreadDocs = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadDocs.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    for (var doc in unreadDocs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();

    emit(state.copyWith(hasNewNotification: false, unreadNotificationsCount: 0));
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    _unreadNotificationsSub?.cancel();
    _activeOrdersSub?.cancel();
    return super.close();
  }

  void changeTab(int index) {
    emit(state.copyWith(
      bottomNavIndex: index,
      hasNewNotification: false,
    ));
  }

  Future<void> loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    emit(state.copyWith(status: HomeStatus.loading, userEmail: user.email ?? ''));
    _listenToUnreadNotifications(user.uid);

    final prefs = await SharedPreferences.getInstance();
    final cachedRole = prefs.getString(_cachedRoleKey);

    if (cachedRole != null) {
      final normalizedCachedRole = _normalizeRole(cachedRole);
      await prefs.setString(_cachedRoleKey, normalizedCachedRole);

      emit(state.copyWith(activeRole: normalizedCachedRole, status: HomeStatus.loaded));
      _listenToActiveOrders(user.uid, normalizedCachedRole);
    }

    try {
      DocumentSnapshot doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .get(const GetOptions(source: Source.server)) 
          .timeout(const Duration(seconds: 10));

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;

        String fetchedRole = _normalizeRole((data['activeRole'] ?? 'client').toString());

        await prefs.setString(_cachedRoleKey, fetchedRole);
        _listenToActiveOrders(user.uid, fetchedRole);

        emit(state.copyWith(
          userName: data['name'] ?? 'مستخدم لَمَّة',
          profileImageUrl: data['profileImage'] ?? '',
          activeRole: fetchedRole,
          status: HomeStatus.loaded,
        ));
      } else {
        emit(state.copyWith(status: HomeStatus.loaded));
      }
    } catch (e) {
      if (cachedRole == null) {
        emit(state.copyWith(status: HomeStatus.error, errorMessage: AppStrings.networkError));
      }
    }
  }

  Future<void> switchUserRole(String newRole) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final normalizedRole = _normalizeRole(newRole);
    final currentNormalizedRole = _normalizeRole(state.activeRole);

    if (normalizedRole == currentNormalizedRole) return;

    emit(state.copyWith(actionStatus: HomeActionStatus.loading));

    try {
      // 🚀 الحل النووي: تحديث السيرفر فوراً وإضافة الصلاحية للمصفوفة لتخطي شاشة التفعيل
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .set({
            'activeRole': normalizedRole,
            'roles': FieldValue.arrayUnion(['client', normalizedRole]) 
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedRoleKey, normalizedRole);

      _listenToActiveOrders(user.uid, normalizedRole);

      emit(state.copyWith(
        activeRole: normalizedRole,
        actionStatus: HomeActionStatus.success,
        successMessage: 'تم تبديل الحساب بنجاح 🔄',
      ));
    } catch (e) {
      emit(state.copyWith(actionStatus: HomeActionStatus.error, errorMessage: AppStrings.networkError));
    }
  }

  Future<void> sendPasswordResetEmail() async {
    User? user = _auth.currentUser;
    if (user != null && user.email != null) {
      emit(state.copyWith(actionStatus: HomeActionStatus.loading));
      try {
        await _auth.sendPasswordResetEmail(email: user.email!).timeout(const Duration(seconds: 10));
        emit(state.copyWith(
          actionStatus: HomeActionStatus.success,
          successMessage: 'تم إرسال رابط تغيير كلمة المرور 📧',
        ));
      } catch (e) {
        emit(state.copyWith(actionStatus: HomeActionStatus.error, errorMessage: AppStrings.networkError));
      }
    }
  }

  Future<void> submitRoleRegistration({
    required String role,
    required Map<String, dynamic> profileData,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final normalizedRole = _normalizeRole(role);

    emit(state.copyWith(actionStatus: HomeActionStatus.loading));

    try {
      await _firestore.collection(FirebaseConstants.usersCollection).doc(user.uid).set({
        'activeRole': normalizedRole,
        'roles': FieldValue.arrayUnion([normalizedRole]), 
        'documents': {normalizedRole: profileData} 
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedRoleKey, normalizedRole);

      _listenToActiveOrders(user.uid, normalizedRole);

      emit(state.copyWith(
        activeRole: normalizedRole,
        actionStatus: HomeActionStatus.success,
        successMessage: 'تم تفعيل الحساب بنجاح 🎉',
      ));
    } catch (e) {
      emit(state.copyWith(actionStatus: HomeActionStatus.error, errorMessage: AppStrings.networkError));
    }
  }

  Future<String?> uploadDocument({
    required String role,
    required String docName,
    required File file,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      final normalizedRole = _normalizeRole(role);

      Reference ref = FirebaseStorage.instance
          .ref()
          .child(FirebaseConstants.usersCollection)
          .child(user.uid)
          .child('documents')
          .child(normalizedRole)
          .child('$docName.jpg');

      UploadTask uploadTask = ref.putFile(file);

      TaskSnapshot snapshot = await uploadTask.timeout(const Duration(seconds: 30));
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  void clearActionStatus() {
    emit(state.copyWith(actionStatus: HomeActionStatus.idle, pendingRegistrationRole: null));
  }

  Future<void> addTravelTrip({required TripModel trip}) async {
    emit(state.copyWith(actionStatus: HomeActionStatus.loading));
    try {
      await _addTravelTripUseCase(trip);
      emit(state.copyWith(
        actionStatus: HomeActionStatus.success,
        successMessage: 'تم نشر رحلة السفر بنجاح! 🚌',
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: HomeActionStatus.error,
        errorMessage: 'حدث خطأ أثناء إضافة الرحلة، برجاء المحاولة مرة أخرى.',
      ));
    }
  }
}