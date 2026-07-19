import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // 🟢 إضافة مكتبة فحص الإنترنت المتوافقة

// 🟢 استدعاءات الشبكة
import 'package:lamma_new/core/network/network_cubit.dart';
import 'package:lamma_new/core/network/network_info.dart';

// 🟢 استدعاءات الـ Modules المنفصلة (Clean Architecture)
import 'package:lamma_new/features/auth/auth_injection.dart';
import 'package:lamma_new/features/home/di/home_injection.dart';
import 'package:lamma_new/features/profile/profile_injection.dart';
import 'package:lamma_new/features/notifications/notification_injection.dart';
import 'package:lamma_new/features/trips/trip_injection.dart';

final sl = GetIt.instance; // sl = Service Locator

Future<void> initDI() async {
  // ==========================================
  // 1. External (Firebase & Local Storage)
  // ==========================================
  // تهيئة التخزين المحلي (SharedPreferences)
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);

  // ==========================================
  // 2. Core (Network & Utilities)
  // ==========================================
  // تسجيل مكتبة Connectivity كنسخة واحدة
  sl.registerLazySingleton(() => Connectivity());

  // الكلاس (Interface) اللي الـ Repositories بتعتمد عليه لفحص الإنترنت
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // 🟢 التعديل الجذري: تحويل الـ NetworkCubit لـ LazySingleton لمراقبة مركزية (Global State)
  // ده هيمنع الـ Memory Leaks وهيخلي التطبيق يفتح Stream واحد بس للإنترنت
  sl.registerLazySingleton(() => NetworkCubit());

  // ==========================================
  // 3. Features Modules (Clean Architecture)
  // ==========================================
  initAuthModule();
  initHome();
  initProfile();
  initNotificationModule();
  initTripModule(); // تفعيل موديول الرحلات المدرع
}
