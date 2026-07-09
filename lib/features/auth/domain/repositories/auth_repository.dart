import 'dart:io';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});
  
  Future<UserEntity> signUp({required String email, required String password, required String name, required String phone});
  
  Future<void> signOut();
  
  Future<UserEntity?> getUserData(String uid);
  
  Future<void> resetPassword(String email);
  
  Future<UserEntity> loginWithGoogle();
  
  Future<void> sendSignUpOtp({
    required String phone, 
    required Function(String) onCodeSent, 
    required Function(String) onError
  });

  // الدالة القديمة اللي الـ UI بيعتمد عليها حالياً
  Future<UserEntity> verifyOtpAndCompleteSignUp({
    required String verificationId, 
    required String smsCode, 
    required String email, 
    required String password, 
    required String name,
    required String phone, 
    required String role, 
    String? nationalId, 
    File? idFrontImage, 
    File? idBackImage,
    File? professionImage, 
    File? carLicenseFrontImage, 
    File? carLicenseBackImage,
  });

  Future<UserEntity?> verifyOtpAndCheckUser({
    required String verificationId, 
    required String smsCode,
  });

  Future<UserEntity> completeRegistration({
    required String email, 
    required String password, 
    required String name,
    required String phone, 
    required String role, 
    String? nationalId, 
    File? idFrontImage, 
    File? idBackImage,
    File? professionImage, 
    File? carLicenseFrontImage, 
    File? carLicenseBackImage,
  });

  Future<void> verifyOtpAndResetPassword({
    required String verificationId, 
    required String smsCode, 
    required String newPassword
  });
}