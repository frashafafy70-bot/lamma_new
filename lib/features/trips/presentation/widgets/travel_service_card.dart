import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TravelServiceCard extends StatelessWidget {
  final VoidCallback onAddTravelTap;

  const TravelServiceCard({
    super.key, 
    required this.onAddTravelTap,
  });

  @override
  Widget build(BuildContext context) {
    // الألوان المستوحاة من هويتك البصرية
    final Color primaryNavy = const Color(0xFF0F172A);
    final Color goldAccent = const Color(0xFFD4AF37);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h), // مسافة بينه وبين الكارت اللي تحته
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: primaryNavy,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🟢 الجزء العلوي: الأيقونة وحالة الخدمة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.directions_bus_filled_rounded, // أيقونة تعبر عن السفر
                color: goldAccent,
                size: 28.sp,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Text(
                      'حجز مسبق',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.blueAccent.shade100,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20.h),
          
          // 🟢 النصوص الأساسية
          Center(
            child: Text(
              'مسافر لمحافظة تانية قريباً؟',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Center(
            child: Text(
              'حدد مسارك وتاريخ رحلتك، وخلي العملاء تحجز معاك مقدماً وتشاركك التكلفة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey.shade400,
                fontSize: 13.sp,
              ),
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // 🟢 زر إضافة رحلة السفر الذهبي
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: onAddTravelTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: goldAccent,
                foregroundColor: primaryNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'إضافة رحلة سفر 🗓️',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}