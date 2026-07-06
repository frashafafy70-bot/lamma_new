enum MessageType { text, image, audio }

class ChatMessageEntity {
  final String id;
  final String senderId;
  final String text;
  final MessageType type;
  final String? imageUrl;
  final String? audioUrl;
  final DateTime? timestamp;
  final bool isRead;

  ChatMessageEntity({
    required this.id,
    required this.senderId,
    required this.text,
    this.type = MessageType.text,
    this.imageUrl,
    this.audioUrl,
    this.timestamp,
    this.isRead = false,
  });
}