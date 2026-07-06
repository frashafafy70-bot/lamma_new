import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamma_new/core/theme/app_colors.dart';

class TravelServiceCard extends StatelessWidget {
  final VoidCallback onAddTravelTap;

  const TravelServiceCard({
    super.key, 
    required this.onAddTravelTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // 🔴 تم إزالة الـ margin من هنا الاعتماد على SizedBox في الرئيسية
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h), // 🔴 تقليل لـ 16
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: const BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'حجز مسبق',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.blueAccent.shade100, 
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.directions_bus_filled_rounded,
                color: AppColors.accentGold,
                size: 24.sp,
              ),
            ],
          ),
          
          SizedBox(height: 12.h), // 🔴 تقليل المسافات
          
          Center(
            child: Text(
              'مسافر لمحافظة تانية قريباً؟',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Center(
            child: Text(
              'حدد مسارك وتاريخ رحلتك، وخلي العملاء تحجز معاك مقدماً وتشاركك التكلفة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.textMuted.shade400,
                fontSize: 12.sp,
              ),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          Container(
            width: double.infinity,
            height: 48.h, // 🔴 ارتفاع الزرار متناسق مع كارت الرادار
            decoration: BoxDecoration(
              color: AppColors.accentGold,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAddTravelTap,
                borderRadius: BorderRadius.circular(12.r),
                splashColor: AppColors.primaryDark.withValues(alpha: 0.1),
                highlightColor: AppColors.primaryDark.withValues(alpha: 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'إضافة رحلة سفر',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.edit_calendar_rounded, 
                      color: AppColors.primaryDark, 
                      size: 20.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}