import 'dart:io';
import 'dart:async'; // 🟢 ضرورية عشان الـ Timeout
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'home_state.dart'; 

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void changeTab(int index) {
    emit(state.copyWith(bottomNavIndex: index));
  }

  Future<void> loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      emit(state.copyWith(status: HomeStatus.loading, userEmail: user.email ?? ''));
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get().timeout(const Duration(seconds: 10));
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          emit(state.copyWith(
            userName: data['name'] ?? 'مستخدم لَمَّة',
            profileImageUrl: data['profileImage'] ?? '',
            activeRole: data['activeRole'] ?? 'customer',
            status: HomeStatus.loaded,
          ));
        } else {
          emit(state.copyWith(status: HomeStatus.loaded));
        }
      } catch (e) {
        emit(state.copyWith(status: HomeStatus.error, errorMessage: 'حدث خطأ في الاتصال، يرجى المحاولة لاحقاً.'));
      }
    }
  }

  Future<void> switchUserRole(String newRole) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    emit(state.copyWith(actionStatus: HomeActionStatus.loading));
    
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get().timeout(const Duration(seconds: 5));
      var userData = userDoc.data() as Map<String, dynamic>? ?? {};
      bool hasProfile = userData.containsKey('profiles') && (userData['profiles'] as Map).containsKey(newRole);

      if (!hasProfile && newRole != 'customer') {
        emit(state.copyWith(
          actionStatus: HomeActionStatus.registrationRequired,
          pendingRegistrationRole: newRole,
        ));
        return; 
      }

      // 🟢 تم إرجاع الـ await مع timeout قصير لضمان أمان البيانات وصيد الأخطاء
      await _firestore.collection('users').doc(user.uid).set({'activeRole': newRole}, SetOptions(merge: true)).timeout(const Duration(seconds: 3));

      emit(state.copyWith(
        activeRole: newRole,
        actionStatus: HomeActionStatus.success,
        successMessage: 'تم التحويل لوضع الحساب الجديد بنجاح ✅',
      ));
    } catch (e) {
      emit(state.copyWith(actionStatus: HomeActionStatus.error, errorMessage: 'فشل التحويل، تأكد من جودة الإنترنت.'));
    }
  }

  Future<void> sendPasswordResetEmail() async {
    User? user = _auth.currentUser;
    if (user != null && user.email != null) {
      emit(state.copyWith(actionStatus: HomeActionStatus.loading));
      try {
        // 🟢 إضافة timeout للـ Auth عشان ميعلقش
        await _auth.sendPasswordResetEmail(email: user.email!).timeout(const Duration(seconds: 10));
        emit(state.copyWith(
          actionStatus: HomeActionStatus.success,
          successMessage: 'تم إرسال رابط تغيير كلمة المرور 📧',
        ));
      } catch (e) {
        emit(state.copyWith(actionStatus: HomeActionStatus.error, errorMessage: 'فشل الإرسال، تحقق من اتصالك بالإنترنت.'));
      }
    }
  }

  Future<void> submitRoleRegistration({required String role, required Map<String, dynamic> profileData}) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    emit(state.copyWith(actionStatus: HomeActionStatus.loading));
    try {
      // 🟢 تم إرجاع الـ await مع timeout لضمان إن البيانات اتسجلت فعلاً ومش نجاح وهمي
      await _firestore.collection('users').doc(user.uid).set({
        'activeRole': role,
        'roles': FieldValue.arrayUnion([role]),
        'profiles': {role: profileData}
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));

      emit(state.copyWith(
        activeRole: role,
        actionStatus: HomeActionStatus.success,
        successMessage: 'تم تفعيل الحساب بنجاح 🎉',
      ));
    } catch (e) {
      emit(state.copyWith(actionStatus: HomeActionStatus.error, errorMessage: 'فشل التفعيل، تأكد من الاتصال بالشبكة.'));
    }
  }

  Future<String?> uploadDocument({required String role, required String docName, required File file}) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;
      Reference ref = FirebaseStorage.instance.ref().child('users').child(user.uid).child('documents').child(role).child('$docName.jpg');
      UploadTask uploadTask = ref.putFile(file);
      
      // 🟢 إضافة timeout لعملية رفع الملفات عشان متفضلش معلقة للأبد
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