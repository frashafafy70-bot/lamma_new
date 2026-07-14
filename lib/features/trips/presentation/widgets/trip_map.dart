// ignore_for_file: use_build_context_synchronously

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/constants/app_constants.dart'; 
import 'package:lamma_new/features/trips/presentation/widgets/lamma_google_map.dart'; 

import 'package:lamma_new/features/trips/data/repositories/map_repository_impl.dart';

class TripMap extends StatefulWidget {
  final LatLng? pickupPoint;
  final LatLng? dropoffPoint;
  final bool isTrackingMode;
  final bool isAddressSelectionMode; // 🟢 تمت الإضافة

  const TripMap({
    super.key, 
    this.pickupPoint, 
    this.dropoffPoint, 
    this.isTrackingMode = false,
    this.isAddressSelectionMode = false, // 🟢 تمت الإضافة بافتراضي false
  });

  @override
  State<TripMap> createState() => _TripMapState();
}

class _TripMapState extends State<TripMap> {
  GoogleMapController? _mapController;
  
  LatLng _centerPosition = const LatLng(AppConstants.fallbackLatitude, AppConstants.fallbackLongitude); 
  String _currentAddress = 'جاري تحديد الموقع...';
  bool _isLoadingAddress = true;
  bool _isGettingLocation = false;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    if (widget.isTrackingMode && widget.pickupPoint != null && widget.dropoffPoint != null) {
      _setupTrackingMode();
    } else {
      _getCurrentUserLocation();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _setupTrackingMode() async {
    setState(() {
      _isLoadingAddress = false;
      _centerPosition = widget.pickupPoint!;
      
      _markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickupPoint!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'نقطة الانطلاق'),
      ));
      
      _markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: widget.dropoffPoint!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'وجهة الوصول'),
      ));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapController != null) {
        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(
            min(widget.pickupPoint!.latitude, widget.dropoffPoint!.latitude),
            min(widget.pickupPoint!.longitude, widget.dropoffPoint!.longitude),
          ),
          northeast: LatLng(
            max(widget.pickupPoint!.latitude, widget.dropoffPoint!.latitude),
            max(widget.pickupPoint!.longitude, widget.dropoffPoint!.longitude),
          ),
        );
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
      }
    });

    final mapRepository = MapRepositoryImpl(); 
    
    // 🟢 التعديل: استقبال Either واستخدام fold للتعامل الآمن مع مسار الخريطة
    final routeResult = await mapRepository.getRouteCoordinates(widget.pickupPoint!, widget.dropoffPoint!);

    routeResult.fold(
      (failure) {
        debugPrint("Error fetching route: ${failure.message}");
        // يمكنك إظهار رسالة خطأ هنا إذا أردت
      },
      (routePoints) {
        if (routePoints.isNotEmpty && mounted) {
          setState(() {
            _polylines.add(Polyline(
              polylineId: const PolylineId('trip_route'),
              points: routePoints,
              color: AppColors.primaryDark,
              width: 5,
              geodesic: true,
            ));
          });
        }
      }
    );
  }

  Future<void> _getCurrentUserLocation() async {
    setState(() => _isGettingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('خدمة الموقع (GPS) مغلقة، يرجى تفعيلها.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('تم رفض صلاحية الوصول للموقع.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('صلاحيات الموقع مرفوضة نهائياً، يرجى تعديلها من الإعدادات.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: currentLatLng, zoom: 17.5, tilt: 30),
          ),
        );
      }

      setState(() => _centerPosition = currentLatLng);
      await _getAddressFromLatLng(currentLatLng);

    } catch (e) {
      _showError('حدث خطأ أثناء جلب الموقع');
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';
        if (place.street != null && place.street!.isNotEmpty && place.street != 'Unnamed Road') {
          address += '${place.street}، ';
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += '${place.subLocality}، ';
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += '${place.locality}';
        }
        
        setState(() {
          _currentAddress = address.trim().isEmpty ? 'موقع غير معروف' : address.trim();
          if (_currentAddress.endsWith('،')) {
            _currentAddress = _currentAddress.substring(0, _currentAddress.length - 1);
          }
        });
      }
    } catch (e) {
      setState(() => _currentAddress = 'موقع غير معروف');
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.primaryDark),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(right: 16.w, top: 8.h),
          child: FloatingActionButton(
            heroTag: 'back_btn',
            mini: true,
            backgroundColor: Colors.white,
            elevation: 2,
            onPressed: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_forward_rounded, color: AppColors.textDark), 
          ),
        ),
      ),
      body: Stack(
        children: [
          LammaGoogleMap(
            initialCameraPosition: CameraPosition(target: _centerPosition, zoom: 16.0),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              if (!widget.isTrackingMode) {
                _centerPosition = position.target;
                if (!_isLoadingAddress) setState(() => _isLoadingAddress = true);
              }
            },
            onCameraIdle: () {
              if (!widget.isTrackingMode) _getAddressFromLatLng(_centerPosition);
            },
          ),

          if (!widget.isTrackingMode)
            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 60.h), 
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOpacity(
                      opacity: _isLoadingAddress ? 0.5 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        constraints: BoxConstraints(maxWidth: 250.w),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('نقطة الانطلاق', style: TextStyle(color: AppColors.textMuted.shade600, fontSize: 11.sp, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                  Text(
                                    _currentAddress,
                                    style: TextStyle(color: AppColors.textDark, fontSize: 13.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textDark),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                      ),
                      child: Icon(Icons.emoji_people_rounded, color: Colors.white, size: 26.sp),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      width: 14.w,
                      height: 14.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryDark, width: 3.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: widget.isTrackingMode ? 30.h : MediaQuery.of(context).size.height * 0.38, 
            right: 16.w,
            child: FloatingActionButton(
              heroTag: 'gps_btn',
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _getCurrentUserLocation,
              child: _isGettingLocation 
                  ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2))
                  : const Icon(Icons.near_me_outlined, color: AppColors.textDark),
            ),
          ),

          if (!widget.isTrackingMode)
            DraggableScrollableSheet(
              initialChildSize: 0.35, 
              minChildSize: 0.25,     
              maxChildSize: 0.85,     
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))],
                  ),
                  child: ListView(
                    controller: scrollController, 
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    children: [
                      Center(
                        child: Container(
                          width: 45.w, height: 5.h,
                          decoration: BoxDecoration(color: AppColors.textMuted.shade300, borderRadius: BorderRadius.circular(10.r)),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      
                      // 🟢 إخفاء كروت نوع الرحلة في حالة اختيار العنوان
                      if (!widget.isTrackingMode && !widget.isAddressSelectionMode) ...[
                        Row(
                          children: [
                            _buildServiceTypeCard('رحلة عادية', Icons.directions_car_rounded, true), 
                            SizedBox(width: 12.w),
                            _buildServiceTypeCard('سفر للمحافظات', Icons.emoji_transportation_rounded, false),
                          ],
                        ),
                        SizedBox(height: 20.h),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                            elevation: 0,
                          ),
                          onPressed: _isLoadingAddress ? null : () {
                            Navigator.pop(context, {
                              'address': _currentAddress,
                              'location': GeoPoint(_centerPosition.latitude, _centerPosition.longitude),
                            });
                          },
                          child: Text(
                            // 🟢 تغيير النص بناءً على الحالة
                            widget.isAddressSelectionMode ? 'تأكيد هذا العنوان' : 'تأكيد الانطلاق من هنا',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(backgroundColor: AppColors.backgroundLight, child: const Icon(Icons.home_rounded, color: AppColors.textDark)),
                        title: const Text('المنزل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                        subtitle: const Text('إضافة عنوان المنزل', style: TextStyle(fontFamily: 'Cairo', color: AppColors.textMuted, fontSize: 12)),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(backgroundColor: AppColors.backgroundLight, child: const Icon(Icons.work_rounded, color: AppColors.textDark)),
                        title: const Text('العمل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                        subtitle: const Text('إضافة عنوان العمل', style: TextStyle(fontFamily: 'Cairo', color: AppColors.textMuted, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildServiceTypeCard(String title, IconData iconData, bool isSelected) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: isSelected ? Border.all(color: Colors.green, width: 1.5) : null,
        ),
        child: Column(
          children: [
            Icon(iconData, size: 35.sp, color: isSelected ? Colors.green : AppColors.textMuted.shade600),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Cairo', 
                fontSize: 13.sp, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.green : AppColors.textMuted.shade700
              ),
            ),
          ],
        ),
      ),
    );
  }
}