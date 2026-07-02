import 'dart:io';
import 'dart:async'; 
import 'package:flutter/foundation.dart'; 
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
import 'package:lamma_new/features/trips/data/services/trip_service.dart';

class HomeCubit extends Cubit<HomeState> {
  // 🟢 استدعاء الـ Service عشان الـ Cubit ميكلمش الفايربيز مباشرة في الرحلات
  final TripService _tripService;

  StreamSubscription<RemoteMessage>? _notificationSubscription;
  StreamSubscription<QuerySnapshot>? _unreadNotificationsSub; 
  StreamSubscription<int>? _activeOrdersSub; // 🟢 ستريم واحد بس بدل 4!

  // هنسيب دول مؤقتاً لحد ما نفصل شغل الـ Auth والـ User Profile في Services لوحدهم
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _cachedRoleKey = 'CACHED_ACTIVE_ROLE';

  // 🟢 Dependency Injection: لو مكتبة get_it مش موجودة، هيعمل نسخة لنفسه عشان التطبيق ميضربش
  HomeCubit({TripService? tripService}) 
      : _tripService = tripService ?? TripService(), 
        super(HomeState()) {
    _listenToForegroundNotifications(); 
  }

  void _listenToForegroundNotifications() {
    _notificationSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("🔔 [HomeCubit] إشعار لايف وصل: ${message.notification?.title}");
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

  // 🟢 شوف النضافة! الكيوبت بقى بيسمع للنتيجة النهائية من السيرفيس بس
  void _listenToActiveOrders(String uid, String role) {
    _activeOrdersSub?.cancel(); // نقفل أي استماع قديم عشان الـ Memory Leak

    if (role == 'captain') {
      _activeOrdersSub = _tripService.getCaptainActiveOrdersCountStream(uid).listen((count) {
        emit(state.copyWith(activeOrdersCount: count));
      }, onError: (e) {
        debugPrint("❌ خطأ في الاستماع لطلبات الكابتن: $e");
      });
    } else {
      _activeOrdersSub = _tripService.getPassengerActiveOrdersCountStream(uid).listen((count) {
        emit(state.copyWith(activeOrdersCount: count));
      }, onError: (e) {
        debugPrint("❌ خطأ في الاستماع لطلبات العميل: $e");
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
    _activeOrdersSub?.cancel(); // 🟢 قفلنا الستريم الجديد
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
    if (user != null) {
      emit(state.copyWith(status: HomeStatus.loading, userEmail: user.email ?? ''));
      _listenToUnreadNotifications(user.uid); 

      final prefs = await SharedPreferences.getInstance();
      final cachedRole = prefs.getString(_cachedRoleKey);
      if (cachedRole != null) {
        emit(state.copyWith(activeRole: cachedRole, status: HomeStatus.loaded));
        _listenToActiveOrders(user.uid, cachedRole); 
      }

      try {
        DocumentSnapshot doc = await _firestore.collection(FirebaseConstants.usersCollection).doc(user.uid).get().timeout(const Duration(seconds: 10));
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          String fetchedRole = (data[FirebaseConstants.activeRoleField] ?? FirebaseConstants.roleCustomer).toString().trim().toLowerCase();
          
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
  }

  Future<void> switchUserRole(String newRole) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    if (newRole.trim().toLowerCase() == state.activeRole.trim().toLowerCase()) return;

    emit(state.copyWith(actionStatus: HomeActionStatus.loading));
    
    try {
      DocumentSnapshot userDoc = await _firestore.collection(FirebaseConstants.usersCollection).doc(user.uid).get().timeout(const Duration(seconds: 5));
      var userData = userDoc.data() as Map<String, dynamic>? ?? {};
      
      Map<String, dynamic> profiles = {};
      if (userData.containsKey(FirebaseConstants.profilesField) && userData[FirebaseConstants.profilesField] != null) {
        profiles = Map<String, dynamic>.from(userData[FirebaseConstants.profilesField] as Map);
      }
      bool hasProfile = profiles.containsKey(newRole);

      if (!hasProfile && newRole != FirebaseConstants.roleCustomer) {
        emit(state.copyWith(
          actionStatus: HomeActionStatus.registrationRequired,
          pendingRegistrationRole: newRole,
        ));
        return; 
      }

      await _firestore.collection(FirebaseConstants.usersCollection).doc(user.uid).set({
        FirebaseConstants.activeRoleField: newRole
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 3));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedRoleKey, newRole);

      _listenToActiveOrders(user.uid, newRole); 

      emit(state.copyWith(
        activeRole: newRole,
        actionStatus: HomeActionStatus.success,
        successMessage: AppStrings.switchSuccess,
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

  Future<void> submitRoleRegistration({required String role, required Map<String, dynamic> profileData}) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    emit(state.copyWith(actionStatus: HomeActionStatus.loading));
    try {
      await _firestore.collection(FirebaseConstants.usersCollection).doc(user.uid).set({
        FirebaseConstants.activeRoleField: role,
        FirebaseConstants.rolesField: FieldValue.arrayUnion([role]),
        FirebaseConstants.profilesField: {role: profileData}
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedRoleKey, role);

      _listenToActiveOrders(user.uid, role); 

      emit(state.copyWith(
        activeRole: role,
        actionStatus: HomeActionStatus.success,
        successMessage: 'تم تفعيل الحساب بنجاح 🎉', 
      ));
    } catch (e) {
      emit(state.copyWith(actionStatus: HomeActionStatus.error, errorMessage: AppStrings.networkError));
    }
  }

  Future<String?> uploadDocument({required String role, required String docName, required File file}) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;
      Reference ref = FirebaseStorage.instance.ref().child(FirebaseConstants.usersCollection).child(user.uid).child('documents').child(role).child('$docName.jpg');
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

  // 🟢 بص الدالة هنا بقت سطرين بس، بتبعت الداتا للـ Service وهو يتصرف
  Future<void> addTravelTrip({required TripModel trip}) async {
    emit(state.copyWith(actionStatus: HomeActionStatus.loading));
    try {
      await _tripService.addTravelTrip(trip);
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