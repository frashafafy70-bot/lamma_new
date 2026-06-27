import 'dart:convert';
import 'package:flutter/foundation.dart'; // 🟢 ضروري لـ debugPrint
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class MapService {
  final String googleApiKey;

  MapService({required this.googleApiKey});

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
        // 🟢 الحل: استخدام debugPrint بدلاً من print
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
      // 🟢 الحل: استخدام debugPrint بدلاً من print
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
      // 🟢 الحل: استخدام debugPrint بدلاً من print
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
      // 🟢 الحل: استخدام debugPrint بدلاً من print
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
}