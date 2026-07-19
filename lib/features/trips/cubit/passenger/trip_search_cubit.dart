import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/trip_booking_repository.dart';
import 'trip_search_state.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';

class TripSearchCubit extends Cubit<TripSearchState> {
  final TripBookingRepository _repository;

  TripSearchCubit(this._repository) : super(TripSearchInitial());

  Future<void> searchForRides(String fromCity, String toCity) async {
    if (isClosed) return;
    emit(TripSearchLoading());

    if (fromCity.isEmpty || toCity.isEmpty) {
      emit(const TripSearchError("يرجى تحديد مدينة الانطلاق والوصول"));
      return;
    }

    final result =
        await _repository.searchTrips(fromCity: fromCity, toCity: toCity);

    if (isClosed) return;

    result.fold(
      (failure) =>
          emit(TripSearchError(failure.message ?? "حدث خطأ غير متوقع")),
      (trips) => emit(TripSearchLoaded(trips)),
    );
  }
}
