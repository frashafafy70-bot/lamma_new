import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<UserCredential> signUpUser({required String email, required String password, required String name, required String phone}) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    User? user = userCredential.user;
    if (user != null) {
      String? fcmToken = await _messaging.getToken();
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'roles': ['client'],
        'activeRole': 'client',
        'fcmToken': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return userCredential;
  }

  Future<UserCredential> loginUser({required String email, required String password}) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    User? user = userCredential.user;
    if (user != null) {
      String? fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        await _firestore.collection('users').doc(user.uid).update({'fcmToken': fcmToken});
      }
    }
    return userCredential;
  }

  Future<void> signOutUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({'fcmToken': FieldValue.delete()});
    }
    await _auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return doc.data() as Map<String, dynamic>;
    return null;
  }

  Future<UserCredential> loginWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('تم إلغاء تسجيل الدخول');

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential = await _auth.signInWithCredential(credential);
    User? user = userCredential.user;

    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        String? fcmToken = await _messaging.getToken();
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? '',
          'name': user.displayName ?? 'مستخدم جوجل',
          'phone': user.phoneNumber ?? '',
          'roles': ['client'],
          'activeRole': 'client',
          'status': 'approved',
          'fcmToken': fcmToken ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    return userCredential;
  }

  Future<void> sendSignUpOtp({
    required String phone,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    String formattedPhone = phone.startsWith('+') ? phone : '+2$phone';
    var phoneCheck = await _firestore.collection('users').where('phone', isEqualTo: phone).limit(1).get();
    if (phoneCheck.docs.isNotEmpty) {
      onError('رقم الهاتف هذا مسجل بالفعل ومربوط بحساب آخر ⚠️');
      return;
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        onError('فشل إرسال كود التحقق للهاتف: ${e.message} ❌');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<String> verifyOtpAndCompleteSignUp({
    required String verificationId, required String smsCode, required String email, required String password,
    required String name, required String phone, required String role, String? nationalId,
    File? idFrontImage, File? idBackImage, File? professionImage, File? carLicenseFrontImage, File? carLicenseBackImage,
  }) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
    UserCredential phoneUserAuth = await _auth.signInWithCredential(credential);

    if (phoneUserAuth.user != null) {
      UserCredential userCredential = await signUpUser(email: email, password: password, name: name, phone: phone);
      String uid = userCredential.user!.uid;
      Map<String, String> uploadedUrls = {};
      List<String> finalRoles = ['client'];
      String initialActiveRole = 'client';

      if (role != 'عميل' && role != 'client') {
        finalRoles.add('driver');
        initialActiveRole = 'driver';
        if (idFrontImage != null) uploadedUrls['id_front'] = await _uploadFileToStorage('users/$uid/id_front.jpg', idFrontImage);
        if (idBackImage != null) uploadedUrls['id_back'] = await _uploadFileToStorage('users/$uid/id_back.jpg', idBackImage);
        if (carLicenseFrontImage != null) uploadedUrls['car_front'] = await _uploadFileToStorage('users/$uid/car_front.jpg', carLicenseFrontImage);
        if (carLicenseBackImage != null) uploadedUrls['car_back'] = await _uploadFileToStorage('users/$uid/car_back.jpg', carLicenseBackImage);
        if (professionImage != null) uploadedUrls['profession'] = await _uploadFileToStorage('users/$uid/profession.jpg', professionImage);
      }

      String? fcmToken = await _messaging.getToken();
      Map<String, dynamic> additionalData = {
        'roles': finalRoles,
        'activeRole': initialActiveRole,
        'status': 'approved',
        'documents': uploadedUrls,
        'fcmToken': fcmToken ?? '',
      };

      if (role != 'عميل' && role != 'client') additionalData['nationalId'] = nationalId;

      await _firestore.collection('users').doc(uid).set(additionalData, SetOptions(merge: true));
      await phoneUserAuth.user!.delete();
      return uid;
    } else {
      throw Exception('كود الـ OTP المدخل غير صحيح ❌');
    }
  }

  Future<String> _uploadFileToStorage(String path, File file) async {
    Reference ref = FirebaseStorage.instance.ref().child(path);
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}