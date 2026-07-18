import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamma_new/core/theme/app_colors.dart'; // 🎨 استدعاء الثيم الموحد
import 'package:lamma_new/features/trips/presentation/widgets/passenger_request/trip_category.dart';
import 'package:lamma_new/features/trips/presentation/widgets/passenger_request/passenger_category_selector.dart';

class PassengerActionPanel extends StatelessWidget {
  final double actualContainerHeight;
  final double keyboardHeight;
  final bool isMapFullscreen;
  final TripCategory selectedCategory;
  final ValueChanged<TripCategory> onCategoryChanged;
  final Widget serviceFormWidget;

  const PassengerActionPanel({
    super.key,
    required this.actualContainerHeight,
    required this.keyboardHeight,
    required this.isMapFullscreen,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.serviceFormWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      bottom: isMapFullscreen ? -actualContainerHeight : keyboardHeight,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        height: actualContainerHeight,
        decoration: BoxDecoration(
          color: AppColors.cardWhite, // تم استبدال Colors.white
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          boxShadow: [
            BoxShadow(
              // استخدمنا الكحلي بشفافية للظل عشان يتماشى مع هوية التطبيق بدل الأسود
              color: AppColors.primaryNavy.withOpacity(0.08), 
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: 20.h,
                  left: 20.w,
                  right: 20.w,
                  bottom: 10.h,
                ),
                child: PassengerCategorySelector(
                  selectedCategory: selectedCategory,
                  onCategoryChanged: onCategoryChanged,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 20.w,
                      right: 20.w,
                      bottom: MediaQuery.of(context).viewInsets.bottom > 0
                          ? 20.h
                          : 20.h,
                    ),
                    child: serviceFormWidget,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}