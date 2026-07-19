import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String message;
  final String? uid;
  final String? role;

  const AuthSuccess(this.message, {this.uid, this.role});

  @override
  List<Object?> get props => [message, uid, role];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthOtpSent extends AuthState {
  final String verificationId;

  const AuthOtpSent(this.verificationId);

  @override
  List<Object?> get props => [verificationId];
}

// 🟢 الحالة الجديدة: للتوجه لصفحة إدخال الباسورد واسم المستخدم بعد نجاح الـ OTP
class AuthNeedsPasswordAndProfile extends AuthState {
  const AuthNeedsPasswordAndProfile();
}

class AuthLoggedOut extends AuthState {}
