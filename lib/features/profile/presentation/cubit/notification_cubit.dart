import 'package:flutter_bloc/flutter_bloc.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit() : super(NotificationState());

  void markAllNotificationsAsRead() {
    emit(
        state.copyWith(unreadNotificationsCount: 0, hasNewNotification: false));
  }
}
