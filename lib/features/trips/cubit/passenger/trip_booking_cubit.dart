import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/trip_booking_repository.dart';
import 'trip_booking_state.dart';

class TripBookingCubit extends Cubit<TripBookingState> {
  final TripBookingRepository _repository;

  TripBookingCubit(this._repository) : super(TripBookingInitial());

  Future<void> searchForRides(String fromCity, String toCity) async {
    emit(TripSearchLoading());
    
    if(fromCity.isEmpty || toCity.isEmpty) {
      emit(const TripSearchError("يرجى تحديد مدينة الانطلاق والوصول"));
      return;
    }

    final result = await _repository.searchTrips(fromCity: fromCity, toCity: toCity);

    result.fold(
      (failure) => emit(TripSearchError(failure.message ?? "حدث خطأ غير متوقع")),
      (trips) => emit(TripSearchLoaded(trips)),
    );
  }

  Future<void> bookSelectedTrip({
    required String tripId,
    required String driverId,
    required int requestedSeats,
  }) async {
    emit(TripBookingLoading());

    final result = await _repository.bookTripSeat(
      tripId: tripId,
      driverId: driverId,
      requestedSeats: requestedSeats,
    );

    result.fold(
      (failure) => emit(TripBookingError(failure.message ?? "فشل الحجز")),
      (_) => emit(const TripBookingSuccess("تم إرسال طلب الحجز للكابتن بنجاح!")),
    );
  }
}