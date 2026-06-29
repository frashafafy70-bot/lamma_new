import 'dart:convert';
import 'package:flutter/material.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class MapService {
  // 1. إعداد الـ Singleton عشان النسخة دي تكون الوحيدة في التطبيق كله
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  // 2. المتغيرات الخاصة بالـ API Key والأيقونات
  late String googleApiKey;
  BitmapDescriptor? carMarker;
  BitmapDescriptor? bikeMarker;
  BitmapDescriptor? tuktokMarker;

  // 3. دالة التهيئة (بتتنادى مرة واحدة بس في بداية التطبيق في main.dart)
  Future<void> init({required String apiKey}) async {
    googleApiKey = apiKey;
    
    // تحميل أيقونات الخريطة في الذاكرة باستخدام الطريقة الجديدة (asset)
    const ImageConfiguration config = ImageConfiguration(size: Size(48, 48));
    try {
      carMarker = await BitmapDescriptor.asset(config, 'assets/images/car_3d.png');
      bikeMarker = await BitmapDescriptor.asset(config, 'assets/images/bike_3d.png');
      tuktokMarker = await BitmapDescriptor.asset(config, 'assets/images/tuktok_3d.png');
    } catch (e) {
      debugPrint("Error loading custom markers: $e");
    }
  }

  // ==========================================
  // الدوال الأساسية للملاحة والبحث الخاصة بمشروعك
  // ==========================================

  String cleanAddress(String address) {
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

  Future<String> performReverseGeocoding(LatLng latLng) async {
    if (googleApiKey.isNotEmpty) {
      final String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$googleApiKey&language=ar";
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
            String formattedAddress = data['results'][0]['formatted_address'];
            return cleanAddress(formattedAddress);
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
        
        return cleanAddress(address);
      }
    } catch (e) {
      debugPrint("Native Geocoding Error: $e");
    }

    return "إحداثيات: ${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}";
  }

  Future<List<dynamic>> searchPlaces(String input) async {
    if (input.isEmpty) return [];
    String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$googleApiKey&language=ar&components=country:eg";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body)['predictions'] ?? [];
      }
    } catch (e) {
      debugPrint("Error searching places: $e");
    }
    return [];
  }

  Future<LatLng?> getPlaceDetails(String placeId) async {
    String url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleApiKey";
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

  Future<List<LatLng>> getRouteCoordinates(LatLng origin, LatLng destination) async {
    String url = "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleApiKey";
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