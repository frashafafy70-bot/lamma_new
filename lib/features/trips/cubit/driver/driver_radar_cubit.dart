import 'package:flutter_bloc/flutter_bloc.dart';
import 'driver_radar_state.dart';
import 'package:lamma_new/features/trips/data/services/driver_radar_service.dart';

class DriverRadarCubit extends Cubit<DriverRadarState> {
  final DriverRadarService _service;
  
  DriverRadarCubit(this._service) : super(DriverRadarInitial());

  void startListeningToRadar() {
    emit(DriverRadarLoading());
    _service.getRadarTripsStream().listen((snapshot) {
      emit(DriverRadarLoaded(snapshot.docs));
    }).onError((error) {
      emit(DriverRadarError(error.toString()));
    });
  }

  Future<void> acceptTrip(String tripId, {String? negotiatedPrice}) async {
    try {
      await _service.acceptTripSecurely(tripId, negotiatedPrice);
      emit(DriverRadarAcceptSuccess());
    } catch (e) {
      if (e.toString().contains('TRIP_ALREADY_TAKEN')) {
        emit(DriverRadarAcceptFailed('عفواً.. قام كابتن آخر بقبول الرحلة أسرع منك! 🏃‍♂️'));
      } else if (e.toString().contains('TRIP_NOT_FOUND')) {
        emit(DriverRadarAcceptFailed('عفواً، تم إلغاء هذه الرحلة من قبل العميل.'));
      } else {
        emit(DriverRadarAcceptFailed('حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.'));
      }
    }
  }

  Future<void> negotiateTrip(String tripId, String offer) async {
    try {
      await _service.negotiateTrip(tripId, offer);
    } catch (e) {
      emit(DriverRadarError('حدث خطأ أثناء التفاوض: $e'));
    }
  }
}