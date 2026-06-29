import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 🟢 استدعاء الـ Widget الذكي للريكورد بتاعك
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
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // 🟢 الفورم دي بتعمل سكرول لوحدها ومستقلة تماماً
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          // 🟢 ويدجت الصوت والنص بتاعك
          OrderInputWidget(
            controller: errandDetailsController,
            onAudioRecorded: onAudioRecorded,
          ),
          SizedBox(height: 12.h),
          
          TextField(
            controller: errandEstimatedCostController,
            keyboardType: TextInputType.number,
            scrollPadding: EdgeInsets.only(bottom: keyboardHeight + 120.h),
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold, color: primaryGreen),
            decoration: InputDecoration(
              labelText: 'سعر الطلبات التقريبي',
              suffixText: 'جنيه',
              prefixIcon: Icon(Icons.account_balance_wallet, color: primaryGreen),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none)
            )
          ),
          SizedBox(height: 16.h),
          
          TextField(
            controller: pickupController,
            keyboardType: TextInputType.text,
            scrollPadding: EdgeInsets.only(bottom: keyboardHeight + 120.h),
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'مكان الشراء',
              suffixIcon: IconButton(
                icon: Icon(Icons.my_location, color: accentGold),
                onPressed: () {
                  FocusScope.of(context).unfocus(); // تنزيل الكيبورد بنعومة
                  onOpenMapSelection('pickup');
                },
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none)
            )
          ),
          SizedBox(height: 12.h),
          
          TextField(
            controller: destinationController,
            keyboardType: TextInputType.text,
            scrollPadding: EdgeInsets.only(bottom: keyboardHeight + 120.h),
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'مكان تسليم الطلب',
              suffixIcon: IconButton(
                icon: Icon(Icons.location_on, color: primaryGreen),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  onOpenMapSelection('destination');
                },
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none)
            )
          ),
          SizedBox(height: 12.h),
          
          TextField(
            controller: priceController,
            focusNode: priceFocusNode,
            keyboardType: TextInputType.number,
            scrollPadding: EdgeInsets.only(bottom: keyboardHeight + 140.h),
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'أجرة التوصيل للكابتن',
              suffixText: 'جنيه',
              prefixIcon: Icon(Icons.payments, color: accentGold),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none)
            )
          ),
          SizedBox(height: 20.h),
          
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))
            ),
            onPressed: isSubmittingTrip ? null : onSubmit,
            child: isSubmittingTrip
                ? CircularProgressIndicator(color: accentGold)
                : Text('إرسال الطلب للكباتن', style: TextStyle(color: accentGold, fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))
          ),
          
          // المساحة السحرية للحفاظ على السكرول
          SizedBox(height: keyboardHeight > 0 ? keyboardHeight + 20.h : 40.h),
        ],
      ),
    );
  }
}