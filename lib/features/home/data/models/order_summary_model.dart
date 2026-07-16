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
    // 🟢 الحل الجوهري: حماية عملية تحويل الوقت من الأخطاء
    
    // 1. استخراج القيمة الخام للوقت
    var rawCreatedAt = json['createdAt'];
    DateTime createdAtDateTime;

    // 2. التحقق من نوع البيانات بشكل آمن
    if (rawCreatedAt is Timestamp) {
      // لو البيانات هي Timestamp فعلاً (يعني قرأناها من السيرفر بنجاح)
      createdAtDateTime = rawCreatedAt.toDate();
    } else {
      // لو البيانات أي حاجة تانية (FieldValue مثلاً لسه مكتبتش ع السيرفر) أو Null
      // بنستخدم الوقت الحالي كـ Fallback عشان الـ UI ميكرش
      createdAtDateTime = DateTime.now(); 
    }

    return OrderSummaryModel(
      orderId: id,
      serviceType: json['serviceType'] ?? 'خدمة غير محددة',
      status: json['status'] ?? 'pending',
      createdAt: createdAtDateTime, // استخدام الوقت الآمن
      price: (json['price'] as num?)?.toDouble(),
    );
  }
}