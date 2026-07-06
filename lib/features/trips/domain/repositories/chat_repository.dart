import 'dart:io';
import '../entities/chat_message_entity.dart';

abstract class ChatRepository {
  Stream<List<ChatMessageEntity>> getMessagesStream(String tripId, int limit);
  
  Future<void> sendTextMessage({required String tripId, required String senderId, required String text});
  Future<void> sendImageMessage({required String tripId, required String senderId, required File imageFile});
  Future<void> sendAudioMessage({required String tripId, required String senderId, required File audioFile});
  Future<void> markMessagesAsRead({required String tripId, required String currentUserId});
}