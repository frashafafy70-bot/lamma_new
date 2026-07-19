// ignore_for_file: use_build_context_synchronously

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/app_localizations.dart';

// استيراد الخريطة الموحدة والـ MapService
import 'package:lamma_new/features/trips/presentation/widgets/lamma_google_map.dart';
import 'package:lamma_new/features/trips/data/services/map_service.dart';

// ==========================================
// كلاس مساعد لعمل انسيابية (Smoothness) بين الإحداثيات
// ==========================================
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required super.begin, required super.end});

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
  final Set<Polyline> polylines;

  const LiveTrackingMapHeader({
    super.key,
    required this.passengerLocation,
    required this.driverLocation,
    this.polylines = const {},
  });

  @override
  State<LiveTrackingMapHeader> createState() => _LiveTrackingMapHeaderState();
}

class _LiveTrackingMapHeaderState extends State<LiveTrackingMapHeader>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  AnimationController? _animationController;
  LatLng? _currentDriverPosition;
  double _markerRotation = 0.0;
  bool _isFirstCameraMove = true;

  // 🟢 تعريف المتغيرات لتخزين الترجمة لمنع استدعائها مراراً داخل الأنيميشن
  late String _myLocationTitle;
  late String _driverTitle;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.driverLocation != null) {
      _currentDriverPosition = LatLng(
          widget.driverLocation!.latitude, widget.driverLocation!.longitude);
    }
  }

  // 🟢 جلب الترجمة مرة واحدة فقط عند التهيئة أو تغير لغة التطبيق
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _myLocationTitle = l10n.myLocationMarker;
    _driverTitle = l10n.driverMarker;
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

    if (widget.driverLocation != null) {
      LatLng newDriverLoc = LatLng(
          widget.driverLocation!.latitude, widget.driverLocation!.longitude);

      if (_currentDriverPosition != null &&
          _currentDriverPosition != newDriverLoc) {
        _markerRotation = _getBearing(_currentDriverPosition!, newDriverLoc);

        Animation<LatLng> animation = LatLngTween(
          begin: _currentDriverPosition,
          end: newDriverLoc,
        ).animate(CurvedAnimation(
            parent: _animationController!, curve: Curves.linear));

        animation.addListener(() {
          setState(() {
            _currentDriverPosition = animation.value;
            _updateMarkers();
          });
        });

        _animationController?.forward(from: 0.0);

        if (!_isFirstCameraMove) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(newDriverLoc));
        }
      } else if (_currentDriverPosition == null) {
        _currentDriverPosition = newDriverLoc;
        _updateMarkers();
      }
    }
  }

  double _getBearing(LatLng begin, LatLng end) {
    double lat1 = begin.latitude * math.pi / 180.0;
    double lon1 = begin.longitude * math.pi / 180.0;
    double lat2 = end.latitude * math.pi / 180.0;
    double lon2 = end.longitude * math.pi / 180.0;

    double dLon = lon2 - lon1;
    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double bearing = math.atan2(y, x) * 180.0 / math.pi;
    return (bearing + 360.0) % 360.0;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMarkers();

    Future.delayed(const Duration(milliseconds: 300), () {
      _zoomToFitMarkers();
    });
  }

  void _updateMarkers() {
    if (!mounted) return;

    setState(() {
      _markers.clear();

      if (widget.passengerLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('passenger_marker'),
            position: LatLng(widget.passengerLocation!.latitude,
                widget.passengerLocation!.longitude),
            infoWindow: InfoWindow(
                title: _myLocationTitle), // 🟢 استخدام المتغير الجاهز
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueYellow),
          ),
        );
      }

      if (_currentDriverPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('driver_marker'),
            position: _currentDriverPosition!,
            rotation: _markerRotation,
            anchor: const Offset(0.5, 0.5),
            infoWindow:
                InfoWindow(title: _driverTitle), // 🟢 استخدام المتغير الجاهز
            icon: MapService().carMarker ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
    });
  }

  void _zoomToFitMarkers() {
    if (_mapController == null) return;

    if (widget.passengerLocation != null && widget.driverLocation != null) {
      LatLng pLoc = LatLng(widget.passengerLocation!.latitude,
          widget.passengerLocation!.longitude);
      LatLng dLoc = LatLng(
          widget.driverLocation!.latitude, widget.driverLocation!.longitude);

      LatLngBounds bounds;
      if (pLoc.latitude > dLoc.latitude) {
        bounds = LatLngBounds(southwest: dLoc, northeast: pLoc);
      } else {
        bounds = LatLngBounds(southwest: pLoc, northeast: dLoc);
      }

      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60.h));
      _isFirstCameraMove = false;
    } else if (widget.passengerLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(widget.passengerLocation!.latitude,
                widget.passengerLocation!.longitude),
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
      defaultCenter = LatLng(widget.passengerLocation!.latitude,
          widget.passengerLocation!.longitude);
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
      child: LammaGoogleMap(
        initialCameraPosition: CameraPosition(
          target: defaultCenter,
          zoom: 17.5,
          tilt: 45.0,
        ),
        markers: _markers,
        polylines: widget.polylines,
        onMapCreated: _onMapCreated,
      ),
    );
  }
}
