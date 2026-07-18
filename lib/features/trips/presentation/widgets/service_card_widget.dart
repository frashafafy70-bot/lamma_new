import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/models/trip_model.dart'; 

class ServiceCardWidget extends StatelessWidget {
  final TripEntity serviceData;

  const ServiceCardWidget({super.key, required this.serviceData});

  @override
  Widget build(BuildContext context) {
    // جلب البيانات من الـ Object مباشرة بدلاً من الـ Map
    final String serviceName = serviceData.tripCategory ?? 'رحلة بدون تصنيف';
    final Color royalGreen = const Color(0xFF1B4332);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // هنا تقدر تستخدم serviceData.id للذهاب لتفاصيل الرحلة
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: royalGreen.withAlpha(25),
                child: Icon(
                  Icons.local_taxi_rounded,
                  color: royalGreen,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              
              Expanded(
                child: Text(
                  serviceName,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.grey.shade400,
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}