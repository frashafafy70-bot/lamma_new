enum NotificationStatus { initial, loaded, error }

class NotificationState {
  final NotificationStatus status;
  final bool hasNewNotification;
  final int unreadNotificationsCount;
  final String? errorMessage;

  NotificationState({
    this.status = NotificationStatus.initial,
    this.hasNewNotification = false,
    this.unreadNotificationsCount = 0,
    this.errorMessage,
  });

  NotificationState copyWith({
    NotificationStatus? status,
    bool? hasNewNotification,
    int? unreadNotificationsCount,
    String? errorMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      hasNewNotification: hasNewNotification ?? this.hasNewNotification,
      unreadNotificationsCount: unreadNotificationsCount ?? this.unreadNotificationsCount,
      errorMessage: errorMessage,
    );
  }
}