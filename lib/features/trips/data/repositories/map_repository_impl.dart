import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

import '../../../../core/errors/failures.dart';
import '../../domain/entities/place_search_entity.dart';
import '../../domain/repositories/map_repository.dart';

class MapRepositoryImpl implements MapRepository {
  String _googleApiKey = ''; 
  BitmapDescriptor? _carMarker;
  BitmapDescriptor? _bikeMarker;
  BitmapDescriptor? _tuktokMarker;

  @override
  String get googleApiKey => _googleApiKey;

  @override
  BitmapDescriptor? get carMarker => _carMarker;

  @override
  BitmapDescriptor? get bikeMarker => _bikeMarker;

  @override
  BitmapDescriptor? get tuktokMarker => _tuktokMarker;

  @override
  Future<void> initMapResources({required String apiKey}) async {
    _googleApiKey = apiKey;
    
    const ImageConfiguration config = ImageConfiguration(size: Size(48, 48));
    try {
      _carMarker = await BitmapDescriptor.asset(config, 'assets/images/car_3d.png');
      _bikeMarker = await BitmapDescriptor.asset(config, 'assets/images/bike_3d.png');
      _tuktokMarker = await BitmapDescriptor.asset(config, 'assets/images/tuktok_3d.png');
    } catch (e) {
      debugPrint("Error loading custom markers: $e");
    }
  }

  String _cleanAddress(String address) {
    String cleaned = address.replaceAll(RegExp(r'\b[A-Z0-9]{2,8}\+[A-Z0-9]{2,4}\b\s*[,،]?\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'Unnamed Road\s*[,،]?\s*', caseSensitive: false), '');
    
    cleaned = cleaned.trim();
    while (cleaned.startsWith('،') || cleaned.startsWith(',')) {
      cleaned = cleaned.substring(1).trim();
    }
    while (cleaned.endsWith('،') || cleaned.endsWith(',')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trim();
    }
    
    return cleaned.isEmpty ? 'موقع غير معروف' : cleaned;
  }

  @override
  Future<Either<Failure, String>> getAddressFromCoordinates(LatLng latLng) async {
    if (_googleApiKey.isNotEmpty) {
      final String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$_googleApiKey&language=ar";
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
            String formattedAddress = data['results'][0]['formatted_address'];
            return Right(_cleanAddress(formattedAddress));
          }
        }
      } catch (e) {
        debugPrint("Google API Error: $e");
        // عند فشل Google API، سنكمل لمحاولة استخدام Native Geocoding بدلاً من الإرجاع مباشرة
      }
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';
        if (place.street != null && place.street!.isNotEmpty) address += '${place.street}، ';
        if (place.subLocality != null && place.subLocality!.isNotEmpty) address += '${place.subLocality}، ';
        if (place.locality != null && place.locality!.isNotEmpty) address += '${place.locality}';
        
        return Right(_cleanAddress(address));
      }
      return Right("إحداثيات: ${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}");
    } catch (e) {
      debugPrint("Native Geocoding Error: $e");
      return Left(ServerFailure(message: 'فشل في جلب العنوان الحالي، تأكد من اتصالك بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, List<PlaceSearchEntity>>> searchPlaces(String input) async {
    if (input.isEmpty) return const Right([]);
    
    String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_googleApiKey&language=ar&components=country:kw|country:eg";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final List<dynamic> predictions = data['predictions'] ?? [];
          final places = predictions.map((json) => PlaceSearchEntity(
            placeId: json['place_id'],
            description: json['description'],
          )).toList();
          return Right(places);
        } else {
          return Left(ServerFailure(message: 'فشل في البحث: ${data['status']}'));
        }
      } else {
        return Left(ServerFailure(message: 'حدث خطأ في الخادم أثناء البحث'));
      }
    } catch (e) {
      debugPrint("Error searching places: $e");
      return Left(ServerFailure(message: 'تأكد من اتصالك بالإنترنت وحاول مجدداً'));
    }
  }

  @override
  Future<Either<Failure, LatLng>> getPlaceCoordinates(String placeId) async {
    String url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          var location = data['result']['geometry']['location'];
          return Right(LatLng(location['lat'], location['lng']));
        } else {
          return Left(ServerFailure(message: 'فشل في جلب تفاصيل الموقع'));
        }
      } else {
        return Left(ServerFailure(message: 'حدث خطأ في الخادم'));
      }
    } catch (e) {
      debugPrint("Error getting place details: $e");
      return Left(ServerFailure(message: 'تأكد من اتصالك بالإنترنت وحاول مجدداً'));
    }
  }

  @override
  Future<Either<Failure, Position>> getUserCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Left(ServerFailure(message: 'خدمة الـ GPS معطلة، يرجى تفعيلها'));
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Left(ServerFailure(message: 'تم رفض صلاحية الوصول للموقع'));
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return Left(ServerFailure(message: 'تم رفض صلاحية الوصول للموقع نهائياً، يرجى تفعيلها من الإعدادات'));
      }

      final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
      );
      return Right(position);
    } catch (e) {
      debugPrint('Location Error: $e');
      return Left(ServerFailure(message: 'فشل في تحديد موقعك الحالي'));
    }
  }

  @override
  Future<Either<Failure, List<LatLng>>> getRouteCoordinates(LatLng origin, LatLng destination) async {
    String url = "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_googleApiKey";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
          return Right(_decodePolyline(encodedPolyline));
        } else {
          return Left(ServerFailure(message: 'لم يتم العثور على مسار متاح'));
        }
      } else {
        return Left(ServerFailure(message: 'حدث خطأ في الخادم أثناء جلب المسار'));
      }
    } catch (e) {
      debugPrint("Error getting directions: $e");
      return Left(ServerFailure(message: 'فشل في جلب المسار، تأكد من اتصالك بالإنترنت'));
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }
}