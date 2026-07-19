// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamma_new/core/theme/app_colors.dart';

// 🟢 استدعاء ملف الترجمة
import 'package:lamma_new/l10n/app_localizations.dart';

import 'package:lamma_new/features/trips/presentation/widgets/order_input_widget.dart';

class TripForm extends StatefulWidget {
  final String tripCategory;
  final String vehicleType;
  final bool isSubmittingTrip;
  final TextEditingController errandDetailsController;
  final TextEditingController errandEstimatedCostController;
  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final TextEditingController priceController;
  final FocusNode priceFocusNode;
  final Color primaryGreen;
  final Color accentGold;
  final Function(String) onCategoryChanged;
  final Function(String) onVehicleChanged;
  final Function(String) onOpenMapSelection;
  final VoidCallback onSubmit;
  final Function(File?)? onAudioRecorded;

  const TripForm({
    super.key,
    required this.tripCategory,
    required this.vehicleType,
    required this.isSubmittingTrip,
    required this.errandDetailsController,
    required this.errandEstimatedCostController,
    required this.pickupController,
    required this.destinationController,
    required this.priceController,
    required this.priceFocusNode,
    required this.primaryGreen,
    required this.accentGold,
    required this.onCategoryChanged,
    required this.onVehicleChanged,
    required this.onOpenMapSelection,
    required this.onSubmit,
    this.onAudioRecorded,
  });

  @override
  State<TripForm> createState() => _TripFormState();
}

class _TripFormState extends State<TripForm> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. التابات العلوية
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(
                    color: AppColors.primaryDark.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  _buildCategoryChip(
                      'داخلي', l10n.deliveryDisplay, Icons.local_taxi_rounded),
                  _buildCategoryChip('طلبات', l10n.buyOrdersDisplay,
                      Icons.shopping_bag_rounded),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // 2. اختيار نوع المركبة
            if (widget.tripCategory == 'داخلي') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildVehicleChip(
                      'سيارة', l10n.carVehicle, 'assets/images/car.png'),
                  SizedBox(width: 10.w),
                  _buildVehicleChip('موتوسيكل', l10n.motorcycleVehicle,
                      'assets/images/motorcycle.png'),
                  SizedBox(width: 10.w),
                  _buildVehicleChip(
                      'توكتوك', l10n.tuktukVehicle, 'assets/images/tuktuk.png'),
                ],
              ),
              SizedBox(height: 24.h),
            ],

            // 3. نقطة الانطلاق
            _buildInputField(
              controller: widget.pickupController,
              label: l10n.pickupLocationLabel,
              icon: Icons.my_location_rounded,
              iconColor: AppColors.accentGold,
              readOnly: true,
              onTap: () => widget.onOpenMapSelection('pickup'),
            ),
            SizedBox(height: 12.h),

            // 4. نقطة الوصول
            _buildInputField(
              controller: widget.destinationController,
              label: l10n.destinationLocationLabel,
              icon: Icons.location_on_rounded,
              iconColor: AppColors.primaryDark,
              readOnly: true,
              onTap: () => widget.onOpenMapSelection('destination'),
            ),
            SizedBox(height: 12.h),

            // 5. حقول خاصة بقسم "طلبات"
            if (widget.tripCategory == 'طلبات') ...[
              OrderInputWidget(
                controller: widget.errandDetailsController,
                onAudioRecorded: (file) {
                  if (widget.onAudioRecorded != null) {
                    widget.onAudioRecorded!(file);
                  }
                },
              ),
              SizedBox(height: 12.h),

              // حقل التكلفة التقريبية للطلبات
              _buildInputField(
                controller: widget.errandEstimatedCostController,
                label: l10n.estimatedOrderPriceLabel,
                icon: Icons.receipt_long_rounded,
                iconColor: AppColors.primaryDark,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12.h),
            ],

            // 6. سعر التوصيل
            _buildInputField(
              controller: widget.priceController,
              focusNode: widget.priceFocusNode,
              label: l10n.deliveryFareLabel,
              icon: Icons.payments_rounded,
              iconColor: AppColors.accentGold,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 24.h),

            // 7. زر الإرسال
            SizedBox(
              height: 55.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: AppColors.accentGold,
                  elevation: 6,
                  shadowColor: AppColors.primaryDarkLight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r)),
                ),
                onPressed: widget.isSubmittingTrip ? null : widget.onSubmit,
                child: widget.isSubmittingTrip
                    ? SizedBox(
                        width: 25.w,
                        height: 25.w,
                        child: const CircularProgressIndicator(
                            color: AppColors.accentGold, strokeWidth: 3))
                    : Text(
                        widget.tripCategory == 'طلبات'
                            ? l10n.sendPurchaseRequestBtn
                            : l10n.sendRequestBtn,
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentGold),
                      ),
              ),
            ),
            SizedBox(
                height:
                    MediaQuery.of(context).viewInsets.bottom > 0 ? 20.h : 0),
          ],
        ),
      ),
    );
  }

  // ودجت التابات العلوية
  Widget _buildCategoryChip(
      String logicTitle, String displayTitle, IconData icon) {
    bool isSelected = widget.tripCategory == logicTitle;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onCategoryChanged(logicTitle),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25.r),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18.sp,
                  color: isSelected ? AppColors.accentGold : Colors.grey),
              SizedBox(width: 8.w),
              Text(
                displayTitle,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primaryDark : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ودجت حقول الإدخال
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      focusNode: focusNode,
      keyboardType: keyboardType,
      style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            fontSize: 13.sp,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: iconColor),
        filled: true,
        fillColor: AppColors.backgroundLight,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide: BorderSide(
                color: AppColors.primaryDark.withValues(alpha: 0.05))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide: BorderSide(
                color: AppColors.primaryDark.withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide:
                const BorderSide(color: AppColors.accentGold, width: 2)),
      ),
    );
  }

  // ودجت السيارات الفرعي (تم فصل الكلمة البرمجية عن كلمة العرض)
  Widget _buildVehicleChip(
      String logicTitle, String displayTitle, String imagePath) {
    bool isSelected = widget.vehicleType == logicTitle;
    return Expanded(
      child: InkWell(
        onTap: () => widget.onVehicleChanged(logicTitle),
        borderRadius: BorderRadius.circular(15.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryDark : Colors.transparent,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(
                color:
                    isSelected ? AppColors.accentGold : Colors.grey.shade300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                imagePath,
                height: 45.h,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 6.h),
              Text(
                displayTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
