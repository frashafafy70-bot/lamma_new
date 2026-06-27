import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'driver_active_trips_state.dart';

class DriverActiveTripsCubit extends Cubit<DriverActiveTripsState> {
  DriverActiveTripsCubit() : super(DriverActiveTripsInitial());

  StreamSubscription? _tripsSubscription;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void startListeningToActiveTrips() {
    emit(DriverActiveTripsLoading());

    _tripsSubscription = FirebaseFirestore.instance
        .collection('trips')
        .where('driverId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
          
      var validTrips = snapshot.docs.where((doc) {
        var data = doc.data(); 
        bool isNotDeleted = data['isDeletedForDriver'] != true;
        bool isValidStatus = data['status'] == 'negotiating' || data['status'] == 'accepted' || data['status'] == 'canceled';
        return isNotDeleted && isValidStatus;
      }).toList();

      validTrips.sort((a, b) {
        var dataA = a.data();
        var dataB = b.data();
        Timestamp? timeA = dataA['createdAt'];
        Timestamp? timeB = dataB['createdAt'];
        
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA); 
      });

      emit(DriverActiveTripsLoaded(validTrips));
      
    }, onError: (error) {
      emit(DriverActiveTripsError('حدث خطأ في تحميل رحلات الكابتن.'));
    });
  }

  @override
  Future<void> close() {
    _tripsSubscription?.cancel();
    return super.close();
  }
}