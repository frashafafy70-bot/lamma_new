part of 'trip_chat_cubit.dart';

@immutable
abstract class TripChatState {}

class TripChatInitial extends TripChatState {}

// 🟢 حالة التحميل (تظهر أول ما نفتح الشات لسه بنجيب الداتا)
class TripChatLoading extends TripChatState {}

// 🟢 حالة نجاح جلب الرسائل (ودي اللي هنعتمد عليها عشان الشات يفضل ظاهر)
class TripChatLoaded extends TripChatState {
  final List<Map<String, dynamic>> messages;
  TripChatLoaded(this.messages);
}

// 🟢 حالات إضافية يمكن استخدامها لعمل Loading مصغر أثناء إرسال صورة أو صوت
class TripChatSending extends TripChatState {}

class TripChatSentSuccess extends TripChatState {}

// 🟢 حالة تغير وضع التسجيل (رغم إننا بنندل التسجيل داخل Cubit بمتغير isRecording)
class TripChatRecordingStatusChanged extends TripChatState {
  final bool isRecording;
  TripChatRecordingStatusChanged(this.isRecording);
}

// 🟢 حالة الخطأ (تستخدم لإظهار رسالة للمستخدم لو فشل الإرسال أو التسجيل)
class TripChatError extends TripChatState {
  final String error;
  TripChatError(this.error);
}