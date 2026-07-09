import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/repositories/map_repository.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../domain/entities/place_search_entity.dart';

part 'passenger_request_state.dart';

class PassengerRequestCubit extends Cubit<PassengerRequestState> {
  final MapRepository mapRepository;
  final TripRepository tripRepository;

  PassengerRequestCubit({required this.mapRepository, required this.tripRepository})
      : super(PassengerRequestInitial());

  Future<void> getUserLocation() async {
    if (isClosed) return; 
    emit(LocationLoading());
    
    try {
      final position = await mapRepository.getUserCurrentLocation();
      if (isClosed) return; 
      emit(LocationLoaded(LatLng(position.latitude, position.longitude)));

    } catch (e) {
      if (isClosed) return; 
      String errorMessage = 'حدث خطأ أثناء جلب الموقع.';
      
      if (e.toString().contains('GPS_DISABLED')) {
        errorMessage = 'خدمة الموقع مقفولة، يرجى تفعيلها من إعدادات الهاتف.';
      } else if (e.toString().contains('PERMISSION_DENIED_FOREVER')) {
        emit(LocationPermissionDenied());
        return;
      } else if (e.toString().contains('PERMISSION_DENIED')) {
        errorMessage = 'تم رفض صلاحية الموقع.';
      }
      
      emit(LocationError(errorMessage));
    }
  }

  Future<void> getAddressFromLatLng(LatLng latLng) async {
    if (isClosed) return;
    emit(AddressLoading());
    try {
      String address = await mapRepository.getAddressFromCoordinates(latLng);
      if (isClosed) return;
      emit(AddressLoaded(address));
    } catch (e) {
      debugPrint("💥 الخطأ الحقيقي في جلب العنوان: $e"); 
      if (isClosed) return;
      emit(AddressError("حدث خطأ أثناء جلب العنوان"));
    }
  }

  Future<void> searchForPlaces(String input) async {
    if (input.isEmpty) {
      if (isClosed) return;
      emit(PlacesSearchLoaded([]));
      return;
    }
    try {
      List<PlaceSearchEntity> results = await mapRepository.searchPlaces(input);
      if (isClosed) return;
      emit(PlacesSearchLoaded(results));
    } catch (e) {
      if (isClosed) return;
      emit(PlacesSearchLoaded([]));
    }
  }

  Future<void> fetchPlaceDetails(String placeId, String description) async {
    try {
      LatLng? location = await mapRepository.getPlaceCoordinates(placeId);
      if (location != null) {
        if (isClosed) return;
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
    
    if (isClosed) return;
    emit(TripSubmitting());

    try {
      String? audioUrl;
      
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
        'audioUrl': audioUrl, 
        'pickupLocation': pickupLocation != null ? GeoPoint(pickupLocation.latitude, pickupLocation.longitude) : null,
        'destinationLocation': destinationLocation != null ? GeoPoint(destinationLocation.latitude, destinationLocation.longitude) : null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await tripRepository.createNewTripRequest(tripData);
      
      if (isClosed) return; 
      emit(TripSubmitSuccess());
    } catch (e) {
      debugPrint("❌ خطأ الإرسال: $e");
      if (isClosed) return;
      emit(TripSubmitError("حدث خطأ أثناء إرسال الطلب."));
    }
  }

  @override
  Future<void> close() {
    return super.close();
  }
}