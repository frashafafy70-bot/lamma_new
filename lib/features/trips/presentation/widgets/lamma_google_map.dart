import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

class LammaGoogleMap extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final void Function(GoogleMapController)? onMapCreated;
  final void Function(CameraPosition)? onCameraMove;
  final VoidCallback? onCameraIdle; // 👈 التعديل الجديد

  const LammaGoogleMap({
    super.key, 
    required this.initialCameraPosition,
    this.markers = const {},
    this.polylines = const {},
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle, // 👈 التعديل الجديد
  });

  @override
  State<LammaGoogleMap> createState() => _LammaGoogleMapState();
}

class _LammaGoogleMapState extends State<LammaGoogleMap> {
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/map_styles/map_theme.json').then((string) {
      if (mounted) {
        setState(() {
          _mapStyle = string;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: widget.initialCameraPosition,
      markers: widget.markers,
      polylines: widget.polylines,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle, // 👈 التعديل الجديد
      style: _mapStyle, 
      onMapCreated: (GoogleMapController controller) {
        if (widget.onMapCreated != null) {
          widget.onMapCreated!(controller);
        }
      },
    );
  }
}