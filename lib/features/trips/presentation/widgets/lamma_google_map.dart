import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LammaGoogleMap extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final void Function(GoogleMapController)? onMapCreated;
  final void Function(CameraPosition)? onCameraMove;
  final VoidCallback? onCameraIdle; 
  final bool showCenterPin; // 👈 التعديل الجديد: إظهار دبوس الاختيار الذكي

  const LammaGoogleMap({
    super.key, 
    required this.initialCameraPosition,
    this.markers = const {},
    this.polylines = const {},
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle, 
    this.showCenterPin = false, // الافتراضي مخفي عشان شاشات التتبع
  });

  @override
  State<LammaGoogleMap> createState() => _LammaGoogleMapState();
}

class _LammaGoogleMapState extends State<LammaGoogleMap> {
  bool _isCameraMoving = false; // 👈 حالة الكاميرا لتشغيل أنيميشن الدبوس

  // 🟢 الثيم الكحلي + الذهبي + الأخضر الملكي مدمج مباشرة لسرعة التحميل الفورية
  final String _mapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#0A192F"}] 
    },
    {
      "elementType": "labels.icon",
      "stylers": [{"visibility": "off"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8892B0"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#0A192F"}]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [{"color": "#8892B0"}]
    },
    {
      "featureType": "poi",
      "elementType": "geometry",
      "stylers": [{"color": "#112240"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8892B0"}]
    },
    {
      "featureType": "landscape.natural",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#1B4332"}] 
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#1B4332"}] 
    },
    {
      "featureType": "road",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#112240"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8892B0"}]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry",
      "stylers": [{"color": "#1D3557"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#D4AF37"}] 
    },
    {
      "featureType": "road.highway.controlled_access",
      "elementType": "geometry",
      "stylers": [{"color": "#F1C40F"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#020C1B"}] 
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#D4AF37"}]
    }
  ]
  ''';

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GoogleMap(
          initialCameraPosition: widget.initialCameraPosition,
          markers: widget.markers,
          polylines: widget.polylines,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          compassEnabled: false,
          style: _mapStyle, // استخدام الثيم المدمج 
          onMapCreated: (GoogleMapController controller) {
            if (widget.onMapCreated != null) {
              widget.onMapCreated!(controller);
            }
          },
          onCameraMoveStarted: () {
            // إخفاء الدبوس عند بدء السحب
            if (widget.showCenterPin) {
              setState(() {
                _isCameraMoving = true;
              });
            }
          },
          onCameraMove: widget.onCameraMove,
          onCameraIdle: () {
            // إظهار الدبوس عند الاستقرار وتأكيد الموقع
            if (widget.showCenterPin) {
              setState(() {
                _isCameraMoving = false;
              });
            }
            if (widget.onCameraIdle != null) {
              widget.onCameraIdle!();
            }
          },
        ),
        
        // 🟢 دبوس الموقع الذكي (يظهر فقط إذا كان showCenterPin = true)
        if (widget.showCenterPin)
          AnimatedOpacity(
            opacity: _isCameraMoving ? 0.0 : 1.0, // يختفي أثناء السحب ويظهر عند الاستقرار
            duration: const Duration(milliseconds: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))
                    ]
                  ),
                  child: const Text('تأكيد الموقع هنا', style: TextStyle(color: Color(0xFFD4AF37), fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.location_on, color: Color(0xFFD4AF37), size: 42),
                // إزاحة بسيطة لأعلى ليكون سن الدبوس في منتصف الشاشة بالضبط
                const SizedBox(height: 42), 
              ],
            ),
          ),
      ],
    );
  }
}