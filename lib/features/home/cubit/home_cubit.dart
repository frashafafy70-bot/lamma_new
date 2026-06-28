import 'dart:io';
import 'dart:async'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🟢 مكتبة التخزين المحلي
import 'home_state.dart'; 

import 'package:lamma_new/core/constants/app_strings.dart';
import 'package:lamma_new/core/constants/firebase_constants.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🟢 مفتاح حفظ الصفة محلياً
  static const String _cachedRoleKey = 'CACHED_ACTIVE_ROLE';

  void changeTab(int index) {
    emit(state.copyWith(bottomNavIndex: index));
  }

  Future<void> loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      emit(state.copyWith(status: HomeStatus.loading, userEmail: user.email ?? ''));
      
      // 🟢 1. جلب الصفة من الذاكرة المحلية أولاً لسرعة فتح التطبيق (Instant Load)
      final prefs = await SharedPreferences.getInstance();
      final cachedRole = prefs.getString(_cachedRoleKey);
      if (cachedRole != null) {
        emit(state.copyWith(
          activeRole: cachedRole,
          status: HomeStatus.loaded, // نعرض الواجهة فوراً
        ));
      }

      // 🟢 2. المزامنة مع Firebase في الخلفية للتأكد من أحدث البيانات
      try {
        DocumentSnapshot doc = await _firestore.collection(FirebaseConstants.usersCollection).doc(user.uid).get().timeout(const Duration(seconds: 10));
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          String fetchedRole = (data[FirebaseConstants.activeRoleField] ?? FirebaseConstants.roleCustomer).toString().trim().toLowerCase();
          
          // تحديث الذاكرة المحلية بالبيانات الجديدة
          await prefs.setString(_cachedRoleKey, fetchedRole);

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
        // لو مفيش نت، التطبيق هيفضل شغال على البيانات اللي جابها من الذاكرة المحلية
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

      // 1. التحديث في Firebase
      await _firestore.collection(FirebaseConstants.usersCollection).doc(user.uid).set({
        FirebaseConstants.activeRoleField: newRole
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 3));

      // 🟢 2. تحديث الذاكرة المحلية فوراً بعد نجاح العملية
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedRoleKey, newRole);

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

      // 🟢 تحديث الذاكرة المحلية عند تسجيل مهنة جديدة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedRoleKey, role);

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
}