// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// استيراد الصفحة الرئيسية (المخ الذكي للمنصة)
import '../../../home/home_page.dart'; 
import 'login_page.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ==========================================
  // 1. دالة إنشاء حساب جديد (مع إعطاء الأدوار الافتراضية وحفظ التوكن)
  // ==========================================
  Future<UserCredential?> signUpUser({
    required BuildContext context,
    required String email,
    required String password,
    required String name,
    required String phone, // إضافة رقم الهاتف لربطه بالبحث لاحقاً
  }) async {
    try {
      // 1. إنشاء الحساب في Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // 2. جلب توكن الإشعارات الخاص بالجهاز
        String? fcmToken = await _messaging.getToken();

        // 3. حفظ بيانات المستخدم والأدوار في Cloud Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'roles': ['customer'], // الدور الافتراضي لأي مستخدم جديد
          'activeRole': 'customer', // الوضع الفعال الحالي
          'fcmToken': fcmToken, // حفظ التوكن لإرسال الإشعارات
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        String errorMessage = 'حدث خطأ أثناء التسجيل';
        if (e.code == 'email-already-in-use') {
          errorMessage = 'البريد الإلكتروني مستخدم بالفعل لحساب آخر.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'كلمة المرور ضعيفة جداً.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'صيغة البريد الإلكتروني غير صحيحة.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')), backgroundColor: Colors.red.shade800)
        );
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ غير متوقع: $e', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red.shade800)
        );
      }
      return null;
    }
  }

  // ==========================================
  // 2. دالة تسجيل الدخول والتوجيه الذكي
  // ==========================================
  Future<void> loginAndRouteUser({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      // 1. تسجيل الدخول العادي
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null && context.mounted) {
        // 2. تحديث توكن الإشعارات في حال دخول المستخدم من جهاز جديد
        String? fcmToken = await _messaging.getToken();
        if (fcmToken != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': fcmToken,
          });
        }

        // 3. التوجيه المباشر للصفحة الرئيسية
        // (الصفحة الرئيسية HomePage مبرمجة حالياً لتقرأ الـ activeRole وتغير الواجهة تلقائياً)
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false, // تصفير مسار العودة حتى لا يعود لصفحة الدخول بالخطأ
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        String errorMessage = 'بيانات الدخول غير صحيحة.';
        if (e.code == 'user-not-found' || e.code == 'invalid-email') {
          errorMessage = 'لا يوجد حساب مسجل بهذا البريد.';
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          errorMessage = 'كلمة المرور غير صحيحة.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')), backgroundColor: Colors.red.shade800)
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء محاولة الدخول.', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red.shade800)
        );
      }
    }
  }

  // ==========================================
  // 3. دالة تسجيل الخروج السريع
  // ==========================================
  Future<void> signOutUser(BuildContext context) async {
    try {
      // اختياري: مسح التوكن من الداتابيز حتى لا تصله إشعارات وهو مسجل خروج
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
      }

      await _auth.signOut();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تسجيل الخروج.', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red)
        );
      }
    }
  }
}