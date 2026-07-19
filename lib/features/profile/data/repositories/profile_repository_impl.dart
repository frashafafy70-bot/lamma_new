import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProfileRepositoryImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _auth = auth,
        _firestore = firestore,
        _storage = storage;

  @override
  Future<Either<Failure, ProfileEntity>> getUserProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user == null)
        return Left(ServerFailure(message: 'المستخدم غير مسجل الدخول'));

      DocumentSnapshot doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;

        final prefs = await SharedPreferences.getInstance();
        String? cachedRole = prefs.getString('cached_active_role');

        if (cachedRole != null) {
          data['activeRole'] = cachedRole;
        } else {
          await prefs.setString(
              'cached_active_role', data['activeRole'] ?? 'client');
        }

        return Right(ProfileModel.fromJson(data, user.uid, user.email ?? ''));
      } else {
        return Left(ServerFailure(message: 'بيانات المستخدم غير موجودة'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء تحميل البيانات'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateUserProfile({
    required String name,
    required String phone,
    String? nationalId,
    File? newProfileImage,
    required String currentImageUrl,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null)
        return Left(ServerFailure(message: 'المستخدم غير مسجل الدخول'));

      String finalImageUrl = currentImageUrl;

      if (newProfileImage != null) {
        Reference ref = _storage.ref().child(
            '${FirebaseConstants.usersCollection}/${user.uid}/profile.jpg');
        UploadTask uploadTask = ref.putFile(newProfileImage);
        TaskSnapshot snapshot = await uploadTask;
        finalImageUrl = await snapshot.ref.getDownloadURL();
      }

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .update({
        'name': name,
        'phone': phone,
        'nationalId': nationalId ?? '',
        'profileImage': finalImageUrl,
      });

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء حفظ البيانات'));
    }
  }

  @override
  Future<Either<Failure, Unit>> switchUserRole(String newRole) async {
    try {
      User? user = _auth.currentUser;
      if (user == null)
        return Left(ServerFailure(message: 'المستخدم غير مسجل الدخول'));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_active_role', newRole);

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .set({
        'activeRole': newRole,
        'roles': FieldValue.arrayUnion(['client', newRole])
      }, SetOptions(merge: true));

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء تبديل الحساب'));
    }
  }

  @override
  Future<Either<Failure, Unit>> submitRoleRegistration(
      String role, Map<String, dynamic> profileData) async {
    try {
      User? user = _auth.currentUser;
      if (user == null)
        return Left(ServerFailure(message: 'المستخدم غير مسجل الدخول'));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_active_role', role);

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .set({
        'activeRole': role,
        'roles': FieldValue.arrayUnion([role]),
        'documents': {role: profileData}
      }, SetOptions(merge: true));

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء تفعيل الحساب'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadDocument(
      String role, String docName, File file) async {
    try {
      User? user = _auth.currentUser;
      if (user == null)
        return Left(ServerFailure(message: 'المستخدم غير مسجل الدخول'));

      Reference ref = _storage
          .ref()
          .child(FirebaseConstants.usersCollection)
          .child(user.uid)
          .child('documents')
          .child(role)
          .child('$docName.jpg');

      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();

      return Right(url);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء رفع المستند'));
    }
  }

  // 🟢 إضافة كود الفايربيز الخاص بالدعم الفني هنا
  @override
  Future<Either<Failure, Unit>> sendSupportTicket(
      {required String name,
      required String email,
      required String message}) async {
    try {
      String uid = _auth.currentUser?.uid ?? 'unknown';
      await _firestore.collection('support_tickets').add({
        'uid': uid,
        'name': name,
        'email': email,
        'message': message,
        'status': 'open',
        'timestamp': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء إرسال الشكوى: $e'));
    }
  }
}
