import 'package:flutter_bloc/flutter_bloc.dart';
// متنساش تتأكد إن مسار الـ import ده مطابق لمكان الملف عندك
import '../../domain/use_cases/login_use_case.dart';

// ----------------------------------------------------
// [ Login States ]
// ----------------------------------------------------
abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final String uid;
  LoginSuccess({required this.uid});
}

class LoginError extends LoginState {
  final String errorMessage;
  LoginError({required this.errorMessage});
}

// ----------------------------------------------------
// [ Login Cubit ]
// ----------------------------------------------------
class LoginCubit extends Cubit<LoginState> {
  // حقن (Injection) للـ UseCase بدل استخدام الفايربيس مباشرة
  final LoginUseCase loginUseCase;

  // بنطلب الـ UseCase في الـ Constructor
  LoginCubit({required this.loginUseCase}) : super(LoginInitial());

  Future<void> loginUser(
      {required String email, required String password}) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      emit(LoginError(
          errorMessage: 'برجاء إدخال البريد الإلكتروني وكلمة المرور'));
      return;
    }

    emit(LoginLoading());

    try {
      // بننادي على الـ UseCase اللي بدورها بتكلم الـ Repository
      final user = await loginUseCase.call(
        email: email.trim(),
        password: password.trim(),
      );

      // لو العملية نجحت، بنبعت الـ uid للـ UI
      emit(LoginSuccess(uid: user.uid));
    } catch (e) {
      // بناخد رسالة الخطأ اللي جاية من الـ AuthService بتاعتك
      String errorMessage = e.toString();

      // تنظيف الرسالة لو بتبدأ بكلمة Exception: عشان شكلها يكون حلو للمستخدم
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }

      emit(LoginError(errorMessage: errorMessage));
    }
  }
}
