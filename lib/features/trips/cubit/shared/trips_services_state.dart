import '../../data/models/trip_model.dart'; 

abstract class TripsServicesState {}

// 1. الحالة الابتدائية
class TripsServicesInitial extends TripsServicesState {}

// 2. حالة التحميل
class TripsServicesLoading extends TripsServicesState {}

// 3. حالة النجاح: تستقبل قائمة من TripModel
class TripsServicesSuccess extends TripsServicesState {
  final List<TripModel> trips; 

  TripsServicesSuccess({required this.trips});
}

// 4. حالة الخطأ
class TripsServicesError extends TripsServicesState {
  final String errorMessage;

  TripsServicesError(this.errorMessage);
}

// 5. حالة نجاح إرسال طلب جديد (تمت إضافتها عشان الشاشة تقفل بعد الطلب)
class TripRequestSuccess extends TripsServicesState {}