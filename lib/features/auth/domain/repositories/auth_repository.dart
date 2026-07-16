import 'dart:io';
import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<String, UserEntity>> login({required String email, required String password});
  
  Future<Either<String, UserEntity>> signUp({required String email, required String password, required String name, required String phone});
  
  Future<Either<String, void>> signOut();
  
  Future<Either<String, UserEntity?>> getUserData(String uid);
  
  Future<Either<String, void>> resetPassword(String email);
  
  Future<Either<String, UserEntity>> loginWithGoogle();
  
  Future<Either<String, void>> sendSignUpOtp({
    required String phone, 
    required Function(String) onCodeSent, 
    required Function(String) onError
  });

  Future<Either<String, UserEntity>> verifyOtpAndCompleteSignUp({
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

  Future<Either<String, UserEntity?>> verifyOtpAndCheckUser({
    required String verificationId, 
    required String smsCode,
  });

  Future<Either<String, UserEntity>> completeRegistration({
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

  Future<Either<String, void>> verifyOtpAndResetPassword({
    required String verificationId, 
    required String smsCode, 
    required String newPassword
  });
}