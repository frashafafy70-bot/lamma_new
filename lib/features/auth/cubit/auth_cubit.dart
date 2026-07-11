import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
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

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني.';
      case 'wrong-password': return 'كلمة المرور غير صحيحة.';
      case 'email-already-in-use': return 'هذا البريد الإلكتروني مسجل مسبقاً.';
      case 'weak-password': return 'كلمة المرور ضعيفة جداً.';
      case 'invalid-email': return 'صيغة البريد الإلكتروني غير صحيحة.';
      case 'network-request-failed': return 'يرجى التحقق من اتصالك بالإنترنت.';
      case 'invalid-credential': return 'بيانات الدخول غير صحيحة.';
      default: return 'حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.';
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    try {
      final user = await loginUseCase.call(email: email, password: password);
      if (isClosed) return;
      final role = (user as dynamic).role;
      emit(AuthSuccess('تم تسجيل الدخول بنجاح! 🎉', uid: user.uid, role: role));
    } on FirebaseAuthException catch (e) {
      if (isClosed) return;
      emit(AuthError(_mapFirebaseAuthError(e)));
    } catch (e) {
      if (isClosed) return;
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }
  
  Future<void> signUp({required String email, required String password, required String name, required String phone}) async {
    emit(AuthLoading());
    try {
      final user = await signUpUseCase.call(email: email, password: password, name: name, phone: phone);
      if (isClosed) return;
      emit(AuthSuccess('تم إنشاء الحساب بنجاح! 🚀', uid: user.uid));
    } on FirebaseAuthException catch (e) {
      if (isClosed) return;
      emit(AuthError(_mapFirebaseAuthError(e)));
    } catch (e) {
      if (isClosed) return;
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> loginWithGoogle() async {
    emit(AuthLoading());
    try {
      final user = await loginWithGoogleUseCase.call();
      if (isClosed) return;
      emit(AuthSuccess('تم تسجيل الدخول بجوجل بنجاح! 🎉', uid: user.uid));
    } on FirebaseAuthException catch (e) {
      if (isClosed) return;
      emit(AuthError('فشل تسجيل الدخول: ${_mapFirebaseAuthError(e)}'));
    } catch (e) {
      if (isClosed) return;
      emit(AuthError('فشل تسجيل الدخول بجوجل ❌: ${e.toString().replaceAll('Exception: ', '')}'));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await signOutUseCase.call();
      if (isClosed) return;
      emit(AuthLoggedOut());
    } catch (e) {
      if (isClosed) return;
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> sendSignUpOtp({required String phone}) async {
    emit(AuthLoading());
    try {
      String formattedPhoneNumber = phone.trim();
      if (formattedPhoneNumber.startsWith('0')) formattedPhoneNumber = formattedPhoneNumber.substring(1);
      if (!formattedPhoneNumber.startsWith('+20')) formattedPhoneNumber = '+20$formattedPhoneNumber';

      await sendSignUpOtpUseCase.call(
        phone: formattedPhoneNumber,
        onCodeSent: (verificationId) {
          if (!isClosed) emit(AuthOtpSent(verificationId));
        },
        onError: (error) {
          if (!isClosed) emit(AuthError(error));
        },
      );
    } catch (e) {
      if (isClosed) return;
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
      String formattedPhoneNumber = phone.trim();
      if (formattedPhoneNumber.startsWith('0')) formattedPhoneNumber = formattedPhoneNumber.substring(1);
      if (!formattedPhoneNumber.startsWith('+20')) formattedPhoneNumber = '+20$formattedPhoneNumber';

      final user = await verifyOtpAndSignUpUseCase.call(
        verificationId: verificationId, smsCode: smsCode, email: email, password: password, name: name, phone: formattedPhoneNumber, role: role,
        nationalId: nationalId, idFrontImage: idFrontImage, idBackImage: idBackImage, professionImage: professionImage,
        carLicenseFrontImage: carLicenseFrontImage, carLicenseBackImage: carLicenseBackImage,
      );
      
      if (isClosed) return;
      emit(AuthSuccess('تم إنشاء وتفعيل حسابك بنجاح! 🎉🚀', uid: user.uid, role: role));
    } on FirebaseAuthException catch (e) {
      if (isClosed) return;
      emit(AuthError('خطأ أثناء التفعيل: ${_mapFirebaseAuthError(e)}'));
    } catch (e) {
      if (isClosed) return;
      emit(const AuthError('كود الـ OTP المدخل غير صحيح أو حدث خطأ ❌'));
    }
  }

  Future<void> verifyOtp({required String verificationId, required String smsCode}) async {
    emit(AuthLoading());
    try {
      final userEntity = await authRepository.verifyOtpAndCheckUser(
        verificationId: verificationId, 
        smsCode: smsCode,
      );
      
      if (isClosed) return;
      if (userEntity != null) {
        final role = (userEntity as dynamic).role;
        emit(AuthSuccess('تم تسجيل الدخول بنجاح', uid: userEntity.uid, role: role));
      } else {
        emit(const AuthNeedsPasswordAndProfile());
      }
    } catch (e) {
      if (isClosed) return;
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> completeRegistration({
    required String email, required String password, required String name, required String phone, required String role,
    String? nationalId, File? idFrontImage, File? idBackImage, File? professionImage, File? carLicenseFrontImage, File? carLicenseBackImage,
  }) async {
    emit(AuthLoading());
    try {
      String formattedPhoneNumber = phone.trim();
      if (formattedPhoneNumber.startsWith('0')) formattedPhoneNumber = formattedPhoneNumber.substring(1);
      if (!formattedPhoneNumber.startsWith('+20')) formattedPhoneNumber = '+20$formattedPhoneNumber';

      final user = await authRepository.completeRegistration(
        email: email, password: password, name: name, phone: formattedPhoneNumber, role: role,
        nationalId: nationalId, idFrontImage: idFrontImage, idBackImage: idBackImage, professionImage: professionImage,
        carLicenseFrontImage: carLicenseFrontImage, carLicenseBackImage: carLicenseBackImage,
      );
      
      if (isClosed) return;
      emit(AuthSuccess('تم إنشاء وتفعيل حسابك بنجاح! 🎉🚀', uid: user.uid, role: role));
    } on FirebaseAuthException catch (e) {
      if (isClosed) return;
      emit(AuthError(_mapFirebaseAuthError(e)));
    } catch (e) {
      if (isClosed) return;
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> sendPasswordResetOtp({required String phone}) async {
    emit(AuthLoading());
    try {
      await authRepository.sendSignUpOtp(
        phone: phone,
        onCodeSent: (verificationId) {
          if (!isClosed) emit(AuthOtpSent(verificationId));
        },
        onError: (error) {
          if (!isClosed) emit(AuthError(error));
        },
      );
    } catch (e) {
      if (isClosed) return;
      emit(AuthError('حدث خطأ: ${e.toString().replaceAll('Exception: ', '')}'));
    }
  }

  Future<void> verifyOtpAndResetPassword({required String verificationId, required String smsCode, required String newPassword}) async {
    emit(AuthLoading());
    try {
      await authRepository.verifyOtpAndResetPassword(verificationId: verificationId, smsCode: smsCode, newPassword: newPassword);
      await signOutUseCase.call(); 
      if (isClosed) return;
      emit(const AuthSuccess('تم تحديث كلمة المرور بنجاح. يرجى تسجيل الدخول.'));
    } catch (e) {
      if (isClosed) return;
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    emit(AuthLoading());
    try {
      await authRepository.resetPassword(email);
      if (isClosed) return;
      emit(const AuthSuccess('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني بنجاح 📧'));
    } on FirebaseAuthException catch (e) {
      if (isClosed) return;
      emit(AuthError(_mapFirebaseAuthError(e)));
    } catch (e) {
      if (isClosed) return;
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}