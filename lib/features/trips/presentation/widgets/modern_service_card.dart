import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamma_new/core/theme/app_colors.dart'; 

class ModernServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath; 
  final IconData fallbackIcon; 
  final Color fallbackColor; 
  final int badgeCount;
  final VoidCallback onTap;

  const ModernServiceCard({
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
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w), // 🔴 تم التقليل لضم الكارت
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50.w, // 🔴 تم التقليل
                          height: 50.w,
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
                          height: 70.w, // 🔴 تم التقليل ليتناسب مع الحجم الجديد
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(fallbackIcon, color: AppColors.accentGold, size: 35.sp);
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15.sp, // 🔴 ضبط الخط
                        fontWeight: FontWeight.bold,
                        color: Colors.white, 
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.sp,
                        color: AppColors.accentGold, 
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
            top: -8, right: -8, 
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