import 'package:get_it/get_it.dart';

// استيراد ملف حقن الهوم بالمسار الكامل الصحيح
import 'package:lamma_new/features/home/home_injection.dart';

final sl = GetIt.instance;

Future<void> initLocator() async {
  // 🟢 استدعاء تهيئة موديول الهوم بالاسم الصحيح والموحد
  initHome();

  // هنا يمكنك استدعاء موديولات الميزات الأخرى مستقبلاً بنفس الطريقة:
  // initAuth();
  // initProfile();
}