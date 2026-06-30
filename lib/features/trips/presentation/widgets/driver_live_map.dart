// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// استدعاء الألوان والثوابت المركزية
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/constants/app_constants.dart'; // 👈 استدعاء الثوابت

class DriverLiveMap extends StatefulWidget {
  final String tripId;
  final double? targetLat; 
  final double? targetLng;

  const DriverLiveMap({
    super.key,
    required this.tripId,
    this.targetLat,
    this.targetLng,
  });

  @override
  State<DriverLiveMap> createState() => _DriverLiveMapState();
}

class _DriverLiveMapState extends State<DriverLiveMap> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  
  // 👈 التعديل هنا لربطها بملف الثوابت
  LatLng _currentDriverPosition = const LatLng(AppConstants.fallbackLatitude, AppConstants.fallbackLongitude); 
  bool _isLoading = true;
  bool _isFollowingDriver = true; 

  final Set<Marker> _markers = {};

  final String _premiumMapStyle = '''[
    {"elementType": "geometry", "stylers": [{"color": "#f5f5f5"}]},
    {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#f5f5f5"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]}
  ]''';

  @override
  void initState() {
    super.initState();
    _startLiveTracking();
    _setupTargetMarker();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _setupTargetMarker() {
    if (widget.targetLat != null && widget.targetLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('target_location'),
          position: LatLng(widget.targetLat!, widget.targetLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'موقع الهدف'),
        ),
      );
    }
  }

  Future<void> _startLiveTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('يرجى تفعيل الـ GPS');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position initialPos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    _updateDriverLocation(initialPos);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5, 
      ),
    ).listen((Position position) {
      _updateDriverLocation(position);
    });
  }

  void _updateDriverLocation(Position position) {
    if (!mounted) return;
    
    LatLng newPos = LatLng(position.latitude, position.longitude);

    setState(() {
      _currentDriverPosition = newPos;
      _isLoading = false;

      _markers.removeWhere((m) => m.markerId.value == 'driver_car');
      _markers.add(
        Marker(
          markerId: const MarkerId('driver_car'),
          position: newPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'موقعي'),
        ),
      );
    });

    if (_isFollowingDriver && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newPos, zoom: 17.5, tilt: 40), 
        ),
      );
    }

    _syncLocationToFirebase(newPos);
  }

  Future<void> _syncLocationToFirebase(LatLng pos) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).update({
        'driverLocation': GeoPoint(pos.latitude, pos.longitude),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("خطأ في تحديث موقع الكابتن: $e");
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryDark));
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _currentDriverPosition, zoom: 17.5, tilt: 40),
          style: _premiumMapStyle,
          myLocationEnabled: false, 
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          markers: _markers,
          onMapCreated: (controller) => _mapController = controller,
          onCameraMoveStarted: () {
            setState(() => _isFollowingDriver = false);
          },
        ),

        Positioned(
          bottom: 20.h,
          right: 16.w,
          child: FloatingActionButton(
            heroTag: 'recenter_driver_map',
            backgroundColor: _isFollowingDriver ? AppColors.primaryDark : Colors.white,
            onPressed: () {
              setState(() => _isFollowingDriver = true);
              if (_mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: _currentDriverPosition, zoom: 17.5, tilt: 40),
                  ),
                );
              }
            },
            child: Icon(
              Icons.my_location_rounded, 
              color: _isFollowingDriver ? AppColors.accentGold : AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }
}