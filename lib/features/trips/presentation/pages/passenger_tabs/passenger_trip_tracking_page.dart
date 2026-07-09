// ignore_for_file: use_build_context_synchronously

import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart'; 

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/data/models/trip_model.dart';
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';
import 'package:lamma_new/features/trips/presentation/widgets/negotiation_widget.dart'; 
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart'; 
import 'package:lamma_new/core/services/navigation_service.dart';

class PassengerTripTrackingPage extends StatefulWidget {
  final String tripId;
  final String passengerId; 

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
  bool _hasShownRatingDialog = false; 

  late final Stream<DocumentSnapshot> _tripLiveStream;
  StreamSubscription<DocumentSnapshot>? _tripStatusSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _previousStatus = ''; 
  
  @override
  void initState() {
    super.initState();
    
    _tripLiveStream = FirebaseFirestore.instance.collection('trips').doc(widget.tripId).snapshots();

    _tripStatusSubscription = _tripLiveStream.listen((snapshot) {
      if (snapshot.exists) {
        // 🟢 تم حل مشكلة الـ Casting هنا
        var data = snapshot.data() as Map<String, dynamic>?;
        String currentStatus = data?['status'] ?? '';
        
        if (_previousStatus.isNotEmpty && currentStatus != _previousStatus) {
          _playSoundForStatus(currentStatus);
        }
        
        _previousStatus = currentStatus; 
      }
    });
  }

  Future<void> _playSoundForStatus(String status) async {
    try {
      if (status == 'negotiating') {
        await _audioPlayer.play(AssetSource('audio/ping_pong.mp3')); 
      } else if (status == 'cancelled') {
        await _audioPlayer.play(AssetSource('audio/cancell.mp3')); 
      } else if (status == 'completed') {
        await _audioPlayer.play(AssetSource('audio/notification.mp3')); 
      } else if (status == 'accepted' || status == 'arrived') {
        await _audioPlayer.play(AssetSource('audio/edite.mp3'));
      }
    } catch (e) {
      debugPrint("مشكلة في تشغيل الصوت: $e");
    }
  }

  @override
  void dispose() {
    _tripStatusSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updateDriverMarker(GeoPoint? driverLocation) {
    if (driverLocation == null) return;
    
    LatLng driverPos = LatLng(driverLocation.latitude, driverLocation.longitude);
    
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver_car');
      _markers.add(
        Marker(
          markerId: const MarkerId('driver_car'),
          position: driverPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'السائق'),
        ),
      );
    });

    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(driverPos));
    }
  }

  void _showRatingDialog(BuildContext context, TripModel trip) {
    int selectedRating = 5;
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
              elevation: 10,
              backgroundColor: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.royalGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle_rounded, color: AppColors.royalGreen, size: 50.sp),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'الرحلة انتهت بنجاح!',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'ما تقييمك للكابتن ${trip.driverName ?? ''}؟',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey.shade700),
                    ),
                    SizedBox(height: 20.h),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setStateDialog(() => selectedRating = index + 1);
                          },
                          child: Icon(
                            index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: AppColors.accentGold,
                            size: 40.sp,
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 20.h),

                    TextField(
                      controller: commentController,
                      maxLines: 2,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: 'أضف تعليقاً (اختياري)...',
                        hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          context.read<TripActionsCubit>().submitRating(
                            tripId: trip.id ?? widget.tripId, 
                            rating: selectedRating.toDouble(), 
                            comment: commentController.text.trim()
                          );
                          Navigator.pop(dialogContext); 
                          Navigator.pop(context); 
                        },
                        child: Text('إرسال التقييم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: Colors.white)),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); 
                        Navigator.pop(context); 
                      },
                      child: Text('تخطي', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            );
          }
        );
      }
    );
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
          stream: _tripLiveStream, 
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
            
            if (trip.status == 'in_progress' || trip.status == 'arrived') {
               WidgetsBinding.instance.addPostFrameCallback((_) {
                 _updateDriverMarker(tripData['driverLocation']);
               });
            }

            if (trip.status == 'completed' && !_hasShownRatingDialog) {
              _hasShownRatingDialog = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showRatingDialog(context, trip);
              });
            }

            return Column(
              children: [
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

                          if (trip.status == 'negotiating')
                            NegotiationWidget(
                              trip: trip, 
                              isDriver: false, 
                              currentUserId: widget.passengerId,
                            ),

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
                                   NavigationService.navigateToTripChat(widget.tripId);
                                 },
                                 icon: const Icon(Icons.chat, color: Colors.white),
                                 label: const Text('محادثة السائق', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                               ),
                             ),
                          ],
                          
                          if (trip.status == 'completed') ...[
                            Center(
                               child: Text(
                                 'وصلت بالسلامة! الرحلة انتهت.',
                                 style: TextStyle(fontFamily: 'Cairo', fontSize: 18.sp, color: AppColors.royalGreen, fontWeight: FontWeight.bold),
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