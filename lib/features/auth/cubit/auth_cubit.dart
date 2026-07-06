import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';
import '../domain/use_cases/login_use_case.dart'; // افترض إنك عملته قبل كده
import '../domain/use_cases/sign_up_use_case.dart'; // افترض إنك عملته قبل كده
import '../domain/use_cases/sign_out_use_case.dart'; // افترض إنك عملته قبل كده
import '../domain/use_cases/auth_advanced_use_cases.dart'; // الملف اللي لسه عاملينه

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final LoginWithGoogleUseCase loginWithGoogleUseCase;
  final SendSignUpOtpUseCase sendSignUpOtpUseCase;
  final VerifyOtpAndSignUpUseCase verifyOtpAndSignUpUseCase;

  AuthCubit({
    required this.loginUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.loginWithGoogleUseCase,
    required this.sendSignUpOtpUseCase,
    required this.verifyOtpAndSignUpUseCase,
  }) : super(AuthInitial());

  Future<void> signUp({required String email, required String password, required String name, required String phone}) async {
    emit(AuthLoading());
    try {
      final user = await signUpUseCase.call(email: email, password: password, name: name, phone: phone);
      emit(AuthSuccess('تم إنشاء الحساب بنجاح!', uid: user.uid));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    try {
      final user = await loginUseCase.call(email: email, password: password);
      emit(AuthSuccess('تم تسجيل الدخول بنجاح!', uid: user.uid));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await signOutUseCase.call();
      emit(AuthLoggedOut());
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> loginWithGoogle() async {
    emit(AuthLoading());
    try {
      final user = await loginWithGoogleUseCase.call();
      emit(AuthSuccess('تم تسجيل الدخول بجوجل بنجاح! 🎉', uid: user.uid));
    } catch (e) {
      emit(AuthError('فشل تسجيل الدخول بجوجل ❌: ${e.toString().replaceAll('Exception: ', '')}'));
    }
  }

  Future<void> sendSignUpOtp({required String phone}) async {
    emit(AuthLoading());
    try {
      await sendSignUpOtpUseCase.call(
        phone: phone,
        onCodeSent: (verificationId) => emit(AuthOtpSent(verificationId)),
        onError: (error) => emit(AuthError(error)),
      );
    } catch (e) {
      emit(AuthError('حدث خطأ: ${e.toString().replaceAll('Exception: ', '')}'));
    }
  }

  Future<void> verifyOtpAndCompleteSignUp({
    required String verificationId, required String smsCode, required String email, required String password,
    required String name, required String phone, required String role, String? nationalId, File? idFrontImage,
    File? idBackImage, File? professionImage, File? carLicenseFrontImage, File? carLicenseBackImage,
  }) async {
    emit(AuthLoading());
    try {
      final user = await verifyOtpAndSignUpUseCase.call(
        verificationId: verificationId, smsCode: smsCode, email: email, password: password, name: name, phone: phone, role: role,
        nationalId: nationalId, idFrontImage: idFrontImage, idBackImage: idBackImage, professionImage: professionImage,
        carLicenseFrontImage: carLicenseFrontImage, carLicenseBackImage: carLicenseBackImage,
      );
      emit(AuthSuccess('تم إنشاء وتفعيل حسابك بنجاح مئة بالمئة! 🎉🚀', uid: user.uid));
    } catch (e) {
      emit(AuthError('كود الـ OTP المدخل غير صحيح أو حدث خطأ ❌'));
    }
  }
}