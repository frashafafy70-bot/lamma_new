import 'dart:async';
import 'dart:io'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; 
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

      query = query.orderBy('createdAt', descending: true);

      _tripsSubscription = query.snapshots().listen(
        (snapshot) {
          if (isClosed) return; // 🟢 حماية المستمع
          List<TripModel> trips = snapshot.docs.map((doc) {
            return TripModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          emit(TripsServicesSuccess(trips: trips));
        }, 
        onError: (error) {
          if (isClosed) return;
          emit(TripsServicesError(error.toString()));
        }
      );

    } catch (e) {
      if (isClosed) return;
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
    File? orderAudioFile, 
  }) async {
    
    emit(TripsServicesLoading());

    try {
      String? audioUrl;

      if (orderAudioFile != null) {
        final String fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final Reference storageRef = FirebaseStorage.instance.ref().child('trip_audios').child(fileName);

        final UploadTask uploadTask = storageRef.putFile(orderAudioFile);
        final TaskSnapshot snapshot = await uploadTask;

        audioUrl = await snapshot.ref.getDownloadURL();
      }

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

      Map<String, dynamic> tripData = newTrip.toMap();
      if (audioUrl != null) {
        tripData['audioUrl'] = audioUrl; 
      }

      await FirebaseFirestore.instance.collection('trips').add(tripData);
      
      if (isClosed) return; // 🟢 حماية بعد الانتهاء من الرفع
      emit(TripRequestSuccess()); 
      
    } catch (e) {
      if (isClosed) return;
      emit(TripsServicesError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _tripsSubscription?.cancel();
    return super.close();
  }
}