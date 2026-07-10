import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  // 🟢 اشتراك الستريم لمراقبة الإشعارات لايف
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  NotificationCubit() : super(NotificationState());

  // 🟢 دالة فتح الستريم وجلب الإشعارات
  void startListeningToNotifications(String userId) {
    if (userId.isEmpty) return;

    emit(state.copyWith(status: NotificationStatus.loading));

    _notificationSubscription?.cancel();
    _notificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        // تحويل الداتا لـ List of Maps
        final notificationsList = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // حفظ الـ ID لو احتجناه
          return data;
        }).toList();

        // حساب عدد الإشعارات غير المقروءة (لو عندك حقل isRead في الفايربيز تقدر تفلتر بيه هنا)
        // int unreadCount = notificationsList.where((n) => n['isRead'] == false).length;

        emit(state.copyWith(
          status: NotificationStatus.loaded,
          notifications: notificationsList,
          // unreadNotificationsCount: unreadCount, // لو مفعل الحقل ده
        ));
      },
      onError: (error) {
        emit(state.copyWith(
          status: NotificationStatus.error,
          errorMessage: 'حدث خطأ في جلب الإشعارات',
        ));
      },
    );
  }

  void markAllNotificationsAsRead() {
    emit(state.copyWith(unreadNotificationsCount: 0, hasNewNotification: false));
  }

  // 🟢 تنظيف الذاكرة
  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
}