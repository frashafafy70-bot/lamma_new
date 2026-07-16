import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';

import '../domain/use_cases/login_use_case.dart'; 
import '../domain/use_cases/sign_up_use_case.dart'; 
import '../domain/use_cases/sign_out_use_case.dart'; 
import '../domain/use_cases/auth_advanced_use_cases.dart'; 
import '../domain/repositories/auth_repository.dart'; 

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final LoginWithGoogleUseCase loginWithGoogleUseCase;
  final SendSignUpOtpUseCase sendSignUpOtpUseCase;
  final VerifyOtpAndSignUpUseCase verifyOtpAndSignUpUseCase;
  final AuthRepository authRepository; 

  AuthCubit({
    required this.loginUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.loginWithGoogleUseCase,
    required this.sendSignUpOtpUseCase,
    required this.verifyOtpAndSignUpUseCase,
    required this.authRepository, 
  }) : super(AuthInitial());

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    final result = await loginUseCase.call(email: email, password: password);
    
    if (isClosed) return;
    
    result.fold(
      (error) => emit(AuthError(error)),
      (user) => emit(AuthSuccess('تم تسجيل الدخول بنجاح! 🎉', uid: user.uid, role: user.role)),
    );
  }
  
  Future<void> signUp({required String email, required String password, required String name, required String phone}) async {
    emit(AuthLoading());
    final result = await signUpUseCase.call(email: email, password: password, name: name, phone: phone);
    
    if (isClosed) return;
    
    result.fold(
      (error) => emit(AuthError(error)),
      (user) => emit(AuthSuccess('تم إنشاء الحساب بنجاح! 🚀', uid: user.uid)),
    );
  }

  Future<void> loginWithGoogle() async {
    emit(AuthLoading());
    final result = await loginWithGoogleUseCase.call();
    
    if (isClosed) return;
    
    result.fold(
      (error) => emit(AuthError('فشل تسجيل الدخول: $error')),
      (user) => emit(AuthSuccess('تم تسجيل الدخول بجوجل بنجاح! 🎉', uid: user.uid)),
    );
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    final result = await signOutUseCase.call();
    
    if (isClosed) return;
    
    result.fold(
      (error) => emit(AuthError(error)),
      (_) => emit(AuthLoggedOut()),
    );
  }

  Future<void> sendSignUpOtp({required String phone}) async {
    emit(AuthLoading());
    
    String formattedPhoneNumber = phone.trim();
    if (formattedPhoneNumber.startsWith('0')) formattedPhoneNumber = formattedPhoneNumber.substring(1);
    if (!formattedPhoneNumber.startsWith('+20')) formattedPhoneNumber = '+20$formattedPhoneNumber';

    final result = await sendSignUpOtpUseCase.call(
      phone: formattedPhoneNumber,
      onCodeSent: (verificationId) {
        if (!isClosed) emit(AuthOtpSent(verificationId));
      },
      onError: (error) {
        if (!isClosed) emit(AuthError(error));
      },
    );

    if (isClosed) return;
    
    result.fold(
      (error) => emit(AuthError(error)),
      (_) {}, // لا نفعل شيئاً هنا لأن الـ callback (onCodeSent) هو من سيقوم بتغيير الحالة
    );
  }

  Future<void> verifyOtpAndCompleteSignUp({
    required String verificationId, required String smsCode, required String email, required String password,
    required String name, required String phone, required String role, String? nationalId, File? idFrontImage,
    File? idBackImage, File? professionImage, File? carLicenseFrontImage, File? carLicenseBackImage,
  }) async {
    emit(AuthLoading());
    
    String formattedPhoneNumber = phone.trim();
    if (formattedPhoneNumber.startsWith('0')) formattedPhoneNumber = formattedPhoneNumber.substring(1);
    if (!formattedPhoneNumber.startsWith('+20')) formattedPhoneNumber = '+20$formattedPhoneNumber';

    final result = await verifyOtpAndSignUpUseCase.call(
      verificationId: verificationId, smsCode: smsCode, email: email, password: password, name: name, phone: formattedPhoneNumber, role: role,
      nationalId: nationalId, idFrontImage: idFrontImage, idBackImage: idBackImage, professionImage: professionImage,
      carLicenseFrontImage: carLicenseFrontImage, carLicenseBackImage: carLicenseBackImage,
    );
    
    if (isClosed) return;
    
    result.fold(
      (error) => emit(AuthError(error)), // لو حصل خطأ سواء في التفعيل أو الرفع
      (user) => emit(AuthSuccess('تم إنشاء وتفعيل حسابك بنجاح! 🎉🚀', uid: user.uid, role: role)),
    );
  }

  Future<void> verifyOtp({required String verificationId, required String smsCode}) async {
    emit(AuthLoading());
    
    final result = await authRepository.verifyOtpAndCheckUser(
      verificationId: verificationId, 
      smsCode: smsCode,
    );
    
    if (isClosed) return;
    
    result.fold(
      (error) => emit(AuthError(error)),
      (userEntity) {
        if (userEntity != null) {
          emit(AuthSuccess('تم تسجيل الدخول بنجاح', uid: userEntity.uid, role: userEntity.role));
        } else {
          emit(const AuthNeedsPasswordAndProfile());
        }
      }
    );
  }

  Future<void> completeRegistration({
    required String email, required String password, required String name, required String phone, required String role,
    String? nationalId, File? idFrontImage, File? idBackImage, File? professionImage, File? carLicenseFrontImage, File? carLicenseBackImage,
  }) async {
    emit(AuthLoading());
    
    String formattedPhoneNumber = phone.trim();
    if (formattedPhoneNumber.startsWith('0')) formattedPhoneNumber = formattedPhoneNumber.substring(1);
    if (!formattedPhoneNumber.startsWith('+20')) formattedPhoneNumber = '+20$formattedPhoneNumber';

    final result = await authRepository.completeRegistration(
      email: email, password: password, name: name, phone: formattedPhoneNumber, role: role,
      nationalId: nationalId, idFrontImage: idFrontImage, idBackImage: idBackImage, professionImage: professionImage,
      carLicenseFrontImage: carLicenseFrontImage, carLicenseBackImage: carLicenseBackImage,
    );
    
    if (isClosed) return;
    
    result.fold(
      (error) => emit(AuthError(error)),
      (user) => emit(AuthSuccess('تم إنشاء وتفعيل حسابك بنجاح! 🎉🚀', uid: user.uid, role: role)),
    );
  }

  Future<void> sendPasswordResetOtp({required String phone}) async {
    emit(AuthLoading());
    
    final result = await authRepository.sendSignUpOtp(
      phone: phone,
      onCodeSent: (verificationId) {
        if (!isClosed) emit(AuthOtpSent(verificationId));
      },
      onError: (error) {
        if (!isClosed) emit(AuthError(error));
      },
    );

    if (isClosed) return;
    
    result.fold(
      (error) => emit(AuthError(error)),
      (_) {}, // يتم التعامل مع النجاح عبر callback
    );
  }

  Future<void> verifyOtpAndResetPassword({required String verificationId, required String smsCode, required String newPassword}) async {
    emit(AuthLoading());
    
    final result = await authRepository.verifyOtpAndResetPassword(verificationId: verificationId, smsCode: smsCode, newPassword: newPassword);
    
    if (isClosed) return;
    
    result.fold(
      (error) => emit(AuthError(error)),
      (_) async {
        await signOutUseCase.call(); // تأكيد تسجيل الخروج بعد تغيير الباسورد
        if (!isClosed) emit(const AuthSuccess('تم تحديث كلمة المرور بنجاح. يرجى تسجيل الدخول.'));
      }
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    emit(AuthLoading());
    
    final result = await authRepository.resetPassword(email);
    
    if (isClosed) return;
    
    result.fold(
      (error) => emit(AuthError(error)),
      (_) => emit(const AuthSuccess('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني بنجاح 📧')),
    );
  }
}