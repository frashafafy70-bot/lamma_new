import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/place_search_entity.dart';
import '../../domain/repositories/map_repository.dart';

class MapRepositoryImpl implements MapRepository {
  // 🟢 شلنا late وحطينا قيمة افتراضية لمنع الكراش
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
    
    // تحميل أيقونات الخريطة في الذاكرة
    const ImageConfiguration config = ImageConfiguration(size: Size(48, 48));
    try {
      _carMarker = await BitmapDescriptor.asset(config, 'assets/images/car_3d.png');
      _bikeMarker = await BitmapDescriptor.asset(config, 'assets/images/bike_3d.png');
      _tuktokMarker = await BitmapDescriptor.asset(config, 'assets/images/tuktok_3d.png');
    } catch (e) {
      debugPrint("Error loading custom markers: $e");
    }
  }

  // دالة مساعدة داخلية لتنظيف النصوص
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
  Future<String> getAddressFromCoordinates(LatLng latLng) async {
    if (_googleApiKey.isNotEmpty) {
      final String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$_googleApiKey&language=ar";
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
            String formattedAddress = data['results'][0]['formatted_address'];
            return _cleanAddress(formattedAddress);
          }
        }
      } catch (e) {
        debugPrint("Google API Error: $e");
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
        
        return _cleanAddress(address);
      }
    } catch (e) {
      debugPrint("Native Geocoding Error: $e");
    }

    return "إحداثيات: ${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}";
  }

  @override
  Future<List<PlaceSearchEntity>> searchPlaces(String input) async {
    if (input.isEmpty) return [];
    // 🟢 تم إضافة دعم الكويت (kw) ومصر (eg) في البحث
    String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_googleApiKey&language=ar&components=country:kw|country:eg";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> predictions = json.decode(response.body)['predictions'] ?? [];
        return predictions.map((json) => PlaceSearchEntity(
          placeId: json['place_id'],
          description: json['description'],
        )).toList();
      }
    } catch (e) {
      debugPrint("Error searching places: $e");
    }
    return [];
  }

  @override
  Future<LatLng?> getPlaceCoordinates(String placeId) async {
    String url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var location = json.decode(response.body)['result']['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
    } catch (e) {
      debugPrint("Error getting place details: $e");
    }
    return null;
  }

  @override
  Future<Position> getUserCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'GPS_DISABLED';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw 'PERMISSION_DENIED';
    }

    if (permission == LocationPermission.deniedForever) throw 'PERMISSION_DENIED_FOREVER';

    return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
    );
  }

  @override
  Future<List<LatLng>> getRouteCoordinates(LatLng origin, LatLng destination) async {
    String url = "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_googleApiKey";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
          return _decodePolyline(encodedPolyline);
        }
      }
    } catch (e) {
      debugPrint("Error getting directions: $e");
    }
    return [];
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