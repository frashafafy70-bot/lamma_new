class NotificationState {
  final int unreadNotificationsCount;
  final bool hasNewNotification;

  NotificationState({
    this.unreadNotificationsCount = 0,
    this.hasNewNotification = false,
  });

  NotificationState copyWith(
      {int? unreadNotificationsCount, bool? hasNewNotification}) {
    return NotificationState(
      unreadNotificationsCount:
          unreadNotificationsCount ?? this.unreadNotificationsCount,
      hasNewNotification: hasNewNotification ?? this.hasNewNotification,
    );
  }
}
