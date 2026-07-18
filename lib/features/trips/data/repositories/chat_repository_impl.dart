import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lamma_new/core/constants/firebase_constants.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Stream<List<ChatMessageEntity>> getMessagesStream(String tripId, int limit) {
    return _firestore
        .collection(FirebaseConstants.tripsCollection)
        .doc(tripId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        MessageType messageType = MessageType.text;
        if (data['type'] == 'audio') messageType = MessageType.audio;
        if (data['type'] == 'image') messageType = MessageType.image;

        return ChatMessageEntity(
          id: doc.id,
          senderId: data['senderId'] ?? '', 
          text: data['text'] ?? '',
          type: messageType,
          imageUrl: data['imageUrl'],
          audioUrl: data['audioUrl'],
          // 🟢 تأمين وقت الـ null أثناء الرفع المبدئي للرسالة
          timestamp: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
          isRead: data['isRead'] ?? false,
        );
      }).toList();
    });
  }

  @override
  Future<void> sendTextMessage({required String tripId, required String senderId, required String text}) async {
    await _firestore.collection(FirebaseConstants.tripsCollection).doc(tripId).collection('messages').add({
      'text': text,
      'imageUrl': '',
      'audioUrl': '',
      'type': 'text',
      'senderId': senderId,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
    // 🟢 السيرفر (Cloud Function) سيتولى إرسال الإشعار تلقائياً بمجرد إضافة المستند
  }

  @override
  Future<void> sendImageMessage({required String tripId, required String senderId, required File imageFile}) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref = _storage.ref().child('trip_chats/$tripId/$fileName.jpg');
    String imageUrl = await (await ref.putFile(imageFile)).ref.getDownloadURL();

    await _firestore.collection(FirebaseConstants.tripsCollection).doc(tripId).collection('messages').add({
      'text': '',
      'imageUrl': imageUrl,
      'audioUrl': '',
      'type': 'image',
      'senderId': senderId,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> sendAudioMessage({required String tripId, required String senderId, required File audioFile}) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref = _storage.ref().child('trip_chats/$tripId/audios/$fileName.m4a');
    String audioUrl = await (await ref.putFile(audioFile)).ref.getDownloadURL();

    await _firestore.collection(FirebaseConstants.tripsCollection).doc(tripId).collection('messages').add({
      'text': '',
      'imageUrl': '',
      'audioUrl': audioUrl,
      'type': 'audio',
      'senderId': senderId,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markMessagesAsRead({required String tripId, required String currentUserId}) async {
    var unreadMessages = await _firestore
        .collection(FirebaseConstants.tripsCollection)
        .doc(tripId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadMessages.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Future<Map<String, String>> getOtherPartyInfo({required String tripId, required String currentUserId}) async {
    try {
      var tripDoc = await _firestore.collection('trips').doc(tripId).get();
      String otherUserId = '';
      if (tripDoc.exists) {
        var tripData = tripDoc.data() as Map<String, dynamic>;
        String driverId = tripData['driverId'] ?? '';
        String passengerId = tripData['passengerId'] ?? tripData['userId'] ?? '';
        if (currentUserId == driverId) {
          if (passengerId.isNotEmpty) {
            otherUserId = passengerId;
          } else {
            var bookings = await _firestore.collection('trip_bookings')
                .where('tripId', isEqualTo: tripId).where('driverId', isEqualTo: currentUserId).limit(1).get();
            if (bookings.docs.isNotEmpty) {
              otherUserId = bookings.docs.first.data()['passengerId'] ?? '';
            }
          }
        } else {
          otherUserId = driverId;
        }
      }
      if (otherUserId.isNotEmpty) {
         var userDoc = await _firestore.collection('users').doc(otherUserId).get();
         if (userDoc.exists) {
            var userData = userDoc.data() as Map<String, dynamic>;
            return {
              'name': userData['name'] ?? userData['displayName'] ?? 'الطرف الآخر',
              'phone': userData['phone'] ?? userData['phoneNumber'] ?? '',
            };
         }
      }
      return {'name': 'مستخدم لَمَّة', 'phone': ''};
    } catch (e) {
      return {'name': 'غير معروف', 'phone': ''};
    }
  }

  @override
  Future<void> sendChatNotification({required String tripId, required String message}) async {
    // ضع لوجيك إرسال الإشعار هنا
  }
}