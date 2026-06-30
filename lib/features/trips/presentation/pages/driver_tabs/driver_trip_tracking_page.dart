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

class DriverTripTrackingPage extends StatefulWidget {
  final String tripId;

  // شيلنا كل المتغيرات الثابتة من هنا، مش محتاجين غير الـ ID وهنجيب الباقي "لايف"
  const DriverTripTrackingPage({
    super.key, 
    required this.tripId,
  });

  @override
  State<DriverTripTrackingPage> createState() => _DriverTripTrackingPageState();
}

class _DriverTripTrackingPageState extends State<DriverTripTrackingPage> {

  // دالة فتح تطبيق خرائط جوجل للتوجيه الصوتي (بتاخد الإحداثيات الحية)
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

  // دالة تحديث حالة الرحلة في قاعدة البيانات بشكل آمن
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
        // الاستماع للرحلة مرة واحدة بس، وكل الصفحة تتبني على أساسها
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('trips').doc(widget.tripId).snapshots(),
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
            
            // استخراج البيانات "الحية" في كل ثانية
            String currentStatus = tripData['status'] ?? 'accepted';
            String destination = tripData['destination'] ?? 'وجهة غير محددة';
            String price = tripData['price']?.toString() ?? '0';
            
            // قراءة الإحداثيات لو موجودة كـ GeoPoint في الفايربيز
            GeoPoint? pickupGeo = tripData['pickupLocation'];
            double? clientLat = pickupGeo?.latitude;
            double? clientLng = pickupGeo?.longitude;

            return Column(
              children: [
                // AppBar مدمج جوه العمود عشان نقدر نمررله اللوكيشن الحي لزرار النافيجيشن
                Container(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  color: AppColors.primaryDark,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'تتبع الرحلة', 
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18.sp, color: Colors.white)
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.navigation_rounded, color: AppColors.accentGold, size: 26.sp),
                        onPressed: () => _launchGoogleMapsNavigation(clientLat, clientLng),
                        tooltip: 'توجيه عبر خرائط جوجل',
                      ),
                      SizedBox(width: 8.w),
                    ],
                  ),
                ),

                // 1. الخريطة المخصصة (بتاخد الإحداثيات الحية، لو العميل اتحرك الخريطة هتتحدث)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
                    child: DriverLiveMap(
                      tripId: widget.tripId,
                      targetLat: clientLat, 
                      targetLng: clientLng,
                    ), 
                  ),
                ),

                // 2. كارت معلومات الرحلة في الأسفل 
                Container(
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

  // ويدجت الزرار الديناميكي (شغال بناءً على الحالة الحية)
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
            docId: widget.tripId, 
            royalGreen: AppColors.royalGreen, 
            isDriver: true,
          );
        },
      );
    }
  }
}