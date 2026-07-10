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

  Box<ServiceCategoryModel> get _categoriesBox => Hive.box<ServiceCategoryModel>('categories_box');

  @override
  Future<Either<Failure, List<ServiceCategoryEntity>>> getServiceCategories() async {
    try {
      final snapshot = await _firestore.collection('service_categories').get();
      
      final categories = snapshot.docs
          .map((doc) => ServiceCategoryModel.fromJson(doc.data(), doc.id))
          .toList();

      // تحديث الـ Hive
      await _categoriesBox.clear();
      await _categoriesBox.addAll(categories);
          
      return Right(categories);
    } catch (e) {
      final cachedCategories = _categoriesBox.values.toList();
      if (cachedCategories.isNotEmpty) {
        return Right(cachedCategories);
      }
      return Left(ServerFailure(message: 'حدث خطأ أثناء تحميل أقسام الخدمات.'));
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
}