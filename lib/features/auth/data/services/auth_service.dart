import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ==========================================
  // 1. دالة إنشاء حساب جديد
  // ==========================================
  Future<UserCredential> signUpUser({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        String? fcmToken = await _messaging.getToken();

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'roles': ['customer'], 
          'activeRole': 'customer', 
          'fcmToken': fcmToken, 
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('البريد الإلكتروني مستخدم بالفعل لحساب آخر.');
      } else if (e.code == 'weak-password') {
        throw Exception('كلمة المرور ضعيفة جداً.');
      } else if (e.code == 'invalid-email') {
        throw Exception('صيغة البريد الإلكتروني غير صحيحة.');
      }
      throw Exception('حدث خطأ أثناء التسجيل: ${e.message}');
    } catch (e) {
      throw Exception('خطأ غير متوقع: $e');
    }
  }

  // ==========================================
  // 2. دالة تسجيل الدخول
  // ==========================================
  Future<UserCredential> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        String? fcmToken = await _messaging.getToken();
        if (fcmToken != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': fcmToken,
          });
        }
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        throw Exception('لا يوجد حساب مسجل بهذا البريد.');
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('كلمة المرور غير صحيحة.');
      }
      throw Exception('بيانات الدخول غير صحيحة.');
    } catch (e) {
      throw Exception('حدث خطأ أثناء محاولة الدخول.');
    }
  }

  // ==========================================
  // 3. دالة تسجيل الخروج
  // ==========================================
  Future<void> signOutUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // حذف التوكن قبل تسجيل الخروج
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
      }
      await _auth.signOut();
    } catch (e) {
      throw Exception('حدث خطأ أثناء تسجيل الخروج.');
    }
  }

  // ==========================================
  // 4. دالة جلب بيانات المستخدم (إضافة هامة للـ Cubit)
  // ==========================================
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب بيانات المستخدم.');
    }
  }
}