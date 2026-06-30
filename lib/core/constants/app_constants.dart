class AppConstants {
  // تم إزالة استدعاء مكتبة جوجل ماب وجعل الإحداثيات أرقام منفصلة
  static const double fallbackLatitude = 30.0444;  // القاهرة
  static const double fallbackLongitude = 31.2357; 
  
  // مستويات الزووم (Zoom Levels)
  static const double defaultMapZoom = 16.5;
  static const double selectionMapZoom = 17.2;
  static const double mapTilt = 45.0;

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