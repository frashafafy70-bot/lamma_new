// ignore_for_file: use_build_context_synchronously
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';
import 'dart:async'; 
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart'; 
import 'package:url_launcher/url_launcher.dart';

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/data/models/trip_model.dart';
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';
import 'package:lamma_new/features/trips/presentation/widgets/negotiation_widget.dart'; 
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart'; 
import 'package:lamma_new/core/services/navigation_service.dart';

// 🟢 كلاس مساعد لعمل انسيابية في حركة السيارة على الخريطة
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

class _PassengerTripTrackingPageState extends State<PassengerTripTrackingPage> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _hasShownRatingDialog = false; 

  late final Stream<DocumentSnapshot> _tripLiveStream;
  StreamSubscription<DocumentSnapshot>? _tripStatusSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _previousStatus = ''; 

  // 🟢 متغيرات الأنيميشن وحركة السيارة
  AnimationController? _animationController;
  LatLng? _currentDriverPosition;
  double _markerRotation = 0.0;

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
    
    // 🟢 تهيئة متحكم الأنيميشن
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // مدة الحركة بين النقطتين
    );

    _tripLiveStream = FirebaseFirestore.instance.collection('trips').doc(widget.tripId).snapshots();

    _tripStatusSubscription = _tripLiveStream.listen((snapshot) {
      if (snapshot.exists) {
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
      } else if (status == 'accepted' || status == 'arrived' || status == 'on_the_way') {
        await _audioPlayer.play(AssetSource('audio/edite.mp3'));
      }
    } catch (e) {
      debugPrint("مشكلة في تشغيل الصوت: $e");
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _tripStatusSubscription?.cancel();
    _audioPlayer.dispose();
    _mapController?.dispose();
    super.dispose();
  }

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

  void _updateDriverMarker(GeoPoint? driverLocation) {
    if (driverLocation == null) return;
    
    LatLng newDriverPos = LatLng(driverLocation.latitude, driverLocation.longitude);
    
    if (_currentDriverPosition == null) {
      setState(() {
        _currentDriverPosition = newDriverPos;
        _drawMarkers();
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(newDriverPos));
      return;
    }

    if (_currentDriverPosition != newDriverPos) {
      _markerRotation = _getBearing(_currentDriverPosition!, newDriverPos);

      Animation<LatLng> animation = LatLngTween(
        begin: _currentDriverPosition,
        end: newDriverPos,
      ).animate(CurvedAnimation(parent: _animationController!, curve: Curves.linear));

      animation.addListener(() {
        setState(() {
          _currentDriverPosition = animation.value;
          _drawMarkers();
        });
      });

      _animationController?.forward(from: 0.0);
      _mapController?.animateCamera(CameraUpdate.newLatLng(newDriverPos));
    }
  }

  void _drawMarkers() {
    _markers.removeWhere((m) => m.markerId.value == 'driver_car');
    
    if (_currentDriverPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver_car'),
          position: _currentDriverPosition!,
          rotation: _markerRotation,
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'السائق'),
        ),
      );
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'جاري البحث عن كابتن...';
      case 'negotiating': return 'جاري التفاوض على السعر...';
      case 'accepted': return 'تم قبول الطلب، الكابتن يتجهز...';
      case 'on_the_way': return 'الكابتن في الطريق إليك...';
      case 'arrived': return 'الكابتن بالخارج!';
      case 'in_progress': return 'الرحلة جارية الآن...';
      case 'completed': return 'وصلت بالسلامة!';
      case 'cancelled': return 'تم إلغاء الرحلة';
      default: return 'جاري التحميل...';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
      case 'negotiating': return Colors.orange;
      case 'accepted':
      case 'on_the_way': return Colors.blueAccent;
      case 'arrived':
      case 'in_progress':
      case 'completed': return AppColors.royalGreen;
      case 'cancelled': return Colors.redAccent;
      default: return AppColors.primaryDark;
    }
  }

  void _showRatingDialog(BuildContext context, TripEntity trip) {
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
          title: Text('تتبع الرحلة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 18.sp)),
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
            // 🟢 استخدام الـ Model بدلاً من الـ Entity للتحويل
            TripEntity trip = TripModel.fromMap(tripData, snapshot.data!.id);
            
            bool driverAssigned = trip.driverId != null && trip.driverId!.isNotEmpty;
            
            if (trip.status == 'in_progress' || trip.status == 'arrived' || trip.status == 'accepted' || trip.status == 'on_the_way') {
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

            return Stack(
              children: [
                // الخريطة
                Positioned.fill(
                  bottom: trip.status == 'negotiating' ? 300.h : 260.h,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(trip.pickupLocation?.latitude ?? 30.0, trip.pickupLocation?.longitude ?? 31.0),
                      zoom: 15,
                    ),
                    style: _premiumMapStyle, 
                    markers: _markers,
                    onMapCreated: (controller) => _mapController = controller,
                    zoomControlsEnabled: false,
                    myLocationEnabled: true,
                  ),
                ),

                // الكارت السفلي الفخم (معدل ليتناسب مع الثلاث ملفات)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1), 
                          blurRadius: 20, 
                          spreadRadius: 2,
                          offset: const Offset(0, -5),
                        )
                      ],
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // مؤشر السحب
                        Center(
                          child: Container(
                            width: 40.w,
                            height: 5.h,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // مؤشر حالة الرحلة
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: _getStatusColor(trip.status.value).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.info_outline, color: _getStatusColor(trip.status.value), size: 24.sp),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                _getStatusText(trip.status.value),
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                              ),
                            ),
                          ],
                        ),
                        
                        const Divider(height: 24, thickness: 1),

                        // تفاصيل السائق إذا تم تعيينه
                        if (driverAssigned && trip.status != 'negotiating') ...[
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28.r,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: tripData['driverImage'] != null ? NetworkImage(tripData['driverImage']) : null,
                                child: tripData['driverImage'] == null ? Icon(Icons.person, color: Colors.grey.shade500, size: 30.sp) : null,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      trip.driverName ?? 'كابتن لَمّة',
                                      style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${tripData['carModel'] ?? 'سيارة'} • ${tripData['carPlate'] ?? 'بدون لوحة'}',
                                      style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  // زر الشات
                                  GestureDetector(
                                    onTap: () => NavigationService.navigateToTripChat(widget.tripId),
                                    child: Container(
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        color: AppColors.info.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.chat_bubble_outline, color: AppColors.info, size: 22.sp),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  // زر الاتصال
                                  GestureDetector(
                                    onTap: () async {
                                      final phone = tripData['driverPhone'] ?? '';
                                      if (phone.isNotEmpty) {
                                        final url = Uri.parse('tel:$phone');
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url);
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.phone_in_talk, color: AppColors.success, size: 22.sp),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const Divider(height: 24, thickness: 1),
                        ],

                        // تفاصيل مسار الرحلة والسعر
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('إلى:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade500)),
                                SizedBox(
                                  width: 200.w,
                                  child: Text(
                                    trip.destination ?? 'الوجهة',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('السعر:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade500)),
                                Text(
                                  '${trip.finalPrice ?? trip.price ?? '--'} ج.م',
                                  style: TextStyle(fontFamily: 'Cairo', color: AppColors.royalGreen, fontSize: 16.sp, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          ],
                        ),

                        // مسار التفاوض
                        if (trip.status == 'negotiating') ...[
                          SizedBox(height: 16.h),
                          NegotiationWidget(
                            trip: trip, 
                            isDriver: false, 
                            currentUserId: widget.passengerId,
                          ),
                        ],

                        // أزرار سريعة للإلغاء أو الانتظار
                        if (trip.status == 'pending' || trip.status == 'accepted') ...[
                          SizedBox(height: 20.h),
                          SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))
                              ),
                              onPressed: () {
                               context.read<TripActionsCubit>().cancelTripFully(tripId: widget.tripId, isDriver: false);
                              },
                              child: Text('إلغاء الرحلة', style: TextStyle(fontFamily: 'Cairo', color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                            ),
                          ),
                        ]
                      ],
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