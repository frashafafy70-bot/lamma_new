import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/utils/passenger_utils.dart'; // لجلب context.l10n

class MapSelectionOverlay extends StatelessWidget {
  final TextEditingController mapSearchController;
  final List<dynamic> placePredictions;
  final bool isReverseGeocoding;
  final Color primaryGreen;
  final Color accentGold;
  final Function(String) onSearch;
  final Function(String, String) onSelectPlace;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const MapSelectionOverlay({
    super.key,
    required this.mapSearchController,
    required this.placePredictions,
    required this.isReverseGeocoding,
    required this.primaryGreen,
    required this.accentGold,
    required this.onSearch,
    required this.onSelectPlace,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.primaryNavy;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: Stack(
        children: [
          // 🟢 1. الماركر الثابت في منتصف الشاشة (تصميم أوبر وكريم)
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 50.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // كارت العنوان العائم
                  AnimatedOpacity(
                    opacity: isReverseGeocoding ? 0.4 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 250.w),
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                              color: isDark ? Colors.black54 : Colors.black12,
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.pickupLocation,
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  mapSearchController.text.isNotEmpty
                                      ? mapSearchController.text
                                      : l10n.locatingMap,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(Icons.arrow_forward_ios,
                              size: 14.sp, color: textColor),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // الأيقونة اللي جواها الراجل (Marker Icon)
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primaryNavy.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Icon(Icons.emoji_people_rounded,
                        color: Colors.white, size: 26.sp),
                  ),

                  SizedBox(height: 4.h),

                  // النقطة المركزية (Bullseye)
                  Container(
                    width: 14.w,
                    height: 14.w,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryNavy, width: 3.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🟢 2. الجزء العلوي: مربع البحث
          Positioned(
            top: 10.h,
            left: 16.w,
            right: 16.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black54 : Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: mapSearchController,
                    onChanged: onSearch,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 14.sp, color: textColor),
                    decoration: InputDecoration(
                      hintText: l10n.typeToStartSearching,
                      hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: primaryGreen),
                      suffixIcon: mapSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                mapSearchController.clear();
                                onSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h),
                    ),
                  ),
                ),

                // قائمة اقتراحات الأماكن
                if (placePredictions.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 5.h),
                    constraints: BoxConstraints(maxHeight: 200.h),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                            color: isDark ? Colors.black54 : Colors.black12,
                            blurRadius: 8)
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: placePredictions.length,
                      itemBuilder: (context, index) {
                        final prediction = placePredictions[index];
                        return ListTile(
                          title: Text(
                            prediction['description'] ?? '',
                            style: TextStyle(fontSize: 13.sp, color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: Icon(Icons.location_on_outlined,
                              color: primaryGreen, size: 20.sp),
                          onTap: () => onSelectPlace(
                            prediction['place_id'],
                            prediction['description'],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 🟢 3. الجزء السفلي: كارت تأكيد الموقع
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [
                  BoxShadow(
                      color: isDark ? Colors.black54 : Colors.black12,
                      blurRadius: 15,
                      offset: const Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: accentGold, size: 20.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            isReverseGeocoding
                                ? l10n.fetchingAddress
                                : l10n.searchPrompt,
                            style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              side: BorderSide(
                                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r)),
                            ),
                            onPressed: onCancel,
                            child: Text(
                              l10n.cancel,
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: textColor),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: accentGold,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r)),
                              elevation: 0,
                            ),
                            onPressed: isReverseGeocoding ? null : onConfirm,
                            child: Text(
                              l10n.confirmLocation,
                              style: TextStyle(
                                  fontSize: 15.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
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