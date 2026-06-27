import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

part 'trip_chat_state.dart';

class TripChatCubit extends Cubit<TripChatState> {
  TripChatCubit() : super(TripChatInitial());

  final AudioRecorder _audioRecorder = AudioRecorder();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  StreamSubscription? _chatSubscription;
  bool isRecording = false;
  
  // 🟢 تخزين الرسائل في الكيوبت عشان الشات مايختفيش وقت الأنيميشن بتاع المايك
  List<Map<String, dynamic>> _messages = [];

  @override
  Future<void> close() {
    _audioRecorder.dispose();
    _chatSubscription?.cancel();
    return super.close();
  }

  void loadChat(String tripId) {
    emit(TripChatLoading());
    
    _chatSubscription?.cancel();
    _chatSubscription = FirebaseFirestore.instance
        .collection('trips')
        .doc(tripId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          
      _messages = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      markMessagesAsRead(tripId, snapshot.docs);

      // 🟢 هنا دايماً بنبعت الـ State محملة بالرسايل
      emit(TripChatLoaded(_messages));
    }, onError: (error) {
      emit(TripChatError("خطأ في جلب الرسائل: $error"));
    });
  }

  // الدالة التي تستخدمها الشاشة الحالية لإرسال نص
  Future<void> sendMessage(String tripId, String senderId, String text) async {
    if (text.trim().isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).collection('messages').add({
        'text': text.trim(), 
        'imageUrl': '',
        'audioUrl': '',
        'type': 'text',
        'senderId': senderId,
        'isRead': false, 
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      emit(TripChatError("خطأ في إرسال الرسالة: $e"));
    }
  }

  // الدالة القديمة لضمان عدم توقف أي Widget آخر يعتمد عليها
  Future<void> sendTextMessage(String tripId, String text) async {
    if (text.trim().isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).collection('messages').add({
        'text': text.trim(), 
        'imageUrl': '',
        'audioUrl': '',
        'type': 'text',
        'senderId': currentUserId,
        'isRead': false, 
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      emit(TripChatError("خطأ في إرسال الرسالة: $e"));
    }
  }

  Future<void> sendImageMessage(String tripId, File imageFile) async {
    // استخدمنا _messages عشان الشات يفضل ظاهر اثناء الرفع
    emit(TripChatLoaded(_messages)); 
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('trip_chats/$tripId/$fileName.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('trips').doc(tripId).collection('messages').add({
        'text': '', 
        'imageUrl': imageUrl,
        'audioUrl': '',
        'type': 'image',
        'senderId': currentUserId,
        'isRead': false, 
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      emit(TripChatError("خطأ في رفع الصورة: $e"));
    }
  }

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        String filePath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        isRecording = true;
        // 🟢 تحديث الـ State عشان المايك ينور، مع الاحتفاظ بالرسايل
        emit(TripChatLoaded(_messages));
        
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc), 
          path: filePath,
        );
      } else {
        emit(TripChatError("برجاء الموافقة على صلاحية الميكروفون للتسجيل"));
      }
    } catch (e) {
      isRecording = false;
      emit(TripChatLoaded(_messages));
      emit(TripChatError("خطأ أثناء بدء التسجيل: $e"));
    }
  }

  Future<void> stopRecordingAndSend(String tripId) async {
    try {
      final path = await _audioRecorder.stop();
      isRecording = false;
      // 🟢 تحديث الـ State عشان المايك يرجع لزرار الإرسال
      emit(TripChatLoaded(_messages));
      
      if (path != null) {
        File audioFile = File(path);
        if (await audioFile.exists()) {
          await _uploadAndSendAudio(tripId, audioFile);
        }
      }
    } catch (e) {
      emit(TripChatError("خطأ أثناء إيقاف التسجيل: $e"));
    }
  }

  Future<void> cancelRecording() async {
    try {
      await _audioRecorder.stop(); 
      isRecording = false;
      // 🟢 تحديث الـ State لإلغاء المايك
      emit(TripChatLoaded(_messages));
    } catch (e) {
      emit(TripChatError("خطأ أثناء الإلغاء: $e"));
    }
  }

  Future<void> _uploadAndSendAudio(String tripId, File audioFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('trip_chats/$tripId/audios/$fileName.m4a');
      
      UploadTask uploadTask = ref.putFile(audioFile);
      TaskSnapshot snapshot = await uploadTask;
      String audioUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('trips').doc(tripId).collection('messages').add({
        'text': '', 
        'imageUrl': '',
        'audioUrl': audioUrl,
        'type': 'audio',
        'senderId': currentUserId,
        'isRead': false, 
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      emit(TripChatError("خطأ في رفع ملف الصوت: $e"));
    }
  }

  Future<void> sendContactMessage(String tripId, String name, String phone) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).collection('messages').add({
        'text': '', 
        'imageUrl': '',
        'audioUrl': '',
        'type': 'contact',
        'contactName': name,
        'contactPhone': phone,
        'senderId': currentUserId,
        'isRead': false, 
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      emit(TripChatError("خطأ في إرسال جهة الاتصال: $e"));
    }
  }

  Future<void> markMessagesAsRead(String tripId, List<QueryDocumentSnapshot> docs) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    bool hasUpdates = false;

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data['senderId'] != currentUserId && (data['isRead'] == null || data['isRead'] == false)) {
        batch.update(doc.reference, {'isRead': true});
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }
}