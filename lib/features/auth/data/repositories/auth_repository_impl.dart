import 'dart:io';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService authService;
  AuthRepositoryImpl(this.authService);

  @override
  Future<UserEntity> login({required String email, required String password}) async {
    final userCredential = await authService.loginUser(email: email, password: password);
    final userData = await authService.getUserData(userCredential.user!.uid);
    return UserModel.fromJson(userData!);
  }

  @override
  Future<UserEntity> signUp({required String email, required String password, required String name, required String phone}) async {
    final userCredential = await authService.signUpUser(email: email, password: password, name: name, phone: phone);
    final userData = await authService.getUserData(userCredential.user!.uid);
    return UserModel.fromJson(userData!);
  }

  @override
  Future<void> signOut() async => await authService.signOutUser();

  @override
  Future<UserEntity?> getUserData(String uid) async {
    final userData = await authService.getUserData(uid);
    return userData != null ? UserModel.fromJson(userData) : null;
  }

  @override
  Future<UserEntity> loginWithGoogle() async {
    final userCredential = await authService.loginWithGoogle();
    final userData = await authService.getUserData(userCredential.user!.uid);
    return UserModel.fromJson(userData!);
  }

  @override
  Future<void> sendSignUpOtp({required String phone, required Function(String) onCodeSent, required Function(String) onError}) async {
    await authService.sendSignUpOtp(phone: phone, onCodeSent: onCodeSent, onError: onError);
  }

  @override
  Future<UserEntity> verifyOtpAndCompleteSignUp({
    required String verificationId, required String smsCode, required String email, required String password, required String name,
    required String phone, required String role, String? nationalId, File? idFrontImage, File? idBackImage,
    File? professionImage, File? carLicenseFrontImage, File? carLicenseBackImage,
  }) async {
    final uid = await authService.verifyOtpAndCompleteSignUp(
      verificationId: verificationId, smsCode: smsCode, email: email, password: password, name: name, phone: phone, role: role,
      nationalId: nationalId, idFrontImage: idFrontImage, idBackImage: idBackImage, professionImage: professionImage,
      carLicenseFrontImage: carLicenseFrontImage, carLicenseBackImage: carLicenseBackImage,
    );
    final userData = await authService.getUserData(uid);
    return UserModel.fromJson(userData!);
  }
}