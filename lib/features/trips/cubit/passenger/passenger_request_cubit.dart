import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// 🟢 استيراد الـ Repositories والـ Entities بدلاً من الـ Services القديمة
import '../../domain/repositories/map_repository.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../domain/entities/place_search_entity.dart';

part 'passenger_request_state.dart';

class PassengerRequestCubit extends Cubit<PassengerRequestState> {
  final MapRepository mapRepository;
  final TripRepository tripRepository;

  PassengerRequestCubit({required this.mapRepository, required this.tripRepository})
      : super(PassengerRequestInitial());

  // 📍 جلب الموقع الحالي بالاعتماد على الـ Repository
  Future<void> getUserLocation() async {
    emit(LocationLoading());
    
    try {
      // 🟢 الـ Repository يتكفل بكل شيء (فحص الصلاحيات، تفعيل الـ GPS، وتحديد الموقع)
      final position = await mapRepository.getUserCurrentLocation();
      emit(LocationLoaded(LatLng(position.latitude, position.longitude)));

    } catch (e) {
      String errorMessage = 'حدث خطأ أثناء جلب الموقع.';
      
      // التعامل مع الأخطاء التي تم تمريرها من طبقة الـ Data
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

  // 🗺️ جلب العنوان من الإحداثيات (Reverse Geocoding)
  Future<void> getAddressFromLatLng(LatLng latLng) async {
    emit(AddressLoading());
    try {
      String address = await mapRepository.getAddressFromCoordinates(latLng);
      emit(AddressLoaded(address));
    } catch (e) {
      emit(AddressError("حدث خطأ أثناء جلب العنوان"));
    }
  }

  // 🔍 البحث عن أماكن
  Future<void> searchForPlaces(String input) async {
    if (input.isEmpty) {
      emit(PlacesSearchLoaded([]));
      return;
    }
    try {
      // 🟢 الآن نحن نستقبل قائمة من الكيان النظيف PlaceSearchEntity بدلاً من dynamic
      List<PlaceSearchEntity> results = await mapRepository.searchPlaces(input);
      emit(PlacesSearchLoaded(results));
    } catch (e) {
      emit(PlacesSearchLoaded([]));
    }
  }

  // 📍 جلب تفاصيل المكان المحدد
  Future<void> fetchPlaceDetails(String placeId, String description) async {
    try {
      LatLng? location = await mapRepository.getPlaceCoordinates(placeId);
      if (location != null) {
        emit(PlaceDetailsLoaded(location, description));
      }
    } catch (e) {
      debugPrint("Error fetching place details: $e");
    }
  }

  // 🚀 إرسال الطلب
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
      
      emit(TripSubmitSuccess());
    } catch (e) {
      debugPrint("❌ خطأ الإرسال: $e");
      emit(TripSubmitError("حدث خطأ أثناء إرسال الطلب."));
    }
  }

  @override
  Future<void> close() {
    return super.close();
  }
}