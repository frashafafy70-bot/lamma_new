// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// استدعاء ملف الألوان المركزي
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';
import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart';

// الخريطة المخصصة
import 'package:lamma_new/features/trips/presentation/widgets/driver_live_map.dart'; 

class DriverTripTrackingPage extends StatelessWidget {
  final String tripId;
  final String destination;
  final String price;
  final double? clientLat; 
  final double? clientLng;

  const DriverTripTrackingPage({
    super.key, 
    required this.tripId,
    required this.destination,
    required this.price,
    this.clientLat,
    this.clientLng,
  });

  // دالة فتح تطبيق خرائط جوجل للتوجيه الصوتي
  Future<void> _launchGoogleMapsNavigation(BuildContext context) async {
    if (clientLat == null || clientLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('موقع العميل غير متوفر حالياً', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
          backgroundColor: AppColors.error,
        ),
      );
      return; 
    }
    
    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$clientLat,$clientLng&mode=d");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا يمكن فتح خرائط جوجل', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // دالة تحديث حالة الرحلة في قاعدة البيانات
  Future<void> _updateTripStatus(String newStatus) async {
    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('تتبع الرحلة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18.sp)),
          backgroundColor: AppColors.primaryDark, 
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.navigation_rounded, color: AppColors.accentGold, size: 26.sp),
              onPressed: () => _launchGoogleMapsNavigation(context),
              tooltip: 'توجيه عبر خرائط جوجل',
            ),
            SizedBox(width: 8.w),
          ],
        ),
        body: Column(
          children: [
            // 1. الخريطة المخصصة للكابتن 
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
                child: DriverLiveMap(
                  tripId: tripId,
                  targetLat: clientLat, 
                  targetLng: clientLng,
                ), 
              ),
            ),

            // 2. كارت معلومات الرحلة في الأسفل (مربوط بـ StreamBuilder)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('trips').doc(tripId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Padding(
                    padding: EdgeInsets.all(20.w),
                    child: const Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
                  );
                }

                var tripData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                String currentStatus = tripData['status'] ?? 'accepted';

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08), 
                        blurRadius: 20, 
                        spreadRadius: 5,
                        offset: const Offset(0, -5),
                      )
                    ],
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // مؤشر سحب صغير يعطي شكل جمالي
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
                          // زرار الشات (ثابت في كل الحالات)
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
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => TripChatPage(tripId: tripId)));
                                },
                                child: Icon(Icons.chat_rounded, color: Colors.white, size: 24.sp),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          
                          // الزرار الديناميكي (بيتغير حسب الحالة)
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 50.h,
                              child: _buildDynamicActionButton(context, currentStatus),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: MediaQuery.of(context).padding.bottom), // للحماية من حواف الآيفون
                    ],
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  // ويدجت الزرار الديناميكي
  Widget _buildDynamicActionButton(BuildContext context, String status) {
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
    else {
      // حالة in_progress أو غيرها
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success, 
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        icon: Icon(Icons.check_circle_rounded, color: Colors.white, size: 20.sp),
        label: Text('إنهاء الرحلة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp)),
        onPressed: () {
          TripDialogsHelper.showRatingDialog(
            context: context, 
            docId: tripId, 
            royalGreen: AppColors.royalGreen, 
            isDriver: true,
          );
        },
      );
    }
  }
}