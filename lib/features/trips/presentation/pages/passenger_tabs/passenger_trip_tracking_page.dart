import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/data/models/trip_model.dart';
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';
// افترض أنك وضعت NegotiationWidget في مجلد الـ widgets
import 'package:lamma_new/features/trips/presentation/widgets/negotiation_widget.dart'; 

class PassengerTripTrackingPage extends StatefulWidget {
  final String tripId;
  final String passengerId; // لمطابقة الـ currentUserId في التفاوض

  const PassengerTripTrackingPage({
    super.key,
    required this.tripId,
    required this.passengerId,
  });

  @override
  State<PassengerTripTrackingPage> createState() => _PassengerTripTrackingPageState();
}

class _PassengerTripTrackingPageState extends State<PassengerTripTrackingPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  
  // دالة لتحديث ماركر السائق على الخريطة
  void _updateDriverMarker(GeoPoint? driverLocation) {
    if (driverLocation == null) return;
    
    LatLng driverPos = LatLng(driverLocation.latitude, driverLocation.longitude);
    
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver_car');
      _markers.add(
        Marker(
          markerId: const MarkerId('driver_car'),
          position: driverPos,
          // يمكنك تغيير الأيقونة لأيقونة سيارة مخصصة
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'السائق'),
        ),
      );
    });

    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(driverPos));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primaryDark,
          title: Text('رحلتي', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 18.sp)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('trips').doc(widget.tripId).snapshots(),
          builder: (context, snapshot) {
            
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryDark));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text('عفواً، بيانات الرحلة غير متاحة.', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp)),
              );
            }

            var tripData = snapshot.data!.data() as Map<String, dynamic>;
            TripModel trip = TripModel.fromMap(tripData, snapshot.data!.id);
            
            // تحديث موقع السائق لو الرحلة بدأت
            if (trip.status == 'in_progress' || trip.status == 'arrived') {
               WidgetsBinding.instance.addPostFrameCallback((_) {
                 _updateDriverMarker(tripData['driverLocation']);
               });
            }

            return Column(
              children: [
                // الخريطة
                Expanded(
                  flex: 5,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(trip.pickupLocation?.latitude ?? 30.0, trip.pickupLocation?.longitude ?? 31.0),
                      zoom: 15,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) => _mapController = controller,
                    zoomControlsEnabled: false,
                  ),
                ),

                // كارت معلومات الرحلة والتفاوض
                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08), 
                          blurRadius: 15, 
                          offset: const Offset(0, -5),
                        )
                      ],
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إلى: ${trip.destination}', 
                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'السعر: ${trip.finalPrice ?? trip.price ?? 'غير محدد'} ج.م', 
                            style: TextStyle(fontFamily: 'Cairo', color: AppColors.success, fontSize: 15.sp, fontWeight: FontWeight.bold),
                          ),
                          const Divider(height: 30),

                          // لو الحالة تفاوض، نعرض ويدجت التفاوض
                          if (trip.status == 'negotiating')
                            NegotiationWidget(
                              trip: trip, 
                              isDriver: false, 
                              currentUserId: widget.passengerId,
                            ),

                          // لو السائق في الطريق أو وصل
                          if (trip.status == 'in_progress' || trip.status == 'arrived') ...[
                             Center(
                               child: Text(
                                 trip.status == 'arrived' ? 'السائق بالخارج' : 'السائق في الطريق إليك...',
                                 style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                               ),
                             ),
                             SizedBox(height: 20.h),
                             SizedBox(
                               width: double.infinity,
                               height: 50.h,
                               child: ElevatedButton.icon(
                                 style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
                                 onPressed: () {
                                   Navigator.push(context, MaterialPageRoute(builder: (context) => TripChatPage(tripId: widget.tripId)));
                                 },
                                 icon: const Icon(Icons.chat, color: Colors.white),
                                 label: const Text('محادثة السائق', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                               ),
                             ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }
}