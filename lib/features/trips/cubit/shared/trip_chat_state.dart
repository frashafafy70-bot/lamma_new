part of 'trip_chat_cubit.dart';

@immutable
abstract class TripChatState {}

class TripChatInitial extends TripChatState {}

// 🟢 حالة التحميل
class TripChatLoading extends TripChatState {}

// 🟢 حالة نجاح جلب الرسائل (تم تعديلها لتستقبل الكيان النظيف)
class TripChatLoaded extends TripChatState {
  final List<ChatMessageEntity> messages;
  TripChatLoaded(this.messages);
}

class TripChatSending extends TripChatState {}

class TripChatSentSuccess extends TripChatState {}

class TripChatRecordingStatusChanged extends TripChatState {
  final bool isRecording;
  TripChatRecordingStatusChanged(this.isRecording);
}

class TripChatError extends TripChatState {
  final String error;
  TripChatError(this.error);
}