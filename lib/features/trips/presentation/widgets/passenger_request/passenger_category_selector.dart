import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamma_new/core/theme/app_colors.dart';
import 'trip_category.dart';

class PassengerCategorySelector extends StatelessWidget {
  final TripCategory selectedCategory;
  final ValueChanged<TripCategory> onCategoryChanged;

  const PassengerCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildCategoryChip(TripCategory.internal),
          _buildCategoryChip(TripCategory.shopping),
          _buildCategoryChip(TripCategory.travel),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(TripCategory category) {
    bool isSelected = selectedCategory == category;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            // إعطاء إحساس ملموس (vibration) عند الضغط
            HapticFeedback.lightImpact();
            onCategoryChanged(category);
          }
        },
        // تأثير التكبير البصري (Expanding animation) عند التحديد
        child: AnimatedScale(
          scale: isSelected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryDark : Colors.transparent,
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(
                color: isSelected ? AppColors.primaryDark : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category.icon,
                  size: 18.sp,
                  color:
                      isSelected ? AppColors.accentGold : Colors.grey.shade400,
                ),
                SizedBox(width: 8.w),
                Text(
                  category.displayTitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? AppColors.accentGold
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
