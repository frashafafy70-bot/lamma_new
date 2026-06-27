import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 🟢 تمت إضافة مكتبة المقاسات

class ServiceSquareCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const ServiceSquareCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      // 🟢 تطبيق r
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          // 🟢 تطبيق r
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5)
            )
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              // 🟢 تطبيق w
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle
              ),
              // 🟢 تطبيق sp
              child: Icon(icon, size: 36.sp, color: iconColor)
            ),
            // 🟢 تطبيق h
            SizedBox(height: 12.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                // 🟢 تطبيق sp
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: const Color(0xFF0F172A)
              )
            ),
            // 🟢 تطبيق h
            SizedBox(height: 4.h),
            Padding(
              // 🟢 تطبيق w
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  // 🟢 تطبيق sp
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                  fontFamily: 'Cairo'
                )
              )
            ),
          ],
        ),
      ),
    );
  }
}