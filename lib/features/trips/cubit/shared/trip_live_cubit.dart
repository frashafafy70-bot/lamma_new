import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamma_new/features/trips/data/models/trip_model.dart';
import 'trip_live_state.dart';

class TripLiveCubit extends Cubit<TripLiveState> {
  final String tripId;
  StreamSubscription<DocumentSnapshot>? _subscription;

  TripLiveCubit({required this.tripId}) : super(TripLiveInitial()) {
    _startListening();
  }

  void _startListening() {
    emit(TripLiveLoading());

    _subscription = FirebaseFirestore.instance
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;
          final trip = TripModel.fromMap(data, snapshot.id);

          emit(TripLiveLoaded(
            rawData: data,
            trip: trip,
            status: data['status'] ?? 'accepted',
          ));
        } else {
          emit(TripLiveError("بيانات الرحلة غير متوفرة أو تم حذفها."));
        }
      },
      onError: (error) {
        emit(TripLiveError("حدث خطأ في الاتصال بالرحلة: $error"));
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
