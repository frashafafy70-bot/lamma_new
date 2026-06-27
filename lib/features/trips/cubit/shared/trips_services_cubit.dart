import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/trip_model.dart';
import 'trips_services_state.dart'; 

class TripsServicesCubit extends Cubit<TripsServicesState> {
  TripsServicesCubit() : super(TripsServicesInitial());

  StreamSubscription? _tripsSubscription;

  void fetchTrips(String currentUserId, {bool isPassenger = true}) {
    emit(TripsServicesLoading());

    try {
      final collection = FirebaseFirestore.instance.collection('trips');
      
      Query query = isPassenger 
          ? collection.where('passengerId', isEqualTo: currentUserId)
          : collection.where('driverId', isEqualTo: currentUserId);

      // ترتيب حسب الأحدث لضمان ظهور التحديثات فوراً
      query = query.orderBy('createdAt', descending: true);

      _tripsSubscription = query.snapshots().listen(
        (snapshot) {
          List<TripModel> trips = snapshot.docs.map((doc) {
            return TripModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          emit(TripsServicesSuccess(trips: trips));
        }, 
        onError: (error) {
          emit(TripsServicesError(error.toString()));
        }
      );

    } catch (e) {
      emit(TripsServicesError(e.toString()));
    }
  }

  Future<void> requestNewTrip({
    required String passengerId,
    required String passengerName,
    required String pickup,
    required String destination,
    required String suggestedPrice,
    required String vehicleType,
    GeoPoint? pickupLocation,
    GeoPoint? destinationLocation,
  }) async {
    
    try {
      final newTrip = TripModel(
        isDriverPost: false, 
        passengerId: passengerId,
        passengerName: passengerName,
        pickup: pickup,
        destination: destination,
        pickupLocation: pickupLocation,
        destinationLocation: destinationLocation,
        suggestedPrice: suggestedPrice,
        vehicleType: vehicleType,
        status: 'pending', 
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('trips').add(newTrip.toMap());
      
    } catch (e) {
      emit(TripsServicesError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _tripsSubscription?.cancel();
    return super.close();
  }
}