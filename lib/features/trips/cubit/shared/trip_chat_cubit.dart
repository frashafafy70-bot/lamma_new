import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

part 'trip_chat_state.dart';

class TripChatCubit extends Cubit<TripChatState> {
  final ChatRepository chatRepository;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  StreamSubscription? _chatSubscription;
  bool isRecording = false;

  List<ChatMessageEntity> _messages = [];

  int _messageLimit = 20;
  bool isLoadingMore = false;

  TripChatCubit({required this.chatRepository}) : super(TripChatInitial());

  // ==========================================
  // 🟢 الدوال تم تنظيفها وعزلها عن Firestore
  // ==========================================

  Future<Map<String, String>> getOtherPartyInfo(String tripId) async {
    try {
      // بنكلم الـ Repo النظيف بدل ما كنا بنكلم Firestore مباشرة
      return await chatRepository.getOtherPartyInfo(
          tripId: tripId, currentUserId: currentUserId);
    } catch (e) {
      debugPrint("خطأ في جلب بيانات الطرف الآخر: $e");
      return {'name': 'غير معروف', 'phone': ''};
    }
  }

  Future<void> sendNotificationToOtherParty(
      {required String tripId, required String message}) async {
    try {
      if (isClosed) return;
      // بنكلم الـ Repo لإرسال الإشعار
      await chatRepository.sendChatNotification(
          tripId: tripId, message: message);
      debugPrint("🔔 إرسال إشعار بمحتوى: $message");
    } catch (e) {
      debugPrint("Error sending notification: $e");
    }
  }

  @override
  Future<void> close() {
    _audioRecorder.dispose();
    _chatSubscription?.cancel();
    return super.close();
  }

  void loadChat(String tripId) {
    if (_messages.isEmpty) emit(TripChatLoading());

    _chatSubscription?.cancel();
    _chatSubscription = chatRepository
        .getMessagesStream(tripId, _messageLimit)
        .listen((messages) {
      if (isClosed) return;
      _messages = messages;
      chatRepository.markMessagesAsRead(
          tripId: tripId, currentUserId: currentUserId);
      isLoadingMore = false;
      emit(TripChatLoaded(List.from(_messages)));
    }, onError: (error) {
      if (isClosed) return;
      emit(TripChatError("خطأ في جلب الرسائل: $error"));
    });
  }

  void loadMoreMessages(String tripId) {
    if (isLoadingMore) return;
    isLoadingMore = true;
    _messageLimit += 20;
    loadChat(tripId);
  }

  Future<void> cancelRecording() async {
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
      isRecording = false;
      if (isClosed) return;
      emit(TripChatLoaded(List.from(_messages)));
    } catch (e) {
      if (isClosed) return;
      emit(TripChatError("خطأ أثناء إلغاء التسجيل: $e"));
    }
  }

  Future<void> sendMessage(String tripId, String senderId, String text) async {
    if (text.trim().isEmpty) return;
    try {
      await chatRepository.sendTextMessage(
          tripId: tripId, senderId: senderId, text: text.trim());
      await sendNotificationToOtherParty(tripId: tripId, message: text.trim());
    } catch (e) {
      if (isClosed) return;
      emit(TripChatError("خطأ في إرسال الرسالة: $e"));
    }
  }

  Future<void> sendImageMessage(String tripId, File imageFile) async {
    try {
      await chatRepository.sendImageMessage(
          tripId: tripId, senderId: currentUserId, imageFile: imageFile);
      await sendNotificationToOtherParty(
          tripId: tripId, message: "صورة جديدة 📸");
    } catch (e) {
      if (isClosed) return;
      emit(TripChatError("خطأ في رفع الصورة: $e"));
    }
  }

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        String filePath =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        isRecording = true;
        if (!isClosed) emit(TripChatLoaded(List.from(_messages)));

        await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: filePath);
      }
    } catch (e) {
      isRecording = false;
      if (isClosed) return;
      emit(TripChatLoaded(List.from(_messages)));
      emit(TripChatError("خطأ أثناء بدء التسجيل: $e"));
    }
  }

  Future<void> stopRecordingAndSend(String tripId) async {
    try {
      final path = await _audioRecorder.stop();
      isRecording = false;
      if (!isClosed) emit(TripChatLoaded(List.from(_messages)));

      if (path != null) {
        File audioFile = File(path);
        if (await audioFile.exists()) {
          await chatRepository.sendAudioMessage(
              tripId: tripId, senderId: currentUserId, audioFile: audioFile);
          await sendNotificationToOtherParty(
              tripId: tripId, message: "رسالة صوتية 🎙️");
        }
      }
    } catch (e) {
      if (isClosed) return;
      emit(TripChatError("خطأ أثناء إيقاف التسجيل: $e"));
    }
  }
}
