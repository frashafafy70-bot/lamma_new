import 'dart:math' as math; // ضفنا دي عشان حساب زاوية دوران العربية
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

// ==========================================
// كلاس مساعد لعمل انسيابية (Smoothness) بين الإحداثيات
// ==========================================
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end}) : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}

class LiveTrackingMapHeader extends StatefulWidget {
  final GeoPoint? passengerLocation;
  final GeoPoint? driverLocation;

  const LiveTrackingMapHeader({
    super.key,
    required this.passengerLocation,
    required this.driverLocation,
  });

  @override
  State<LiveTrackingMapHeader> createState() => _LiveTrackingMapHeaderState();
}

class _LiveTrackingMapHeaderState extends State<LiveTrackingMapHeader> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // متغيرات الأنيميشن
  AnimationController? _animationController;
  LatLng? _currentDriverPosition;
  double _markerRotation = 0.0;
  bool _isFirstCameraMove = true;

  final String _premiumMapStyle = '''[
    {"elementType": "geometry", "stylers": [{"color": "#f5f5f5"}]},
    {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#f5f5f5"}]},
    {"featureType": "administrative.land_parcel", "elementType": "labels.text.fill", "stylers": [{"color": "#bdbdbd"}]},
    {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#eeeeee"}]},
    {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]},
    {"featureType": "road.arterial", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
    {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#dadada"}]},
    {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#c9c9c9"}]},
    {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}]}
  ]''';

  @override
  void initState() {
    super.initState();
    // تهيئة متحكم الأنيميشن لمدة ثانية واحدة (لتناسب معدل تحديث الفايربيز)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.driverLocation != null) {
      _currentDriverPosition = LatLng(widget.driverLocation!.latitude, widget.driverLocation!.longitude);
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LiveTrackingMapHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    // التحقق مما إذا كان موقع الكابتن قد تغير في الفايربيز
    if (widget.driverLocation != null) {
      LatLng newDriverLoc = LatLng(widget.driverLocation!.latitude, widget.driverLocation!.longitude);
      
      if (_currentDriverPosition != null && _currentDriverPosition != newDriverLoc) {
        // 1. حساب اتجاه دوران العربية
        _markerRotation = _getBearing(_currentDriverPosition!, newDriverLoc);

        // 2. تشغيل الأنيميشن لتحريك الماركر بنعومة
        Animation<LatLng> animation = LatLngTween(
          begin: _currentDriverPosition!,
          end: newDriverLoc,
        ).animate(CurvedAnimation(parent: _animationController!, curve: Curves.linear));

        animation.addListener(() {
          setState(() {
            _currentDriverPosition = animation.value;
            _updateMarkers();
          });
        });

        _animationController?.forward(from: 0.0);

        // 3. تحريك الكاميرا بنعومة لتتبع الكابتن بدون عمل Zoom Out يضايق العميل
        if (!_isFirstCameraMove) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(newDriverLoc));
        }

      } else if (_currentDriverPosition == null) {
        _currentDriverPosition = newDriverLoc;
        _updateMarkers();
      }
    }
  }

  // دالة رياضية لحساب زاوية دوران الماركر بناءً على النقطة القديمة والجديدة
  double _getBearing(LatLng begin, LatLng end) {
    double lat1 = begin.latitude * math.pi / 180.0;
    double lon1 = begin.longitude * math.pi / 180.0;
    double lat2 = end.latitude * math.pi / 180.0;
    double lon2 = end.longitude * math.pi / 180.0;

    double dLon = lon2 - lon1;
    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double bearing = math.atan2(y, x) * 180.0 / math.pi;
    return (bearing + 360.0) % 360.0;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMarkers();
    
    // تأخير بسيط لضمان بناء الخريطة قبل عمل الزووم الاحترافي
    Future.delayed(const Duration(milliseconds: 300), () {
      _zoomToFitMarkers();
    });
  }

  void _updateMarkers() {
    if (!mounted) return;
    setState(() {
      _markers.clear();

      // 1. ماركر موقع الراكب (أنت)
      if (widget.passengerLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('passenger_marker'),
            position: LatLng(widget.passengerLocation!.latitude, widget.passengerLocation!.longitude),
            infoWindow: const InfoWindow(title: 'موقعي'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          ),
        );
      }

      // 2. ماركر موقع الكابتن (هنا التعديل لإضافة النعومة والدوران)
      if (_currentDriverPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('driver_marker'),
            position: _currentDriverPosition!,
            rotation: _markerRotation, // تطبيق الدوران ليواجه الطريق
            anchor: const Offset(0.5, 0.5), // جعل نقطة الارتكاز في المنتصف لتجنب اهتزاز الأيقونة عند الدوران
            infoWindow: const InfoWindow(title: 'الكابتن'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), 
            // 💡 نصيحة: استبدل hueBlue بصورة سيارة (BitmapDescriptor.fromAssetImage) للحصول على أفضل شكل
          ),
        );
      }
    });
  }

  void _zoomToFitMarkers() {
    if (_mapController == null) return;

    if (widget.passengerLocation != null && widget.driverLocation != null) {
      LatLng pLoc = LatLng(widget.passengerLocation!.latitude, widget.passengerLocation!.longitude);
      LatLng dLoc = LatLng(widget.driverLocation!.latitude, widget.driverLocation!.longitude);

      LatLngBounds bounds;
      if (pLoc.latitude > dLoc.latitude) {
        bounds = LatLngBounds(southwest: dLoc, northeast: pLoc);
      } else {
        bounds = LatLngBounds(southwest: pLoc, northeast: dLoc);
      }

      // تحريك الكاميرا لاحتواء النقطتين مع بادينج مناسب
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60.h));
      _isFirstCameraMove = false; // تم الانتهاء من الزووم الأول

    } else if (widget.passengerLocation != null) {
      // زووم احترافي بـ Tilt 3D إذا كانت نقطة واحدة
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(widget.passengerLocation!.latitude, widget.passengerLocation!.longitude),
            zoom: 17.5,
            tilt: 45.0,
          ),
        ),
      );
      _isFirstCameraMove = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    LatLng defaultCenter = const LatLng(30.0444, 31.2357);
    if (widget.passengerLocation != null) {
      defaultCenter = LatLng(widget.passengerLocation!.latitude, widget.passengerLocation!.longitude);
    }

    return Container(
      height: 220.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: defaultCenter,
          zoom: 17.5,  // زووم قريب واحترافي
          tilt: 45.0,  // زاوية الميل ليعطي شكل 3D
        ),
        style: _premiumMapStyle, 
        markers: _markers,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: false,
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: true, 
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(
            () => EagerGestureRecognizer(),
          ),
        },
        onMapCreated: _onMapCreated,
      ),
    );
  }
}