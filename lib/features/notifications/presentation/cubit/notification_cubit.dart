import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'notification_state.dart';
import 'package:lamma_new/features/notifications/domain/use_cases/get_notifications_use_case.dart';
class NotificationCubit extends Cubit<NotificationState> {
  final GetNotificationsUseCase _getNotificationsUseCase;
  StreamSubscription? _notificationSubscription;

  NotificationCubit({required GetNotificationsUseCase getNotificationsUseCase})
      : _getNotificationsUseCase = getNotificationsUseCase,
        super(NotificationState());

  void startListeningToNotifications(String userId) {
    if (userId.isEmpty) return;

    emit(state.copyWith(status: NotificationStatus.loading));

    _notificationSubscription?.cancel();
    
    // 🟢 الكيوبت بيسمع للـ Stream النقي اللي جاي من الـ UseCase
    _notificationSubscription = _getNotificationsUseCase(userId).listen(
      (eitherResult) {
        if (isClosed) return;

        eitherResult.fold(
          (failure) {
            emit(state.copyWith(
              status: NotificationStatus.error,
              errorMessage: failure.message,
            ));
          },
          (notificationsList) {
            // حساب الإشعارات الغير مقروءة
            int unreadCount = notificationsList.where((n) => n.isRead == false).length;

            emit(state.copyWith(
              status: NotificationStatus.loaded,
              notifications: notificationsList,
              unreadNotificationsCount: unreadCount,
              hasNewNotification: unreadCount > 0,
            ));
          },
        );
      },
    );
  }

  void markAllNotificationsAsRead() {
    emit(state.copyWith(unreadNotificationsCount: 0, hasNewNotification: false));
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
}