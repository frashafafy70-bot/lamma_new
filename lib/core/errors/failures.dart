// مسار الملف: lib/core/errors/failures.dart

import 'package:equatable/equatable.dart';

// 🟢 الكلاس الأساسي أصبح يرث من Equatable ويستخدم const لتقليل استهلاك الذاكرة
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

// -------------------------------------------------------------------
// 🟢 تفريعات الأخطاء (Sub-classes) لتحديد نوع المشكلة بدقة
// -------------------------------------------------------------------

/// أخطاء السيرفر وقواعد البيانات (مثل أخطاء Firebase Firestore)
class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

/// أخطاء انقطاع الإنترنت أو ضعف الشبكة
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message =
        'لا يوجد اتصال بالإنترنت، يرجى التحقق من الشبكة والمحاولة مرة أخرى.',
  });
}

/// أخطاء التخزين المحلي (مثل فشل قراءة/كتابة البيانات في SharedPreferences أو Hive)
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// أخطاء الصلاحيات والمصادقة (مثل انتهاء جلسة المستخدم أو عدم وجود صلاحية)
class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

/// أخطاء المدخلات (مثل تمرير بيانات غير صالحة من الـ UI)
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}
