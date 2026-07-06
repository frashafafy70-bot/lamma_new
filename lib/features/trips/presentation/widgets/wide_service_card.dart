import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamma_new/core/theme/app_colors.dart'; 

class WideServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath; 
  final IconData fallbackIcon; 
  final Color fallbackColor; 
  final int badgeCount;
  final VoidCallback onTap;

  const WideServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.fallbackIcon,
    required this.fallbackColor,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryDark, 
            borderRadius: BorderRadius.circular(24.r), 
            border: Border.all(
              color: AppColors.accentGold.withValues(alpha: 0.15), 
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDarkLight, 
                blurRadius: 20, 
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24.r),
              splashColor: AppColors.accentGoldLight, 
              highlightColor: AppColors.accentGold.withValues(alpha: 0.05),
              child: Padding(
                // 🔴 تم تكبير الـ Padding العمودي لزيادة ارتفاع الكارت
                padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w), 
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 55.w, // 🔴 تكبير الدائرة الخلفية
                          height: 55.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentGold.withValues(alpha: 0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 90.w, // 🔴 تكبير الصورة لتتناسب مع الارتفاع الجديد
                          width: 90.w,
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(fallbackIcon, color: AppColors.accentGold, size: 40.sp);
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title, 
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 19.sp, // 🔴 تكبير الخط سِنة
                                fontWeight: FontWeight.bold,
                                color: Colors.white, 
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              subtitle, 
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12.sp, // 🔴 تكبير خط الوصف
                                color: AppColors.accentGold, 
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -8,
            right: -8, 
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.error, 
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.5), blurRadius: 8)],
              ),
              child: Text(
                badgeCount.toString(),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}