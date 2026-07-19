import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lamma_new/core/theme/app_colors.dart';

class DriverRadarCard extends StatelessWidget {
  final int activeOrdersCount;
  final VoidCallback onRadarTap; // 🔴 ضفنا دي عشان تستقبل الأكشن من بره

  const DriverRadarCard({
    super.key,
    required this.activeOrdersCount,
    required this.onRadarTap, // 🔴 مطلوب تمريرها
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryDarkLight,
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
        border: Border.all(color: AppColors.accentGoldLight, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppColors.success, blurRadius: 8)
                          ])),
                  SizedBox(width: 8.w),
                  Text('متصل وجاهز للطلبات',
                      style: TextStyle(
                          color: AppColors.success,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Icon(Icons.directions_car_rounded,
                  color: AppColors.accentGold, size: 24.sp),
            ],
          ),
          SizedBox(height: 12.h),
          Text('جاهز لاستقبال مشاوير جديدة؟',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 4.h),
          Text('ادخل على الرادار لمتابعة الطلبات المتاحة في محيطك الآن.',
              style: TextStyle(
                  color: AppColors.textMuted.shade400, fontSize: 12.sp)),
          SizedBox(height: 16.h),
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('trips')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                int radarCount =
                    snapshot.hasData ? snapshot.data!.docs.length : 0;
                int totalButtonAlerts = activeOrdersCount + radarCount;
                return Badge(
                  isLabelVisible: totalButtonAlerts > 0,
                  label: Text(totalButtonAlerts.toString(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: AppColors.error,
                  alignment: Alignment.topLeft,
                  offset: const Offset(-5, -10),
                  child: Container(
                    width: double.infinity,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: AppColors.accentGold,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            onRadarTap, // 🔴 الكارت بينفذ الأكشن اللي بيتبعتله من بره
                        borderRadius: BorderRadius.circular(12.r),
                        splashColor:
                            AppColors.primaryDark.withValues(alpha: 0.1),
                        highlightColor:
                            AppColors.primaryDark.withValues(alpha: 0.05),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('افتح الرادار الآن',
                                style: TextStyle(
                                    color: AppColors.primaryDark,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(width: 8.w),
                            Icon(Icons.sensors_rounded,
                                color: AppColors.primaryDark, size: 20.sp),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
        ],
      ),
    );
  }
}
