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
      errorMessage: errorMessage, // يتم تمريرها مباشرة لتسهيل تصفير الخطأ عند الحاجة
      successMessage: successMessage, // يتم تمريرها مباشرة لتسهيل تصفير رسائل النجاح
    );
  }
}