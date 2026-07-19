// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/utils/passenger_utils.dart';
import 'package:lamma_new/features/trips/presentation/widgets/order_input_widget.dart';
import 'package:lamma_new/features/trips/cubit/passenger/passenger_request_cubit.dart';
// تأكد من استيراد امتداد اللغة الخاص بك هنا، على سبيل المثال:
// import 'package:lamma_new/l10n/l10n.dart'; 

class BuyOrdersServiceForm extends StatelessWidget {
  final bool isSubmittingTrip;
  final TextEditingController errandDetailsController;
  final TextEditingController errandEstimatedCostController;
  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final TextEditingController priceController;
  final FocusNode priceFocusNode;
  final Color primaryGreen;
  final Color accentGold;
  final Function(String) onOpenMapSelection;
  final Function(File?) onAudioRecorded;
  final VoidCallback onSubmit;

  const BuyOrdersServiceForm({
    super.key,
    required this.isSubmittingTrip,
    required this.errandDetailsController,
    required this.errandEstimatedCostController,
    required this.pickupController,
    required this.destinationController,
    required this.priceController,
    required this.priceFocusNode,
    required this.primaryGreen,
    required this.accentGold,
    required this.onOpenMapSelection,
    required this.onAudioRecorded,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    // 🟢 استدعاء متغيرات اللغة
    final l10n = context.l10n;

    return BlocListener<PassengerRequestCubit, PassengerRequestState>(
      listener: (context, state) {
        if (state is TripSubmitSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.requestSentSuccess, // 🟢 من ملف الترجمة
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
          );
        } else if (state is TripSubmitError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          OrderInputWidget(
            controller: errandDetailsController,
            onAudioRecorded: onAudioRecorded,
          ),
          SizedBox(height: 16.h),
          _buildPremiumTextField(
            context: context,
            controller: errandEstimatedCostController,
            label: l10n.estimatedOrderPriceLabel, // 🟢 من ملف الترجمة
            suffixText: l10n.currencyEGP, // 🟢 من ملف الترجمة
            icon: Icons.account_balance_wallet_rounded,
            iconColor: primaryGreen,
            isNumber: true,
          ),
          SizedBox(height: 16.h),
          _buildPremiumLocationField(
            context: context,
            label: l10n.pickupLocationLabel, // 🟢 من ملف الترجمة
            controller: pickupController,
            icon: Icons.my_location_rounded,
            iconColor: accentGold,
            onMapTap: () {
              FocusScope.of(context).unfocus();
              onOpenMapSelection('pickup');
            },
          ),
          SizedBox(height: 16.h),
          _buildPremiumLocationField(
            context: context,
            label: l10n.destinationLocationLabel, // 🟢 من ملف الترجمة
            controller: destinationController,
            icon: Icons.location_on_rounded,
            iconColor: primaryGreen,
            onMapTap: () {
              FocusScope.of(context).unfocus();
              onOpenMapSelection('destination');
            },
          ),
          SizedBox(height: 16.h),
          _buildPremiumTextField(
            context: context,
            controller: priceController,
            focusNode: priceFocusNode,
            label: l10n.deliveryFareLabel, // 🟢 من ملف الترجمة
            suffixText: l10n.currencyEGP, // 🟢 من ملف الترجمة
            icon: Icons.payments_outlined,
            iconColor: accentGold,
            isNumber: true,
          ),
          SizedBox(height: 24.h),
          Container(
            width: double.infinity,
            height: 54.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r)),
              ),
              onPressed: isSubmittingTrip ? null : onSubmit,
              child: isSubmittingTrip
                  ? CircularProgressIndicator(color: accentGold)
                  : Text(l10n.sendRequestBtn, // 🟢 من ملف الترجمة
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField(
      {required BuildContext context,
      required TextEditingController controller,
      FocusNode? focusNode,
      required String label,
      required String suffixText,
      required IconData icon,
      required Color iconColor,
      bool isNumber = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24.sp),
          SizedBox(width: 14.w),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType:
                  isNumber ? TextInputType.number : TextInputType.text,
              style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.primaryNavy),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600),
                suffixText: suffixText,
                suffixStyle: TextStyle(
                    fontSize: 12.sp,
                    color: primaryGreen,
                    fontWeight: FontWeight.bold),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumLocationField(
      {required BuildContext context,
      required String label,
      required TextEditingController controller,
      required IconData icon,
      required Color iconColor,
      required VoidCallback onMapTap}) {
    return Container(
      padding: EdgeInsets.only(right: 16.w, left: 8.w, top: 4.h, bottom: 4.h),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.primaryNavy),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          GestureDetector(
            onTap: onMapTap,
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ]),
              child: Icon(icon, color: iconColor, size: 22.sp),
            ),
          )
        ],
      ),
    );
  }
}