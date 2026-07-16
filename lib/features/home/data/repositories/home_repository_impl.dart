import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/service_category_entity.dart';
import '../../domain/entities/order_summary_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../models/service_category_model.dart';
import '../models/order_summary_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HomeRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  // 🟢 دالة مساعدة لضمان فتح الصندوق بأمان لتجنب إيرور (Box not found)
  Future<Box<ServiceCategoryModel>> _getOpenBox() async {
    if (!Hive.isBoxOpen('categories_box')) {
      return await Hive.openBox<ServiceCategoryModel>('categories_box');
    }
    return Hive.box<ServiceCategoryModel>('categories_box');
  }

  @override
  Future<Either<Failure, List<ServiceCategoryEntity>>> getServiceCategories() async {
    try {
      final snapshot = await _firestore.collection('service_categories').get();
      
      final categories = snapshot.docs
          .map((doc) => ServiceCategoryModel.fromJson(doc.data(), doc.id))
          .toList();

      // فتح الصندوق وتحديث الكاش بأمان
      final box = await _getOpenBox();
      await box.clear();
      await box.addAll(categories);
          
      return Right(categories);
    } catch (e) {
      try {
        // 🟢 تأمين الـ Catch: محاولة جلب البيانات من الكاش بأمان
        final box = await _getOpenBox();
        final cachedCategories = box.values.toList();
        if (cachedCategories.isNotEmpty) {
          return Right(cachedCategories);
        }
      } catch (hiveError) {
        // تجاهل أخطاء Hive الفرعية في حالة فشل فتح الصندوق
      }
      
      return Left(ServerFailure(message: 'لا توجد صلاحية أو حدث خطأ أثناء الاتصال.'));
    }
  }

  @override
  Future<Either<Failure, List<OrderSummaryEntity>>> getActiveOrdersSummary() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure(message: 'المستخدم غير مسجل الدخول.'));
      }

      final snapshot = await _firestore
          .collection('orders') 
          .where('userId', isEqualTo: user.uid)
          .where('status', isNotEqualTo: 'completed') 
          .limit(3) 
          .get();

      final orders = snapshot.docs
          .map((doc) => OrderSummaryModel.fromJson(doc.data(), doc.id))
          .toList();

      return Right(orders);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ أثناء تحميل الطلبات النشطة.'));
    }
  }

  // 🟢 تنفيذ ستريم الرادار
  @override
  Stream<int> getRadarBadgeCountStream(String currentUserId) {
    return _firestore
        .collection('trips')
        .where('isDriverPost', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        var d = doc.data();
        if (d['isDeletedForDriver'] == true) return false;
        String status = d['status'] ?? '';
        String driverId = d['driverId'] ?? '';
        String ownerId = d['userId'] ?? d['passengerId'] ?? '';
        bool isPending = status == 'pending';
        bool isNegotiatingWithAnother = status == 'negotiating' && driverId != currentUserId;
        return (isPending || isNegotiatingWithAnother) && ownerId != currentUserId;
      }).length;
    }).handleError((_) => 0); 
  }

  // 🟢 تنفيذ ستريم الرحلات النشطة
  @override
  Stream<int> getActiveTripsBadgeCountStream(String currentUserId) {
    return _firestore
        .collection('trip_bookings')
        .where('driverId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        var d = doc.data();
        return d['status'] == 'pending';
      }).length;
    }).handleError((_) => 0);
  }

  // 🟢 تنفيذ ستريم طلبات العملاء
  @override
  Stream<int> getClientRequestsBadgeCountStream(String currentUserId) {
    return _firestore
        .collection('trips')
        .where('isDriverPost', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        var d = doc.data();
        return d['status'] == 'available' && (d['driverId'] ?? '') != currentUserId;
      }).length;
    }).handleError((_) => 0);
  }
}