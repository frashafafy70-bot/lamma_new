import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// استدعاء الـ Widget الذكي للريكورد بتاعك
import 'package:lamma_new/features/trips/presentation/widgets/order_input_widget.dart'; 

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
    // 🟢 السر في الـ Column ده مع mainAxisSize: MainAxisSize.min عشان يمنع الشاشة الحمرا
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, 
      children: [
        
        OrderInputWidget(
          controller: errandDetailsController,
          onAudioRecorded: onAudioRecorded,
        ),
        SizedBox(height: 16.h),
        
        _buildPremiumTextField(
          controller: errandEstimatedCostController,
          label: 'سعر الطلبات التقريبي',
          suffixText: 'جنيه',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: primaryGreen,
          isNumber: true,
        ),
        SizedBox(height: 16.h),
        
        _buildPremiumLocationField(
          label: 'مكان الشراء',
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
          label: 'مكان تسليم الطلب',
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
          controller: priceController,
          focusNode: priceFocusNode,
          label: 'أجرة التوصيل للسائق',
          suffixText: 'جنيه',
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            ),
            onPressed: isSubmittingTrip ? null : onSubmit,
            child: isSubmittingTrip
                ? CircularProgressIndicator(color: accentGold)
                : Text(
                    'إرسال الطلب للكباتن', 
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumTextField({required TextEditingController controller, FocusNode? focusNode, required String label, required String suffixText, required IconData icon, required Color iconColor, bool isNumber = false}) {
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
              keyboardType: isNumber ? TextInputType.number : TextInputType.text,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                suffixText: suffixText,
                suffixStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: primaryGreen, fontWeight: FontWeight.bold),
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

  Widget _buildPremiumLocationField({required String label, required TextEditingController controller, required IconData icon, required Color iconColor, required VoidCallback onMapTap}) {
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
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
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
              decoration: const BoxDecoration(
                color: Colors.white, 
                shape: BoxShape.circle, 
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
              ),
              child: Icon(icon, color: iconColor, size: 22.sp),
            ),
          )
        ],
      ),
    );
  }
}