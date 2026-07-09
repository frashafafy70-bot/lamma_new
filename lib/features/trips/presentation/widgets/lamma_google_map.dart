import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ==========================================
// 1. شاشة الاستدعاء (لتفادي مشكلة الـ Overflow)
// ==========================================
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🟢 نقطة بداية الكاميرا (تم التعديل لإحداثيات الكويت)
    const CameraPosition initialPosition = CameraPosition(
      target: LatLng(29.3759, 47.9774),
      zoom: 12.0, // قللنا الزوم شوية لرؤية أوضح
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('خريطة لمَّة', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF1B4332),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[200],
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('سيارة'),
                Text('موتوسيكل'),
              ],
            ),
          ),
          
          const Expanded(
            child: LammaGoogleMap(
              initialCameraPosition: initialPosition,
              showCenterPin: true, 
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. كود مكون الخريطة الأساسي
// ==========================================
class LammaGoogleMap extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final void Function(GoogleMapController)? onMapCreated;
  final void Function(CameraPosition)? onCameraMove;
  final VoidCallback? onCameraIdle; 
  final void Function(LatLng)? onTap; 
  final bool showCenterPin; 
  final EdgeInsets mapPadding; 

  const LammaGoogleMap({
    super.key, 
    required this.initialCameraPosition,
    this.markers = const {},
    this.polylines = const {},
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle, 
    this.onTap, 
    this.showCenterPin = false, 
    this.mapPadding = EdgeInsets.zero, 
  });

  @override
  State<LammaGoogleMap> createState() => _LammaGoogleMapState();
}

class _LammaGoogleMapState extends State<LammaGoogleMap> {
  bool _isCameraMoving = false; 

  final String _lammaLightStyle = '''
  [
    {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#a7a7a7"}]},
    {"featureType": "landscape.natural", "elementType": "geometry.fill", "stylers": [{"color": "#e8ecd7"}]},
    {"featureType": "poi.park", "elementType": "geometry.fill", "stylers": [{"color": "#d5e0d3"}]},
    {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#ffffff"}]},
    {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#e0e0e0"}]},
    {"featureType": "road.highway", "elementType": "geometry.fill", "stylers": [{"color": "#f9e5a3"}]},
    {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#e8c973"}]},
    {"featureType": "water", "elementType": "geometry.fill", "stylers": [{"color": "#b8d1d8"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#333333"}]},
    {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]}
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
          padding: widget.mapPadding,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          myLocationEnabled: true, 
          myLocationButtonEnabled: true, 
          compassEnabled: false,
          style: _lammaLightStyle, 
          onTap: widget.onTap, 
          onMapCreated: (GoogleMapController controller) {
            if (widget.onMapCreated != null) {
              widget.onMapCreated!(controller);
            }
          },
          onCameraMoveStarted: () {
            if (widget.showCenterPin) {
              setState(() => _isCameraMoving = true);
            }
          },
          onCameraMove: widget.onCameraMove,
          onCameraIdle: () {
            if (widget.showCenterPin) {
              setState(() => _isCameraMoving = false);
            }
            if (widget.onCameraIdle != null) {
              widget.onCameraIdle!();
            }
          },
        ),
        
        if (widget.showCenterPin)
          AnimatedOpacity(
            opacity: _isCameraMoving ? 0.0 : 1.0, 
            duration: const Duration(milliseconds: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4332), 
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))
                    ]
                  ),
                  child: const Text('تأكيد الموقع هنا', style: TextStyle(color: Color(0xFFD4AF37), fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.location_on, color: Color(0xFF1B4332), size: 42), 
                const SizedBox(height: 42), 
              ],
            ),
          ),
      ],
    );
  }
}