// استدعاء ملفات الفرم الثلاثة من مجلد di
import 'di/trip_shared_di.dart';
import 'di/trip_driver_di.dart';
import 'di/trip_passenger_di.dart';

void initTripModule() {
  // 1. تهيئة الأساسيات والمشتركات أولاً (مهم جداً تكون في الأول)
  initTripSharedDI();
  
  // 2. تهيئة قسم الكابتن
  initTripDriverDI();
  
  // 3. تهيئة قسم الراكب
  initTripPassengerDI();
}