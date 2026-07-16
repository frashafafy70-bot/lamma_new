import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/booking_repository.dart';
import 'trip_booking_state.dart';

class TripBookingCubit extends Cubit<TripBookingState> {
  // 🟢 بنعتمد على الـ BookingRepository النظيف
  final BookingRepository _repository;

  TripBookingCubit(this._repository) : super(TripBookingInitial());

  // ==========================================
  // 🎟️ حجز مقعد في رحلة
  // ==========================================
  Future<void> bookSelectedTrip({
    required String tripId,
    required String driverId,
    required String passengerId, // 🟢 ضفنا المتغير هنا عشان الـ UI ميزعلش
    required int requestedSeats,
  }) async {
    if (isClosed) return;
    emit(TripBookingLoading());

    // 🟢 استدعاء الدالة الصحيحة من الـ Repo
    final result = await _repository.bookSeatInDriverPost(
      tripId: tripId,
      driverId: driverId,
      passengerId: passengerId,
      seatsToBook: requestedSeats,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(TripBookingError(failure.message ?? "فشل الحجز")),
      (_) => emit(const TripBookingSuccess("تم إرسال طلب الحجز للكابتن بنجاح!")),
    );
  }
}