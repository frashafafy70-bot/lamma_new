import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../data/services/map_service.dart';
import '../../data/services/trip_service.dart';

part 'passenger_request_state.dart';

class PassengerRequestCubit extends Cubit<PassengerRequestState> {
  final MapService mapService;
  final TripService tripService;

  PassengerRequestCubit({required this.mapService, required this.tripService})
      : super(PassengerRequestInitial());

  Future<void> getAddressFromLatLng(LatLng latLng) async {
    emit(AddressLoading());
    try {
      String address = await mapService.performReverseGeocoding(latLng);
      emit(AddressLoaded(address));
    } catch (e) {
      emit(AddressError("حدث خطأ أثناء جلب العنوان"));
    }
  }

  Future<void> searchForPlaces(String input) async {
    if (input.isEmpty) {
      emit(PlacesSearchLoaded([]));
      return;
    }
    try {
      List<dynamic> results = await mapService.searchPlaces(input);
      emit(PlacesSearchLoaded(results));
    } catch (e) {
      emit(PlacesSearchLoaded([]));
    }
  }

  Future<void> fetchPlaceDetails(String placeId, String description) async {
    try {
      LatLng? location = await mapService.getPlaceDetails(placeId);
      if (location != null) {
        emit(PlaceDetailsLoaded(location, description));
      }
    } catch (e) {
      debugPrint("Error fetching place details: $e");
    }
  }

  Future<void> submitTripRequest({
    required String tripCategory,
    required String vehicleType,
    required String pickup,
    required String destination,
    required String price,
    String? errandDetails,
    String? errandCost,
    LatLng? pickupLocation,
    LatLng? destinationLocation,
    File? orderAudioFile,
  }) async {
    
    emit(TripSubmitting());

    try {
      String? audioUrl;
      
      // رفع الملف للـ Firebase Storage
      if (orderAudioFile != null) {
        final String fileName = 'trips_audio/${DateTime.now().millisecondsSinceEpoch}.m4a';
        final Reference ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(orderAudioFile);
        audioUrl = await ref.getDownloadURL();
        debugPrint("✅ تم رفع الريكورد: $audioUrl");
      }

      final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final String currentUserName = FirebaseAuth.instance.currentUser?.displayName ?? 'عميل';
      bool isErrand = tripCategory == 'طلبات';

      Map<String, dynamic> tripData = {
        'isDriverPost': false,
        'passengerId': currentUserId,
        'passengerName': currentUserName,
        'tripCategory': tripCategory,
        'vehicleType': isErrand ? 'موتوسيكل' : vehicleType,
        'pickup': pickup,
        'destination': destination,
        'suggestedPrice': price,
        'price': price,
        'errandDetails': isErrand ? errandDetails : null,
        'errandCost': isErrand ? errandCost : null,
        'audioUrl': audioUrl, // 🟢 حفظ الرابط هنا
        'pickupLocation': pickupLocation != null ? GeoPoint(pickupLocation.latitude, pickupLocation.longitude) : null,
        'destinationLocation': destinationLocation != null ? GeoPoint(destinationLocation.latitude, destinationLocation.longitude) : null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await tripService.createNewTripRequest(tripData);
      
      emit(TripSubmitSuccess());
    } catch (e) {
      debugPrint("❌ خطأ الإرسال: $e");
      emit(TripSubmitError("حدث خطأ أثناء إرسال الطلب."));
    }
  }
}