import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../cubit/family_tracking_cubit.dart';
import '../../cubit/family_tracking_state.dart';

class FamilyTripTrackingPage extends StatefulWidget {
  final String childUid;
  final String childName;

  const FamilyTripTrackingPage({
    super.key,
    required this.childUid,
    required this.childName,
  });

  @override
  State<FamilyTripTrackingPage> createState() => _FamilyTripTrackingPageState();
}

class _FamilyTripTrackingPageState extends State<FamilyTripTrackingPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FamilyTrackingCubit()..startTracking(widget.childUid),
      child: Scaffold(
        appBar: AppBar(
          title: Text('تتبع رحلة ${widget.childName}'),
          centerTitle: true,
        ),
        body: BlocConsumer<FamilyTrackingCubit, FamilyTrackingState>(
          listener: (context, state) {
            if (state is FamilyTrackingActive && state.driverLat != null && state.driverLng != null) {
              final position = LatLng(state.driverLat!, state.driverLng!);
              _updateDriverMarker(position);
              
              // تحريك الكاميرا لموقع الكابتن بسلاسة
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: position, zoom: 16.5),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is FamilyTrackingLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is FamilyTrackingNoActiveTrip) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_off, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد رحلة نشطة حالياً لـ ${widget.childName}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }

            if (state is FamilyTrackingError) {
              return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
            }

            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(31.2001, 29.9187), // إحداثيات افتراضية
                    zoom: 14,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  zoomControlsEnabled: false, // خريطة نظيفة بدون أزرار تكبير
                  myLocationButtonEnabled: false,
                  myLocationEnabled: false,
                  mapToolbarEnabled: false,
                  markers: _markers,
                ),
                
                // بطاقة تفاصيل الرحلة الموسعة في أسفل الشاشة
                if (state is FamilyTrackingActive)
                  Positioned(
                    bottom: 20,
                    left: 15,
                    right: 15,
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // السطر الأول: الحالة والسعر
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.directions_car, color: Colors.blueAccent),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getTripStatusArabic(state.tripData['status'] ?? ''),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${state.tripData['price'] ?? '0'} ج.م',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            
                            // بيانات الكابتن والوقت
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('الكابتن: ${state.tripData['driverName'] ?? 'غير محدد'}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text('السيارة: ${state.tripData['carModel'] ?? 'غير محدد'}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      state.tripData['tripTime'] ?? 'جاري الحساب',
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            
                            // مسار الرحلة (مكان التحرك والواجهة)
                            Row(
                              children: [
                                Column(
                                  children: [
                                    const Icon(Icons.circle, size: 12, color: Colors.green),
                                    Container(width: 2, height: 25, color: Colors.grey.shade400),
                                    const Icon(Icons.location_on, size: 16, color: Colors.red),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.tripData['pickupAddress'] ?? 'مكان التحرك غير محدد',
                                        style: const TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis),
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        state.tripData['destinationAddress'] ?? 'الواجهة غير محددة',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
              ],
            );
          },
        ),
      ),
    );
  }

  void _updateDriverMarker(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('driver_marker'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'موقع الكابتن'),
        ),
      };
    });
  }

  String _getTripStatusArabic(String status) {
    switch (status) {
      case 'accepted': return 'الكابتن في الطريق';
      case 'arrived': return 'الكابتن بالخارج';
      case 'in_progress': return 'الرحلة جارية';
      default: return 'جاري المعالجة';
    }
  }
}