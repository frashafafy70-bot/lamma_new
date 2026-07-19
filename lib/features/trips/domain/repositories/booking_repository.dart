import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class BookingRepository {
  /// قبول حجز الراكب وتحديث المقاعد في الرحلة
  Future<Either<Failure, void>> acceptPassengerBooking({
    required String bookingId,
    required String tripId,
    required int seatsToDeduct,
  });

  /// رفض طلب الراكب وحذفه من قائمة الحجوزات
  Future<Either<Failure, void>> rejectPassengerBooking({
    required String bookingId,
    required String tripId,
    required String passengerId,
  });

  /// إلغاء الحجز وإعادة المقاعد للسيارة
  Future<Either<Failure, void>> cancelPassengerBooking({
    required String bookingId,
    required String tripId,
    required String passengerId,
    required int seatsToReturn,
    required bool wasAccepted,
  });

  /// التفاوض على السعر بين السائق والراكب
  Future<Either<Failure, void>> submitNegotiation({
    required String docId,
    required double offerPrice,
    required bool isDriver,
  });

  /// قبول عرض السعر النهائي وتثبيته
  Future<Either<Failure, void>> acceptTripOffer({
    required String tripId,
    required String finalPrice,
    required bool isDriver,
    required String currentUserId,
  });

  /// رفض عرض السعر وإعادة الرحلة للحالة المعلقة
  Future<Either<Failure, void>> rejectTripOffer({
    required String tripId,
  });

  /// حجز مقعد في رحلة سفر منشورة مسبقاً بواسطة سائق
  Future<Either<Failure, void>> bookSeatInDriverPost({
    required String tripId,
    required String driverId,
    required String passengerId,
    required int seatsToBook,
  });
}
