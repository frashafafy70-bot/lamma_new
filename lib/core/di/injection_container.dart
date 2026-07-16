import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// 🟢 استدعاءات الشبكة
import 'package:lamma_new/core/network/network_cubit.dart';

// 🟢 استدعاءات الـ Modules المنفصلة (Clean Architecture)
import 'package:lamma_new/features/auth/auth_injection.dart'; 
import 'package:lamma_new/features/home/home_injection.dart'; 
import 'package:lamma_new/features/profile/profile_injection.dart'; 
import 'package:lamma_new/features/notifications/notification_injection.dart'; 
import 'package:lamma_new/features/trips/trip_injection.dart'; // 👈 مسار التريبس

final sl = GetIt.instance; // sl = Service Locator

Future<void> initDI() async {
  // ==========================================
  // 1. External (Firebase)
  // ==========================================
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);

  // ==========================================
  // 2. Core (Network)
  // ==========================================
  sl.registerFactory(() => NetworkCubit());

  // ==========================================
  // 3. Features Modules (Clean Architecture)
  // ==========================================
  initAuthModule(); 
  initHome(); 
  initProfile(); 
  initNotificationModule(); 
  initTripModule(); // 👈 تفعيل الرحلات النظيف بالكامل
}