// ignore_for_file: use_build_context_synchronously

import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart'; 

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';
import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart';
import 'package:lamma_new/features/trips/presentation/widgets/driver_live_map.dart'; 

class DriverTripTrackingPage extends StatefulWidget {
  final String tripId;

  const DriverTripTrackingPage({
    super.key, 
    required this.tripId,
  });

  @override
  State<DriverTripTrackingPage> createState() => _DriverTripTrackingPageState();
}

class _DriverTripTrackingPageState extends State<DriverTripTrackingPage> {

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
        // 🟢 تم حل مشكلة الـ Casting هنا عشان الفلتر ميعملش Error
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
      } else if (status == 'accepted') {
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

  Future<void> _launchGoogleMapsNavigation(double? lat, double? lng) async {
    if (lat == null || lng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('موقع العميل غير متوفر حالياً', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return; 
    }
    
    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا يمكن فتح خرائط جوجل', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateTripStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في تحديث الحالة', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: StreamBuilder<DocumentSnapshot>(
          stream: _tripLiveStream,
          builder: (context, snapshot) {
            
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryDark));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text('عفواً، بيانات الرحلة غير متاحة أو تم إلغاؤها.', 
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: AppColors.error)),
              );
            }

            var tripData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            
            String currentStatus = tripData['status'] ?? 'accepted';
            String destination = tripData['destination'] ?? 'وجهة غير محددة';
            String price = tripData['price']?.toString() ?? '0';
            
            GeoPoint? pickupGeo = tripData['pickupLocation'];
            double? clientLat = pickupGeo?.latitude;
            double? clientLng = pickupGeo?.longitude;

            return Column(
              children: [
                // البار العلوي
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10.h, 
                    bottom: 16.h, 
                    left: 20.w, 
                    right: 20.w
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1B4332)], 
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B4332).withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 28),
                      ),
                      Text(
                        'تتبع الرحلة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      InkWell(
                        onTap: () => _launchGoogleMapsNavigation(clientLat, clientLng),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.navigation_rounded, color: AppColors.accentGold, size: 22.sp),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: DriverLiveMap(
                      tripId: widget.tripId,
                      targetLat: clientLat, 
                      targetLng: clientLng,
                    ), 
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000), 
                        blurRadius: 20, 
                        spreadRadius: 5,
                        offset: Offset(0, -5),
                      )
                    ],
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 5.h,
                          margin: EdgeInsets.only(bottom: 16.h),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_rounded, color: AppColors.error, size: 24.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              destination, 
                              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.textDark),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Icon(Icons.monetization_on_rounded, color: AppColors.success, size: 24.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'السعر المتفق عليه: $price جنيه', 
                            style: TextStyle(fontFamily: 'Cairo', color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 15.sp),
                          ),
                        ],
                      ),
                      
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: const Divider(color: AppColors.dividerColor),
                      ),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 50.h,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.info, 
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                ),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => TripChatPage(tripId: widget.tripId)));
                                },
                                child: Icon(Icons.chat_rounded, color: Colors.white, size: 24.sp),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 50.h,
                              child: _buildDynamicActionButton(currentStatus),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: MediaQuery.of(context).padding.bottom), 
                    ],
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildDynamicActionButton(String status) {
    if (status == 'accepted') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warning, 
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        icon: Icon(Icons.location_on, color: Colors.white, size: 20.sp),
        label: Text('أنا وصلت للعميل', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp)),
        onPressed: () => _updateTripStatus('arrived'),
      );
    } 
    else if (status == 'arrived') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark, 
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        icon: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20.sp),
        label: Text('بدء الرحلة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp)),
        onPressed: () => _updateTripStatus('in_progress'),
      );
    } 
    else if (status == 'completed') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey, 
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        icon: Icon(Icons.done_all_rounded, color: Colors.white, size: 20.sp),
        label: Text('تم إنهاء الرحلة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp)),
        onPressed: null, 
      );
    }
    else {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success, 
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        icon: Icon(Icons.check_circle_rounded, color: Colors.white, size: 20.sp),
        label: Text('إنهاء الرحلة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp)),
        onPressed: () async {
          await _updateTripStatus('completed');
          if (mounted) {
            await TripDialogsHelper.showRatingDialog(
              context: context, 
              docId: widget.tripId, 
              royalGreen: AppColors.royalGreen, 
              isDriver: true,
            );
          }
          if (mounted) {
            Navigator.pop(context);
          }
        },
      );
    }
  }
}