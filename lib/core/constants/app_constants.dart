import 'package:google_maps_flutter/google_maps_flutter.dart';

class AppConstants {
  // إحداثيات افتراضية (القاهرة كمثال) للرجوع إليها لو مفيش موقع
  static const LatLng fallbackLocation = LatLng(30.0444, 31.2357);
  
  // مستويات الزووم (Zoom Levels)
  static const double defaultMapZoom = 16.5;
  static const double selectionMapZoom = 17.2;
  static const double mapTilt = 45.0;

  // ستايل الخريطة
  static const String premiumMapStyle = '''[
    {
      "featureType": "poi",
      "elementType": "labels",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "transit",
      "elementType": "labels.icon",
      "stylers": [{"visibility": "off"}]
    }
  ]''';
}