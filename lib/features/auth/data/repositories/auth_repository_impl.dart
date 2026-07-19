import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService authService;
  AuthRepositoryImpl(this.authService);

  String _mapFirebaseError(String error) {
    if (error.contains('invalid-credential') ||
        error.contains('wrong-password'))
      return 'بيانات الدخول غير صحيحة، تأكد من الرقم أو كلمة المرور.';
    if (error.contains('user-not-found'))
      return 'لا يوجد حساب مسجل بهذه البيانات.';
    if (error.contains('email-already-in-use'))
      return 'هذا البريد الإلكتروني مسجل مسبقاً.';
    if (error.contains('network-request-failed'))
      return 'تحقق من اتصالك بالإنترنت.';
    if (error.contains('too-many-requests'))
      return 'تم حظر الطلبات مؤقتاً بسبب كثرة المحاولات، حاول لاحقاً.';
    if (error.contains('invalid-verification-code'))
      return 'كود التحقق غير صحيح.';
    if (error.contains('session-expired'))
      return 'انتهت صلاحية الكود، يرجى طلب كود جديد.';
    if (error.contains('invalid-phone-number')) return 'رقم الهاتف غير صالح.';

    if (RegExp(r'[\u0600-\u06FF]').hasMatch(error)) {
      return error.replaceAll('Exception: ', '').trim();
    }

    return 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً.';
  }

  String _normalizeNumbers(String input) {
    const arabicNumbers = '٠١٢٣٤٥٦٧٨٩';
    const englishNumbers = '0123456789';
    String result = input;
    for (int i = 0; i < arabicNumbers.length; i++) {
      result = result.replaceAll(arabicNumbers[i], englishNumbers[i]);
    }
    return result;
  }

  @override
  Future<Either<String, UserEntity>> login(
      {required String email, required String password}) async {
    try {
      String loginIdentifier = _normalizeNumbers(email.trim());

      if (!loginIdentifier.contains('@')) {
        String exactPhone = loginIdentifier;
        String phoneWithoutZero =
            exactPhone.startsWith('0') ? exactPhone.substring(1) : exactPhone;
        String phoneWithPlus20 =
            exactPhone.startsWith('+20') ? exactPhone : '+20$phoneWithoutZero';
        String phoneWithPlus2 =
            exactPhone.startsWith('+2') ? exactPhone : '+2$exactPhone';

        List<String> possiblePhones = {
          exactPhone,
          phoneWithoutZero,
          phoneWithPlus20,
          phoneWithPlus2,
          '+20$exactPhone',
        }.toList();

        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', whereIn: possiblePhones)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          loginIdentifier = querySnapshot.docs.first.data()['email'] ?? '';
          if (loginIdentifier.isEmpty) {
            return const Left(
                'هذا الحساب مرتبط برقم الهاتف ولكن لا يوجد بريد إلكتروني، يرجى التواصل مع الدعم.');
          }
        } else {
          return const Left('لا يوجد حساب مسجل برقم الهاتف هذا.');
        }
      }

      final userCredential = await authService.loginUser(
          email: loginIdentifier, password: password);

      final userData = await authService.getUserData(userCredential.user!.uid);
      if (userData == null) return const Left('بيانات المستخدم غير موجودة');

      return Right(UserModel.fromJson(userData));
    } catch (e) {
      return Left(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<Either<String, UserEntity>> signUp(
      {required String email,
      required String password,
      required String name,
      required String phone}) async {
    try {
      final userCredential = await authService.signUpUser(
          email: email, password: password, name: name, phone: phone);
      final userData = await authService.getUserData(userCredential.user!.uid);
      if (userData == null)
        return const Left('فشل في جلب بيانات الحساب الجديد');
      return Right(UserModel.fromJson(userData));
    } catch (e) {
      return Left(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<Either<String, void>> signOut() async {
    try {
      await authService.signOutUser();
      return const Right(null);
    } catch (e) {
      return Left(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<Either<String, UserEntity?>> getUserData(String uid) async {
    try {
      final userData = await authService.getUserData(uid);
      return Right(userData != null ? UserModel.fromJson(userData) : null);
    } catch (e) {
      return Left(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<Either<String, void>> resetPassword(String email) async {
    try {
      await authService.resetPassword(email);
      return const Right(null);
    } catch (e) {
      return Left(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<Either<String, UserEntity>> loginWithGoogle() async {
    try {
      final userCredential = await authService.loginWithGoogle();
      final userData = await authService.getUserData(userCredential.user!.uid);
      if (userData == null) return const Left('فشل جلب بيانات حساب جوجل');
      return Right(UserModel.fromJson(userData));
    } catch (e) {
      return Left(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<Either<String, void>> sendSignUpOtp(
      {required String phone,
      required Function(String) onCodeSent,
      required Function(String) onError}) async {
    try {
      await authService.sendSignUpOtp(
          phone: phone,
          onCodeSent: onCodeSent,
          onError: (err) => onError(_mapFirebaseError(err)));
      return const Right(null);
    } catch (e) {
      return Left(_mapFirebaseError(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final uid = await authService.verifyOtpAndCompleteSignUp(
        verificationId: verificationId,
        smsCode: smsCode,
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
        nationalId: nationalId,
        idFrontImage: idFrontImage,
        idBackImage: idBackImage,
        professionImage: professionImage,
        carLicenseFrontImage: carLicenseFrontImage,
        carLicenseBackImage: carLicenseBackImage,
      );
      final userData = await authService.getUserData(uid);
      if (userData == null) return const Left('فشل إنشاء ملف المستخدم');
      return Right(UserModel.fromJson(userData));
    } catch (e) {
      return Left(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<Either<String, UserEntity?>> verifyOtpAndCheckUser(
      {required String verificationId, required String smsCode}) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final userData = await authService.getUserData(userCredential.user!.uid);

      if (userData != null) {
        return Right(UserModel.fromJson(userData));
      } else {
        return const Right(null);
      }
    } catch (e) {
      return Left(_mapFirebaseError(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null)
        return const Left('برجاء التحقق من كود الهاتف أولاً');

      await currentUser.updatePassword(password);
      if (email.isNotEmpty) await currentUser.updateEmail(email);

      Map<String, dynamic> userData = {
        'uid': currentUser.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'status': role == 'customer' ? 'approved' : 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (nationalId != null) userData['nationalId'] = nationalId;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set(userData);

      return Right(UserModel.fromJson(userData));
    } catch (e) {
      return Left(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<Either<String, void>> verifyOtpAndResetPassword(
      {required String verificationId,
      required String smsCode,
      required String newPassword}) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      await userCredential.user!.updatePassword(newPassword);
      await FirebaseAuth.instance.signOut();
      return const Right(null);
    } catch (e) {
      return Left(_mapFirebaseError(e.toString()));
    }
  }
}
