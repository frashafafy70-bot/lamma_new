import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

// 🟢 تم تعديل المسار ليكون صحيحاً (../../ بدلاً من ../../../)
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

part 'trip_chat_state.dart';

class TripChatCubit extends Cubit<TripChatState> {
  final ChatRepository chatRepository; 
  
  StreamSubscription<RemoteMessage>? _notificationSubscription;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  StreamSubscription? _chatSubscription;
  bool isRecording = false;
  
  List<ChatMessageEntity> _messages = [];
  
  int _messageLimit = 20;
  bool isLoadingMore = false;

  TripChatCubit({required this.chatRepository}) : super(TripChatInitial()) {
    _listenToChatNotifications();
  }

  void _listenToChatNotifications() {
    _notificationSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'chat') {
        debugPrint("💬 [TripChatCubit] رسالة جديدة وصلت لايف: ${message.notification?.body}");
      }
    });
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    _audioRecorder.dispose();
    _chatSubscription?.cancel();
    return super.close();
  }

  void loadChat(String tripId) {
    if (_messages.isEmpty) emit(TripChatLoading());
    
    _chatSubscription?.cancel();
    _chatSubscription = chatRepository.getMessagesStream(tripId, _messageLimit).listen(
      (messages) {
        _messages = messages;
        chatRepository.markMessagesAsRead(tripId: tripId, currentUserId: currentUserId);
        isLoadingMore = false;
        emit(TripChatLoaded(List.from(_messages)));
      }, 
      onError: (error) {
        emit(TripChatError("خطأ في جلب الرسائل: $error"));
      }
    );
  }

  void loadMoreMessages(String tripId) {
    if (isLoadingMore) return;
    isLoadingMore = true;
    _messageLimit += 20;
    loadChat(tripId);
  }

  Future<void> sendMessage(String tripId, String senderId, String text) async {
    if (text.trim().isEmpty) return;
    try {
      await chatRepository.sendTextMessage(
        tripId: tripId, 
        senderId: senderId, 
        text: text.trim()
      );
    } catch (e) {
      emit(TripChatError("خطأ في إرسال الرسالة: $e"));
    }
  }

  Future<void> sendImageMessage(String tripId, File imageFile) async {
    emit(TripChatLoaded(List.from(_messages))); 
    try {
      await chatRepository.sendImageMessage(
        tripId: tripId, 
        senderId: currentUserId, 
        imageFile: imageFile
      );
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
        emit(TripChatLoaded(List.from(_messages)));
        
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc), 
          path: filePath,
        );
      } else {
        emit(TripChatError("برجاء الموافقة على صلاحية الميكروفون للتسجيل"));
      }
    } catch (e) {
      isRecording = false;
      emit(TripChatLoaded(List.from(_messages)));
      emit(TripChatError("خطأ أثناء بدء التسجيل: $e"));
    }
  }

  Future<void> stopRecordingAndSend(String tripId) async {
    try {
      final path = await _audioRecorder.stop();
      isRecording = false;
      emit(TripChatLoaded(List.from(_messages)));
      
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
      emit(TripChatLoaded(List.from(_messages)));
    } catch (e) {
      emit(TripChatError("خطأ أثناء الإلغاء: $e"));
    }
  }

  Future<void> _uploadAndSendAudio(String tripId, File audioFile) async {
    try {
      await chatRepository.sendAudioMessage(
        tripId: tripId, 
        senderId: currentUserId, 
        audioFile: audioFile
      );
    } catch (e) {
      emit(TripChatError("خطأ في رفع ملف الصوت: $e"));
    }
  }
}