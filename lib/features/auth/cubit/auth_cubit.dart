import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../data/services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit(this._authService) : super(AuthInitial());

  // ================= الدوال الأساسية الخاصة بك =================

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    emit(AuthLoading());
    try {
      var userCredential = await _authService.signUpUser(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      
      emit(AuthSuccess('تم إنشاء الحساب بنجاح!', uid: userCredential.user?.uid));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      var userCredential = await _authService.loginUser(
        email: email,
        password: password,
      );
      
      emit(AuthSuccess('تم تسجيل الدخول بنجاح!', uid: userCredential.user?.uid));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await _authService.signOutUser();
      emit(AuthLoggedOut()); 
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ================= دوال التسجيل المتقدمة (OTP + رفع المستندات) =================

  // 1. إرسال كود الـ OTP
  Future<void> sendSignUpOtp({required String phone}) async {
    emit(AuthLoading());
    String formattedPhone = phone.startsWith('+') ? phone : '+2$phone';

    try {
      // التأكد من أن الرقم غير مسجل
      var phoneCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (phoneCheck.docs.isNotEmpty) {
        emit(AuthError('رقم الهاتف هذا مسجل بالفعل ومربوط بحساب آخر ⚠️'));
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          emit(AuthError('فشل إرسال كود التحقق للهاتف: ${e.message} ❌'));
        },
        codeSent: (String verificationId, int? resendToken) {
          emit(AuthOtpSent(verificationId));
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      emit(AuthError('حدث خطأ: $e'));
    }
  }

  // 2. تفعيل الحساب برقم الهاتف واستكمال التسجيل عبر AuthService
  Future<void> verifyOtpAndCompleteSignUp({
    required String verificationId,
    required String smsCode,
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? nationalId,
    File? idFrontImage,
    File? idBackImage,
    File? professionImage,
    File? carLicenseFrontImage,
    File? carLicenseBackImage,
  }) async {
    emit(AuthLoading());

    try {
      // 1. التحقق من كود الـ OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential phoneUserAuth = await FirebaseAuth.instance.signInWithCredential(credential);

      if (phoneUserAuth.user != null) {
        
        // 2. إنشاء الحساب الأساسي باستخدام AuthService الخاصة بك للحفاظ على نظافة المعمارية
        var userCredential = await _authService.signUpUser(
          email: email,
          password: password,
          name: name,
          phone: phone,
        );

        String uid = userCredential.user!.uid;
        Map<String, String> uploadedUrls = {};

        // 3. رفع المستندات لـ Storage بناءً على نوع المستخدم
        if (role != 'عميل') {
          uploadedUrls['id_front'] = await _uploadFileToStorage('users/$uid/id_front.jpg', idFrontImage!);
          uploadedUrls['id_back'] = await _uploadFileToStorage('users/$uid/id_back.jpg', idBackImage!);
        }
        if (carLicenseFrontImage != null) {
          uploadedUrls['car_front'] = await _uploadFileToStorage('users/$uid/car_front.jpg', carLicenseFrontImage);
          uploadedUrls['car_back'] = await _uploadFileToStorage('users/$uid/car_back.jpg', carLicenseBackImage!);
        }
        if (professionImage != null) {
          uploadedUrls['profession'] = await _uploadFileToStorage('users/$uid/profession.jpg', professionImage);
        }

        // 4. الحصول على توكن الإشعارات
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        // 5. إضافة البيانات الإضافية في Firestore
        Map<String, dynamic> additionalData = {
          'uid': uid,
          'role': role,
          'status': 'approved', 
          'documents': uploadedUrls,
          'fcmToken': fcmToken ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (role != 'عميل') {
          additionalData['nationalId'] = nationalId;
        }

        // استخدام merge: true لدمج البيانات الجديدة مع البيانات اللي AuthService كتبتها
        await FirebaseFirestore.instance.collection('users').doc(uid).set(additionalData, SetOptions(merge: true));
        
        // مسح مستخدم الموبايل الوهمي (OTP)
        await phoneUserAuth.user!.delete();

        emit(AuthSuccess('تم إنشاء وتفعيل حسابك بنجاح مئة بالمئة! 🎉🚀', uid: uid));
      }
    } catch (e) {
      emit(AuthError('كود الـ OTP المدخل غير صحيح أو حدث خطأ ❌'));
    }
  }

  // دالة مساعدة لرفع الملفات
  Future<String> _uploadFileToStorage(String path, File file) async {
    Reference ref = FirebaseStorage.instance.ref().child(path);
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}