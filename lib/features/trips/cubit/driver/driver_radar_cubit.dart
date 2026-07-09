import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/driver_radar_repository.dart';
import '../../data/models/trip_model.dart';
import 'driver_radar_state.dart';

class DriverRadarCubit extends Cubit<DriverRadarState> {
  final DriverRadarRepository _repository;
  StreamSubscription? _radarSubscription;

  DriverRadarCubit(this._repository) : super(DriverRadarInitial());

  void listenToRadarTrips() {
    emit(DriverRadarLoading());
    
    _radarSubscription?.cancel();
    _radarSubscription = _repository.getRadarTripsStream().listen(
      (trips) {
        if (isClosed) return; // 🟢 حماية المستمع
        try {
          List<TripModel> models = [];
          
          if (trips is List<TripModel>) {
            models = trips;
          } else if (trips is List) {
            models = trips.map((e) => e as TripModel).toList();
          }
          
          emit(DriverRadarLoaded(models));
        } catch (e) {
          emit(DriverRadarError('حدث خطأ في معالجة الطلبات: ${e.toString()}'));
        }
      },
      onError: (error) {
        if (isClosed) return;
        emit(DriverRadarError(error.toString()));
      },
    );
  }

  Future<void> acceptTrip(String tripId, {String? negotiatedPrice}) async {
    emit(DriverRadarActionLoading());
    try {
      await _repository.acceptTripSecurely(tripId, negotiatedPrice);
      if (isClosed) return; // 🟢 حماية بعد عملية الـ await
      emit(DriverRadarActionSuccess('تم قبول الرحلة بنجاح'));
    } catch (e) {
      if (isClosed) return;
      String errorMessage = 'حدث خطأ غير متوقع';
      if (e.toString().contains('TRIP_NOT_FOUND')) {
        errorMessage = 'عذراً، هذه الرحلة لم تعد متوفرة';
      } else if (e.toString().contains('TRIP_ALREADY_TAKEN')) {
        errorMessage = 'عذراً، تم التقاط هذه الرحلة بواسطة سائق آخر';
      }
      emit(DriverRadarActionError(errorMessage));
    }
  }

  Future<void> negotiateTrip(String tripId, String offer) async {
    emit(DriverRadarActionLoading());
    try {
      await _repository.negotiateTrip(tripId, offer);
      if (isClosed) return;
      emit(DriverRadarActionSuccess('تم إرسال عرض السعر بنجاح'));
    } catch (e) {
      if (isClosed) return;
      emit(DriverRadarActionError('حدث خطأ أثناء التفاوض: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _radarSubscription?.cancel();
    return super.close();
  }
}