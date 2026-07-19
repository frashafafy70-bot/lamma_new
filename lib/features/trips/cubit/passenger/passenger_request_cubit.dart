import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// 🟢 لا يوجد أي أثر لفايربيز هنا! (Clean Architecture 100%)
import '../../domain/repositories/map_repository.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../domain/entities/place_search_entity.dart';

part 'passenger_request_state.dart';

class PassengerRequestCubit extends Cubit<PassengerRequestState> {
  final MapRepository mapRepository;
  final TripRepository tripRepository;

  PassengerRequestCubit(
      {required this.mapRepository, required this.tripRepository})
      : super(PassengerRequestInitial());

  Future<void> getUserLocation() async {
    if (isClosed) return;
    emit(LocationLoading());

    final result = await mapRepository.getUserCurrentLocation();
    if (isClosed) return;

    result.fold((failure) {
      if (failure.message.contains('نهائياً')) {
        emit(LocationPermissionDenied());
      } else {
        emit(LocationError(failure.message));
      }
    }, (position) {
      emit(LocationLoaded(LatLng(position.latitude, position.longitude)));
    });
  }

  Future<void> getAddressFromLatLng(LatLng latLng) async {
    if (isClosed) return;
    emit(AddressLoading());

    final result = await mapRepository.getAddressFromCoordinates(latLng);
    if (isClosed) return;

    result.fold((failure) => emit(AddressError(failure.message)),
        (address) => emit(AddressLoaded(address)));
  }

  Future<void> searchForPlaces(String input) async {
    if (input.isEmpty) {
      if (isClosed) return;
      emit(PlacesSearchLoaded([]));
      return;
    }

    final result = await mapRepository.searchPlaces(input);
    if (isClosed) return;

    result.fold((failure) => emit(PlacesSearchLoaded([])),
        (results) => emit(PlacesSearchLoaded(results)));
  }

  Future<void> fetchPlaceDetails(String placeId, String description) async {
    final result = await mapRepository.getPlaceCoordinates(placeId);
    if (isClosed) return;

    result.fold(
        (failure) =>
            debugPrint("Error fetching place details: ${failure.message}"),
        (location) => emit(PlaceDetailsLoaded(location, description)));
  }

  Future<void> fetchRoute(LatLng origin, LatLng destination) async {
    if (isClosed) return;

    final result = await mapRepository.getRouteCoordinates(origin, destination);
    if (isClosed) return;

    result.fold(
        (failure) =>
            debugPrint("Error fetching route from Cubit: ${failure.message}"),
        (points) => emit(RouteCoordinatesLoaded(points)));
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

    // 🟢 الـ Repository هو اللي بيتصرف في كل حاجة دلوقتي
    final result = await tripRepository.createPassengerTrip(
      tripCategory: tripCategory,
      vehicleType: vehicleType,
      pickup: pickup,
      destination: destination,
      price: price,
      errandDetails: errandDetails,
      errandCost: errandCost,
      orderAudioFile: orderAudioFile,
      pickupLat: pickupLocation?.latitude,
      pickupLng: pickupLocation?.longitude,
      destinationLat: destinationLocation?.latitude,
      destinationLng: destinationLocation?.longitude,
    );

    if (isClosed) return;

    result.fold((failure) {
      debugPrint("❌ خطأ الإرسال: ${failure.message}");
      emit(TripSubmitError(failure.message));
    },
        // 🟢 تم التعديل هنا: استقبال الـ tripId وتمريره للحالة
        (tripId) => emit(TripSubmitSuccess(tripId)));
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
