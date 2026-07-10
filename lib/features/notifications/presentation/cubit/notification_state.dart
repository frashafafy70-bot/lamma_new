enum NotificationStatus { initial, loading, loaded, error }

class NotificationState {
  final int unreadNotificationsCount;
  final bool hasNewNotification;
  
  // 🟢 المتغيرات الجديدة الخاصة بلستة الإشعارات
  final List<Map<String, dynamic>> notifications;
  final NotificationStatus status;
  final String? errorMessage;

  NotificationState({
    this.unreadNotificationsCount = 0,
    this.hasNewNotification = false,
    this.notifications = const [],
    this.status = NotificationStatus.initial,
    this.errorMessage,
  });

  NotificationState copyWith({
    int? unreadNotificationsCount,
    bool? hasNewNotification,
    List<Map<String, dynamic>>? notifications,
    NotificationStatus? status,
    String? errorMessage,
  }) {
    return NotificationState(
      unreadNotificationsCount: unreadNotificationsCount ?? this.unreadNotificationsCount,
      hasNewNotification: hasNewNotification ?? this.hasNewNotification,
      notifications: notifications ?? this.notifications,
      status: status ?? this.status,
      errorMessage: errorMessage, // بدون ?? عشان نقدر نصفره
    );
  }
}