import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // ==========================================
  // إعدادات الخرائط (Map Configurations)
  // ==========================================
  
  // الإحداثيات الافتراضية
  static const double fallbackLatitude = 30.0444;  // القاهرة
  static const double fallbackLongitude = 31.2357; 
  
  // مستويات الزووم (Zoom Levels)
  static const double defaultMapZoom = 16.5;
  static const double selectionMapZoom = 17.2;
  static const double mapTilt = 45.0;

  // جلب مفتاح خرائط جوجل بأمان من ملف الـ .env
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // معرفات العلامات (Marker IDs)
  static const String pickupMarkerId = 'pickup_marker_id';
  static const String destinationMarkerId = 'destination_marker_id';
  
  // معرفات المسارات (Polyline IDs)
  static const String tempRoutePolylineId = 'temp_route_polyline_id';
  static const String finalRoutePolylineId = 'final_route_polyline_id';

  // حالات تحديد الموقع (Map Selection Modes)
  static const String mapModeNone = 'none';
  static const String mapModePickup = 'pickup';
  static const String mapModeDestination = 'destination';

  // ستايل الخريطة (Premium)
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

  // ==========================================
  // ثوابت الرحلات والسفر (Trips & Travel)
  // ==========================================
  static const String travelCategory = 'سفر';
  static const String fullCarType = 'full_car';
  static const String seatsType = 'seats';
}