import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart'; 

import '../data/services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit(this._authService) : super(AuthInitial());

  // ================= الدوال الأساسية =================

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

  // ================= دالة التسجيل باستخدام جوجل =================
  Future<void> loginWithGoogle() async {
    emit(AuthLoading());
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        emit(AuthError('تم إلغاء تسجيل الدخول'));
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email ?? '',
            'name': user.displayName ?? 'مستخدم جوجل',
            'phone': user.phoneNumber ?? '', 
            'role': 'عميل', 
            'status': 'approved',
            'fcmToken': fcmToken ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        emit(AuthSuccess('تم تسجيل الدخول بجوجل بنجاح! 🎉', uid: user.uid));
      }
    } catch (e) {
      emit(AuthError('فشل تسجيل الدخول بجوجل ❌: $e'));
    }
  }

  // ================= دوال التسجيل المتقدمة (OTP + رفع المستندات) =================

  Future<void> sendSignUpOtp({required String phone}) async {
    emit(AuthLoading());
    String formattedPhone = phone.startsWith('+') ? phone : '+2$phone';

    try {
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
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential phoneUserAuth = await FirebaseAuth.instance.signInWithCredential(credential);

      if (phoneUserAuth.user != null) {
        
        var userCredential = await _authService.signUpUser(
          email: email,
          password: password,
          name: name,
          phone: phone,
        );

        String uid = userCredential.user!.uid;
        Map<String, String> uploadedUrls = {};

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

        String? fcmToken = await FirebaseMessaging.instance.getToken();

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

        await FirebaseFirestore.instance.collection('users').doc(uid).set(additionalData, SetOptions(merge: true));
        
        await phoneUserAuth.user!.delete();

        emit(AuthSuccess('تم إنشاء وتفعيل حسابك بنجاح مئة بالمئة! 🎉🚀', uid: uid));
      }
    } catch (e) {
      emit(AuthError('كود الـ OTP المدخل غير صحيح أو حدث خطأ ❌'));
    }
  }

  Future<String> _uploadFileToStorage(String path, File file) async {
    Reference ref = FirebaseStorage.instance.ref().child(path);
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}