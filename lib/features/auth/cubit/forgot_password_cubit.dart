import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ----------------------------------------------------
// [ States ]
// ----------------------------------------------------
abstract class ForgotPasswordState {}

class ForgotPasswordInitial extends ForgotPasswordState {}

class ForgotPasswordLoading extends ForgotPasswordState {}

class ForgotPasswordSuccess extends ForgotPasswordState {}

class ForgotPasswordError extends ForgotPasswordState {
  final String message;
  ForgotPasswordError({required this.message});
}

// ----------------------------------------------------
// [ Cubit ]
// ----------------------------------------------------
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit() : super(ForgotPasswordInitial());

  Future<void> resetPassword(String email) async {
    if (email.trim().isEmpty) {
      emit(ForgotPasswordError(message: 'برجاء إدخال البريد الإلكتروني'));
      return;
    }

    emit(ForgotPasswordLoading());

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      emit(ForgotPasswordSuccess());
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'حدث خطأ أثناء الإرسال، حاول مرة أخرى';
      if (e.code == 'user-not-found') {
        errorMessage = 'لا يوجد حساب مسجل بهذا البريد الإلكتروني';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'صيغة البريد الإلكتروني غير صحيحة';
      }
      emit(ForgotPasswordError(message: errorMessage));
    } catch (e) {
      emit(ForgotPasswordError(message: 'تأكد من اتصالك بالإنترنت وحاول مجدداً'));
    }
  }
}