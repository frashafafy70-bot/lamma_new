import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService authService;
  AuthRepositoryImpl(this.authService);

  String _mapFirebaseError(String error) {
    if (error.contains('invalid-credential') || error.contains('wrong-password')) return 'بيانات الدخول غير صحيحة، تأكد من الرقم أو كلمة المرور.';
    if (error.contains('user-not-found')) return 'لا يوجد حساب مسجل بهذه البيانات.';
    if (error.contains('email-already-in-use')) return 'هذا البريد الإلكتروني مسجل مسبقاً.';
    if (error.contains('network-request-failed')) return 'تحقق من اتصالك بالإنترنت.';
    if (error.contains('too-many-requests')) return 'تم حظر الطلبات مؤقتاً بسبب كثرة المحاولات، حاول لاحقاً.';
    if (error.contains('invalid-verification-code')) return 'كود التحقق غير صحيح.';
    if (error.contains('session-expired')) return 'انتهت صلاحية الكود، يرجى طلب كود جديد.';
    if (error.contains('invalid-phone-number')) return 'رقم الهاتف غير صالح.';

    if (RegExp(r'[\u0600-\u06FF]').hasMatch(error)) {
      return error.replaceAll('Exception: ', '').trim();
    }

    return 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً.';
  }

  // 🟢 دالة لتحويل الأرقام العربية (لو الكيبورد عربي) لأرقام إنجليزية عشان الداتابيز
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
  Future<UserEntity> login({required String email, required String password}) async {
    try {
      String loginIdentifier = _normalizeNumbers(email.trim());

      // 1. لو المدخل مفيهوش علامة @، يبقى المستخدم كاتب رقم تليفون
      if (!loginIdentifier.contains('@')) {
        
        // 🟢 الحل الجذري: توليد كل الاحتمالات اللي ممكن الرقم يكون اتسجل بيها
        String exactPhone = loginIdentifier;
        String phoneWithoutZero = exactPhone.startsWith('0') ? exactPhone.substring(1) : exactPhone;
        String phoneWithPlus20 = exactPhone.startsWith('+20') ? exactPhone : '+20$phoneWithoutZero';
        String phoneWithPlus2 = exactPhone.startsWith('+2') ? exactPhone : '+2$exactPhone';

        // بنحطهم في Set عشان نمنع التكرار، وبنحولهم لـ List عشان الفايربيز
        List<String> possiblePhones = {
          exactPhone,
          phoneWithoutZero,
          phoneWithPlus20,
          phoneWithPlus2,
          '+20$exactPhone', // خطأ شائع لو اتسجل +20012
        }.toList();

        // 🟢 بنستخدم whereIn عشان ندور في كل الاحتمالات بطلبة واحدة بس!
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', whereIn: possiblePhones)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          loginIdentifier = querySnapshot.docs.first.data()['email'] ?? '';
          if (loginIdentifier.isEmpty) {
            throw Exception('هذا الحساب مرتبط برقم الهاتف ولكن لا يوجد بريد إلكتروني، يرجى التواصل مع الدعم.');
          }
        } else {
          throw Exception('لا يوجد حساب مسجل برقم الهاتف هذا.');
        }
      }

      final userCredential = await authService.loginUser(email: loginIdentifier, password: password);
      
      final userData = await authService.getUserData(userCredential.user!.uid);
      if (userData == null) throw Exception('بيانات المستخدم غير موجودة');
      
      return UserModel.fromJson(userData);
      
    } catch (e) {
      throw Exception(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<UserEntity> signUp({required String email, required String password, required String name, required String phone}) async {
    try {
      final userCredential = await authService.signUpUser(email: email, password: password, name: name, phone: phone);
      final userData = await authService.getUserData(userCredential.user!.uid);
      if (userData == null) throw Exception('فشل في جلب بيانات الحساب الجديد');
      return UserModel.fromJson(userData);
    } catch (e) {
      throw Exception(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await authService.signOutUser();
    } catch (e) {
      throw Exception(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<UserEntity?> getUserData(String uid) async {
    try {
      final userData = await authService.getUserData(uid);
      return userData != null ? UserModel.fromJson(userData) : null;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> resetPassword(String email) async {
    try {
      await authService.resetPassword(email);
    } catch (e) {
      throw Exception(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<UserEntity> loginWithGoogle() async {
    try {
      final userCredential = await authService.loginWithGoogle();
      final userData = await authService.getUserData(userCredential.user!.uid);
      if (userData == null) throw Exception('فشل جلب بيانات حساب جوجل');
      return UserModel.fromJson(userData);
    } catch (e) {
      throw Exception(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<void> sendSignUpOtp({required String phone, required Function(String) onCodeSent, required Function(String) onError}) async {
    try {
      await authService.sendSignUpOtp(
        phone: phone, 
        onCodeSent: onCodeSent, 
        onError: (err) => onError(_mapFirebaseError(err))
      );
    } catch (e) {
      onError(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<UserEntity> verifyOtpAndCompleteSignUp({
    required String verificationId, required String smsCode, required String email, required String password, required String name,
    required String phone, required String role, String? nationalId, File? idFrontImage, File? idBackImage,
    File? professionImage, File? carLicenseFrontImage, File? carLicenseBackImage,
  }) async {
    try {
      final uid = await authService.verifyOtpAndCompleteSignUp(
        verificationId: verificationId, smsCode: smsCode, email: email, password: password, name: name, phone: phone, role: role,
        nationalId: nationalId, idFrontImage: idFrontImage, idBackImage: idBackImage, professionImage: professionImage,
        carLicenseFrontImage: carLicenseFrontImage, carLicenseBackImage: carLicenseBackImage,
      );
      final userData = await authService.getUserData(uid);
      if (userData == null) throw Exception('فشل إنشاء ملف المستخدم');
      return UserModel.fromJson(userData);
    } catch (e) {
      throw Exception(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<UserEntity?> verifyOtpAndCheckUser({required String verificationId, required String smsCode}) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final userData = await authService.getUserData(userCredential.user!.uid);
      if (userData != null) {
        return UserModel.fromJson(userData);
      } else {
        return null; 
      }
    } catch (e) {
      throw Exception(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<UserEntity> completeRegistration({
    required String email, required String password, required String name, required String phone, required String role,
    String? nationalId, File? idFrontImage, File? idBackImage, File? professionImage, File? carLicenseFrontImage, File? carLicenseBackImage,
  }) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('برجاء التحقق من كود الهاتف أولاً');

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
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set(userData);

      return UserModel.fromJson(userData);
    } catch (e) {
      throw Exception(_mapFirebaseError(e.toString()));
    }
  }

  @override
  Future<void> verifyOtpAndResetPassword({required String verificationId, required String smsCode, required String newPassword}) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      await userCredential.user!.updatePassword(newPassword);
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      throw Exception(_mapFirebaseError(e.toString()));
    }
  }
}