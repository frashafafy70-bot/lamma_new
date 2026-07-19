import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.timestamp,
    super.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json, String id) {
    // 🟢 حماية الوقت من خطأ الـ FieldValue
    var rawTimestamp = json['timestamp'];
    DateTime parsedTimestamp = DateTime.now();

    if (rawTimestamp is Timestamp) {
      parsedTimestamp = rawTimestamp.toDate();
    }

    return NotificationModel(
      id: id,
      title: json['title'] ?? 'إشعار جديد',
      body: json['body'] ?? '',
      timestamp: parsedTimestamp,
      isRead: json['isRead'] ?? false,
    );
  }
}
