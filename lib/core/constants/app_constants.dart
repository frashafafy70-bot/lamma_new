import 'package:flutter_dotenv/flutter_dotenv.dart'; // 👈 استدعاء مكتبة dotenv

class AppConstants {
  // الإحداثيات الافتراضية
  static const double fallbackLatitude = 30.0444;  // القاهرة
  static const double fallbackLongitude = 31.2357; 
  
  // مستويات الزووم (Zoom Levels)
  static const double defaultMapZoom = 16.5;
  static const double selectionMapZoom = 17.2;
  static const double mapTilt = 45.0;

  // 🟢 جلب مفتاح خرائط جوجل بأمان من ملف الـ .env
  // تأكد إن اسم المتغير جوه ملف .env هو GOOGLE_MAPS_API_KEY
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

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
}