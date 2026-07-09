import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/order_summary_entity.dart';

class OrderSummaryModel extends OrderSummaryEntity {
  OrderSummaryModel({
    required super.orderId,
    required super.serviceType,
    required super.status,
    required super.createdAt,
    super.price,
  });

  factory OrderSummaryModel.fromJson(Map<String, dynamic> json, String id) {
    return OrderSummaryModel(
      orderId: id,
      serviceType: json['serviceType'] ?? 'خدمة غير محددة',
      status: json['status'] ?? 'pending',
      // تحويل الوقت من Firebase Timestamp لـ DateTime الخاص بـ Dart
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      price: (json['price'] as num?)?.toDouble(),
    );
  }
}