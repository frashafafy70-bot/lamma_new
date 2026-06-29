import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'service_form/ride_service_form.dart';
import 'service_form/buy_orders_service_form.dart';

class TripForm extends StatelessWidget {
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
  final Function(File?) onAudioRecorded;

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
    required this.onAudioRecorded,
  });

  Widget _buildTripCategorySelector() {
    List<Map<String, dynamic>> categories = [
      {'id': 'داخلي', 'name': 'توصيل', 'icon': Icons.local_taxi_rounded},
      {'id': 'طلبات', 'name': 'شراء طلبات', 'icon': Icons.shopping_bag_rounded},
      {'id': 'خارجي', 'name': 'سفر', 'icon': Icons.emoji_transportation_rounded}
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 6.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: categories.map((c) {
          bool isSelected = tripCategory == c['id'];
          return GestureDetector(
            onTap: () => onCategoryChanged(c['id']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack, 
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 18.w : 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(25.r),
                boxShadow: isSelected ? [
                  BoxShadow(color: accentGold.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3))
                ] : [],
                border: isSelected ? Border.all(color: accentGold.withValues(alpha: 0.3), width: 1) : Border.all(color: Colors.transparent, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.2 : 1.0, 
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: AnimatedRotation(
                      turns: isSelected ? 0 : -0.02, 
                      duration: const Duration(milliseconds: 300),
                      child: Icon(c['icon'], color: isSelected ? accentGold : Colors.grey.shade400, size: 22.sp),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, fontSize: isSelected ? 14.sp : 13.sp, color: isSelected ? primaryGreen : Colors.grey.shade500),
                    child: Text(c['name']),
                  )
                ]
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 السكرول شغال براحته ومفيش أي كود يقفله
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(top: 20.h, left: 20.w, right: 20.w, bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTripCategorySelector(),
          SizedBox(height: 16.h),
          _buildSelectedForm(),
        ],
      ),
    );
  }

  Widget _buildSelectedForm() {
    if (tripCategory == 'داخلي') {
      return RideServiceForm(
        vehicleType: vehicleType,
        isSubmittingTrip: isSubmittingTrip,
        pickupController: pickupController,
        destinationController: destinationController,
        priceController: priceController,
        priceFocusNode: priceFocusNode,
        onVehicleChanged: onVehicleChanged,
        onOpenMapSelection: onOpenMapSelection,
        onSubmit: onSubmit,
        primaryGreen: primaryGreen,
        accentGold: accentGold,
      );
    } else if (tripCategory == 'طلبات') {
      return BuyOrdersServiceForm(
        isSubmittingTrip: isSubmittingTrip,
        errandDetailsController: errandDetailsController,
        errandEstimatedCostController: errandEstimatedCostController,
        pickupController: pickupController,
        destinationController: destinationController,
        priceController: priceController,
        priceFocusNode: priceFocusNode,
        onOpenMapSelection: onOpenMapSelection,
        onAudioRecorded: onAudioRecorded,
        onSubmit: onSubmit,
        primaryGreen: primaryGreen,
        accentGold: accentGold,
      );
    } else {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Text('خدمات السفر قريباً...', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
        ),
      );
    }
  }
}