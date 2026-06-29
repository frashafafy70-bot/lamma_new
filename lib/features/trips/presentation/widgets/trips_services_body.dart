import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// استدعاء الفورمز الفرعية من الفولدر اللي إنت عملته
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: categories.map((c) {
        bool isSelected = tripCategory == c['id'];
        return GestureDetector(
          onTap: () => onCategoryChanged(c['id']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected ? accentGold.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(c['icon'], color: isSelected ? accentGold : Colors.grey.shade500, size: 22.sp),
                SizedBox(width: 6.w),
                Text(
                  c['name'],
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14.sp,
                    color: isSelected ? primaryGreen : Colors.grey.shade600
                  )
                )
              ]
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h, left: 20.w, right: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTripCategorySelector(),
          SizedBox(height: 16.h),
          
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _buildSelectedForm(),
          ),
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
        // تمرير الألوان للفورم الأول
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
        // تمرير الألوان للفورم الثاني
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