enum HomeStatus { initial, loading, loaded, error }
enum HomeActionStatus { idle, loading, success, error, registrationRequired }

class HomeState {
  final int bottomNavIndex;
  final String userName;
  final String userEmail;
  final String profileImageUrl;
  final String activeRole;
  final HomeStatus status;
  final HomeActionStatus actionStatus;
  final String? pendingRegistrationRole;
  final String? errorMessage;
  final String? successMessage;
  final bool hasNewNotification; 
  final int unreadNotificationsCount; 
  final int activeOrdersCount; 

  HomeState({
    this.bottomNavIndex = 0,
    this.userName = 'جاري التحميل...',
    this.userEmail = '',
    this.profileImageUrl = '',
    this.activeRole = 'customer',
    this.status = HomeStatus.initial,
    this.actionStatus = HomeActionStatus.idle,
    this.pendingRegistrationRole,
    this.errorMessage,
    this.successMessage,
    this.hasNewNotification = false,
    this.unreadNotificationsCount = 0,
    this.activeOrdersCount = 0, 
  });

  HomeState copyWith({
    int? bottomNavIndex,
    String? userName,
    String? userEmail,
    String? profileImageUrl,
    String? activeRole,
    HomeStatus? status,
    HomeActionStatus? actionStatus,
    String? pendingRegistrationRole,
    String? errorMessage,
    String? successMessage,
    bool? hasNewNotification,
    int? unreadNotificationsCount,
    int? activeOrdersCount, 
  }) {
    return HomeState(
      bottomNavIndex: bottomNavIndex ?? this.bottomNavIndex,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      activeRole: activeRole ?? this.activeRole,
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      pendingRegistrationRole: pendingRegistrationRole ?? this.pendingRegistrationRole,
      errorMessage: errorMessage,
      successMessage: successMessage,
      hasNewNotification: hasNewNotification ?? this.hasNewNotification,
      unreadNotificationsCount: unreadNotificationsCount ?? this.unreadNotificationsCount,
      activeOrdersCount: activeOrdersCount ?? this.activeOrdersCount, 
    );
  }
}