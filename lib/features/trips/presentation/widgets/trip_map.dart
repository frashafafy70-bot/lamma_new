// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class TripMap extends StatefulWidget {
  const TripMap({super.key});

  @override
  State<TripMap> createState() => _TripMapState();
}

class _TripMapState extends State<TripMap> {
  GoogleMapController? _mapController;
  
  LatLng _centerPosition = const LatLng(30.0444, 31.2357); 
  String _currentAddress = 'جاري تحديد الموقع...';
  bool _isLoadingAddress = true;
  bool _isGettingLocation = false;

  // ستايل خريطة فخم (فاتح) ليتناسب مع التطبيقات العالمية
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
    _getCurrentUserLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
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
        SnackBar(content: Text(message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: const Color(0xFF131E31)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // عشان الخريطة تاخد الشاشة كلها
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
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.black87), // سهم رجوع مناسب للعربي
          ),
        ),
      ),
      body: Stack(
        children: [
          // 🟢 1. الخريطة في الخلفية
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _centerPosition, zoom: 16.0),
            style: _premiumMapStyle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, 
            zoomControlsEnabled: false,
            mapToolbarEnabled: false, 
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
            },
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              _centerPosition = position.target;
              if (!_isLoadingAddress) setState(() => _isLoadingAddress = true);
            },
            onCameraIdle: () => _getAddressFromLatLng(_centerPosition),
          ),

          // 🟢 2. الماركر الثابت الفخم في منتصف الشاشة
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 60.h), // الرفع لضمان إن النقطة هي المركز الحقيقي
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // كارت العنوان العائم (Where from)
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
                                Text('نقطة الانطلاق', style: TextStyle(color: Colors.grey.shade600, fontSize: 11.sp, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                Text(
                                  _currentAddress,
                                  style: TextStyle(color: Colors.black, fontSize: 13.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(Icons.arrow_forward_ios, size: 14.sp, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // أيقونة الشخص (الأسود)
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    child: Icon(Icons.emoji_people_rounded, color: Colors.white, size: 26.sp),
                  ),
                  SizedBox(height: 4.h),
                  // نقطة المركز الحقيقية (Bullseye)
                  Container(
                    width: 14.w,
                    height: 14.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 3.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🟢 3. زر الموقع الحالي (فوق الشيت السحابي)
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.38, // بيتضبط فوق الشيت المبدئي
            right: 16.w,
            child: FloatingActionButton(
              heroTag: 'gps_btn',
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _getCurrentUserLocation,
              child: _isGettingLocation 
                  ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.near_me_outlined, color: Colors.black87),
            ),
          ),

          // 🟢 4. الشيت السحابي הפخم (DraggableScrollableSheet)
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
                    // Handle line
                    Center(
                      child: Container(
                        width: 45.w, height: 5.h,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10.r)),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    
                    // تصنيفات الرحلة
                    Row(
                      children: [
                        _buildServiceTypeCard('رحلة عادية', Icons.directions_car_rounded, true), 
                        SizedBox(width: 12.w),
                        _buildServiceTypeCard('سفر للمحافظات', Icons.emoji_transportation_rounded, false),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // زر تأكيد الموقع والانتقال (نفس وظيفة الزرار القديم بتاعك)
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF131E31), // الكحلي بتاعك
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                          elevation: 0,
                        ),
                        onPressed: _isLoadingAddress ? null : () {
                          // إرجاع البيانات زي ما كنت عاملها بالظبط عشان متأثرش على باقي التطبيق
                          Navigator.pop(context, {
                            'address': _currentAddress,
                            'location': GeoPoint(_centerPosition.latitude, _centerPosition.longitude),
                          });
                        },
                        child: Text(
                          'تأكيد الانطلاق من هنا',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFFF3C444)),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // أمثلة لأماكن محفوظة (بتظهر لما الشيت يتسحب لفوق)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: Colors.grey.shade100, child: const Icon(Icons.home_rounded, color: Colors.black87)),
                      title: const Text('المنزل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      subtitle: const Text('إضافة عنوان المنزل', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 12)),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: Colors.grey.shade100, child: const Icon(Icons.work_rounded, color: Colors.black87)),
                      title: const Text('العمل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      subtitle: const Text('إضافة عنوان العمل', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 12)),
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

  // ويدجت الكروت (Ride / City to city)
  Widget _buildServiceTypeCard(String title, IconData iconData, bool isSelected) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: isSelected ? Border.all(color: Colors.blue.shade200, width: 1.5) : null,
        ),
        child: Column(
          children: [
            Icon(iconData, size: 35.sp, color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Cairo', 
                fontSize: 13.sp, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.blue.shade800 : Colors.grey.shade700
              ),
            ),
          ],
        ),
      ),
    );
  }
}