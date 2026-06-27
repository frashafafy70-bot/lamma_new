import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. دالة لإرسال الرسالة
  Future<void> sendMessage({
    required String tripId,
    required String senderId,
    required String text,
  }) async {
    try {
      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': senderId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // هنا لاحقاً هنضيف الكود الخاص بإرسال الإشعار (FCM) للطرف التاني
      
    } catch (e) {
      debugPrint("خطأ في إرسال الرسالة: $e");
      rethrow; 
    }
  }

  // 2. دالة لجلب استريم الرسائل (Real-time Stream)
  Stream<QuerySnapshot> getMessagesStream(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}