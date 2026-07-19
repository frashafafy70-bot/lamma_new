import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lamma_new/core/theme/app_colors.dart'; // 🎨 مسار الألوان الموحد
import 'package:lamma_new/l10n/app_localizations.dart'; // 🌐 مسار الترجمة

mixin PassengerUIMixin<T extends StatefulWidget> on State<T> {
  void showPassengerSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite, // توحيد لون النص
          ),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  void showLocationPermissionDialog(AppLocalizations l10n) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardWhite, // توحيد لون خلفية الـ Dialog
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.location_off_rounded,
                color: AppColors.error, size: 24.sp),
            SizedBox(width: 8.w),
            Text(
              l10n.locationPermissionTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                color: AppColors.textDark, // توحيد لون العنوان
              ),
            ),
          ],
        ),
        content: Text(
          l10n.locationPermissionMessage,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textDark, // توحيد لون النص
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: AppColors.accentGold, // تأثير الضغط
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            onPressed: () {
              Geolocator.openAppSettings();
              Navigator.pop(context);
            },
            child: Text(
              l10n.openSettings,
              style: TextStyle(
                color: AppColors.accentGold,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showTripLoadingDialog(AppLocalizations l10n) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.cardWhite, // توحيد لون الخلفية
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primaryNavy),
                  SizedBox(height: 20.h),
                  Text(
                    l10n.sendingRequest,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
