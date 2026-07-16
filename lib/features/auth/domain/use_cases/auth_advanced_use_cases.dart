import 'dart:io';
import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';
import '../entities/user_entity.dart';

class LoginWithGoogleUseCase {
  final AuthRepository repository;
  LoginWithGoogleUseCase(this.repository);
  
  Future<Either<String, UserEntity>> call() async => await repository.loginWithGoogle();
}

class SendSignUpOtpUseCase {
  final AuthRepository repository;
  SendSignUpOtpUseCase(this.repository);
  
  Future<Either<String, void>> call({required String phone, required Function(String) onCodeSent, required Function(String) onError}) async {
    return await repository.sendSignUpOtp(phone: phone, onCodeSent: onCodeSent, onError: onError);
  }
}

class VerifyOtpAndSignUpUseCase {
  final AuthRepository repository;
  VerifyOtpAndSignUpUseCase(this.repository);
  
  Future<Either<String, UserEntity>> call({
    required String verificationId, required String smsCode, required String email, required String password, required String name,
    required String phone, required String role, String? nationalId, File? idFrontImage, File? idBackImage,
    File? professionImage, File? carLicenseFrontImage, File? carLicenseBackImage,
  }) async {
    return await repository.verifyOtpAndCompleteSignUp(
      verificationId: verificationId, smsCode: smsCode, email: email, password: password, name: name, phone: phone, role: role,
      nationalId: nationalId, idFrontImage: idFrontImage, idBackImage: idBackImage, professionImage: professionImage,
      carLicenseFrontImage: carLicenseFrontImage, carLicenseBackImage: carLicenseBackImage,
    );
  }
}