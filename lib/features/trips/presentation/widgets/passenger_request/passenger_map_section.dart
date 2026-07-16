import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/presentation/widgets/lamma_google_map.dart';

class PassengerMapSection extends StatelessWidget {
  final bool isLoadingMap;
  final LatLng? pickupLocation;
  final double fallbackLatitude;
  final double fallbackLongitude;
  final double closeZoom;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final bool isPickingMap;
  final bool isMapFullscreen;
  final double actualContainerHeight;
  
  // Callbacks للتواصل مع الملف الأساسي
  final MapCreatedCallback onMapCreated;
  final ArgumentCallback<LatLng> onMapTap;
  final CameraPositionCallback onCameraMove;
  final VoidCallback onCameraIdle;

  const PassengerMapSection({
    super.key,
    required this.isLoadingMap,
    required this.pickupLocation,
    required this.fallbackLatitude,
    required this.fallbackLongitude,
    required this.closeZoom,
    required this.markers,
    required this.polylines,
    required this.isPickingMap,
    required this.isMapFullscreen,
    required this.actualContainerHeight,
    required this.onMapCreated,
    required this.onMapTap,
    required this.onCameraMove,
    required this.onCameraIdle,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingMap) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentGold),
      );
    }

    return LammaGoogleMap(
      initialCameraPosition: CameraPosition(
        target: pickupLocation ?? LatLng(fallbackLatitude, fallbackLongitude), 
        zoom: closeZoom,
      ),
      markers: markers,
      polylines: polylines,
      showCenterPin: isPickingMap,
      // التحكم الديناميكي في أبعاد الخريطة بناءً على حالة الكيبورد والشاشة
      mapPadding: EdgeInsets.only(
        bottom: isMapFullscreen ? 90.h : actualContainerHeight + 10.h, 
        top: isPickingMap ? 100.h : 0,
      ),
      onTap: onMapTap,
      onMapCreated: onMapCreated,
      onCameraMove: onCameraMove,
      onCameraIdle: onCameraIdle,
    );
  }
}