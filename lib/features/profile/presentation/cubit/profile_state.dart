enum ProfileStatus { initial, loading, loaded, error }

enum ProfileActionStatus {
  initial,
  loading,
  success,
  error,
  registrationRequired
}

class ProfileState {
  final ProfileStatus status;
  final ProfileActionStatus actionStatus;
  final String userName;
  final String userEmail;
  final String? userPhone;
  final String? nationalId;
  final String profileImageUrl;
  final String activeRole;
  final List<String> userRoles;
  final String? errorMessage;
  final String? successMessage;
  final String? pendingRegistrationRole;

  ProfileState({
    this.status = ProfileStatus.initial,
    this.actionStatus = ProfileActionStatus.initial,
    this.userName = '',
    this.userEmail = '',
    this.userPhone,
    this.nationalId,
    this.profileImageUrl = '',
    this.activeRole = 'client', // القيمة الافتراضية
    this.userRoles = const ['client'],
    this.errorMessage,
    this.successMessage,
    this.pendingRegistrationRole,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileActionStatus? actionStatus,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? nationalId,
    String? profileImageUrl,
    String? activeRole,
    List<String>? userRoles,
    String? errorMessage,
    String? successMessage,
    String? pendingRegistrationRole,
  }) {
    return ProfileState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      nationalId: nationalId ?? this.nationalId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      activeRole: activeRole ?? this.activeRole,
      userRoles: userRoles ?? this.userRoles,
      errorMessage: errorMessage,
      successMessage: successMessage,
      pendingRegistrationRole: pendingRegistrationRole,
    );
  }
}
