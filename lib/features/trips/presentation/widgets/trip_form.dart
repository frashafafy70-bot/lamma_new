import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/cubit/passenger/passenger_request_cubit.dart';

import 'service_form/ride_service_form.dart';
import 'service_form/buy_orders_service_form.dart';
import 'service_form/travel_service_form.dart';

class TripForm extends StatefulWidget {
  final Function(String) onOpenMapSelection;
  final LatLng? pickupLocation;
  final LatLng? destinationLocation;

  const TripForm({
    super.key,
    required this.onOpenMapSelection,
    this.pickupLocation,
    this.destinationLocation,
  });

  @override
  State<TripForm> createState() => TripFormState();
}

class TripFormState extends State<TripForm> {
  String tripCategory = 'داخلي';
  String vehicleType = 'سيارة';
  
  late TextEditingController pickupController;
  late TextEditingController destinationController;
  late TextEditingController priceController;
  late TextEditingController errandDetailsController;
  late TextEditingController errandEstimatedCostController;
  late FocusNode priceFocusNode;
  
  File? orderAudioFile;

  @override
  void initState() {
    super.initState();
    pickupController = TextEditingController(text: 'موقعي الحالي');
    destinationController = TextEditingController();
    priceController = TextEditingController();
    errandDetailsController = TextEditingController();
    errandEstimatedCostController = TextEditingController();
    priceFocusNode = FocusNode();
  }

  @override
  void dispose() {
    pickupController.dispose();
    destinationController.dispose();
    priceController.dispose();
    errandDetailsController.dispose();
    errandEstimatedCostController.dispose();
    priceFocusNode.dispose();
    super.dispose();
  }

  // 🟢 الدالة دي عشان شاشة الـ Tab تبعت للفورم العناوين بعد اختيارها من الخريطة
  void updateLocationText(String mode, String address) {
    setState(() {
      if (mode == 'pickup') {
        pickupController.text = address;
      } else if (mode == 'destination') {
        destinationController.text = address;
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold)), 
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  // 🟢 نقلنا الـ Validation بالكامل هنا عشان الفورم يعتمد على نفسه
  void _validateAndSubmit() {
    bool isErrand = tripCategory == 'طلبات';
    
    if (destinationController.text.trim().isEmpty || priceController.text.trim().isEmpty || pickupController.text.trim().isEmpty) {
      _showError('الرجاء إكمال جميع الحقول الأساسية!');
      return;
    }

    double? suggestedPrice = double.tryParse(priceController.text.trim());
    if (suggestedPrice == null || suggestedPrice <= 0) {
      _showError('الرجاء إدخال سعر صحيح (أرقام فقط)!');
      return;
    }

    if (isErrand) {
      if (errandDetailsController.text.trim().isEmpty && orderAudioFile == null) {
        _showError('الرجاء كتابة تفاصيل الطلبات أو تسجيلها صوتياً!');
        return;
      }
      double? errandCost = double.tryParse(errandEstimatedCostController.text.trim());
      if (errandCost == null || errandCost <= 0) {
        _showError('الرجاء إدخال تكلفة تقريبية صحيحة (أرقام فقط)!');
        return;
      }
    }
    
    // الإرسال للـ Cubit
    context.read<PassengerRequestCubit>().submitTripRequest(
      tripCategory: tripCategory,
      vehicleType: vehicleType,
      pickup: pickupController.text.trim(),
      destination: destinationController.text.trim(),
      price: priceController.text.trim(),
      errandDetails: errandDetailsController.text.trim(),
      errandCost: errandEstimatedCostController.text.trim(),
      pickupLocation: widget.pickupLocation,
      destinationLocation: widget.destinationLocation,
      orderAudioFile: orderAudioFile,
    );
  }

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
            onTap: () {
              setState(() => tripCategory = c['id']);
              FocusScope.of(context).unfocus();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic, 
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 18.w : 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(25.r),
                boxShadow: isSelected ? [
                  BoxShadow(color: AppColors.accentGold.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3))
                ] : [],
                border: isSelected ? Border.all(color: AppColors.accentGold.withValues(alpha: 0.3), width: 1) : Border.all(color: Colors.transparent, width: 1),
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
                      child: Icon(c['icon'], color: isSelected ? AppColors.accentGold : Colors.grey.shade400, size: 22.sp),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, fontSize: isSelected ? 14.sp : 13.sp, color: isSelected ? AppColors.royalGreen : Colors.grey.shade500),
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

  Widget _buildSelectedForm(bool isSubmittingTrip) {
    if (tripCategory == 'داخلي') {
      return RideServiceForm(
        vehicleType: vehicleType,
        isSubmittingTrip: isSubmittingTrip,
        pickupController: pickupController,
        destinationController: destinationController,
        priceController: priceController,
        priceFocusNode: priceFocusNode,
        onVehicleChanged: (v) => setState(() => vehicleType = v),
        onOpenMapSelection: widget.onOpenMapSelection,
        onSubmit: _validateAndSubmit,
        primaryGreen: AppColors.royalGreen,
        accentGold: AppColors.accentGold,
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
        onOpenMapSelection: widget.onOpenMapSelection,
        onAudioRecorded: (file) => setState(() => orderAudioFile = file),
        onSubmit: _validateAndSubmit,
        primaryGreen: AppColors.royalGreen,
        accentGold: AppColors.accentGold,
      );
    } else if (tripCategory == 'خارجي') { 
      return TravelServiceForm(
        vehicleType: vehicleType,
        isSubmittingTrip: isSubmittingTrip,
        pickupController: pickupController,
        destinationController: destinationController,
        priceController: priceController,
        priceFocusNode: priceFocusNode,
        onVehicleChanged: (v) => setState(() => vehicleType = v),
        onOpenMapSelection: widget.onOpenMapSelection,
        onSubmit: _validateAndSubmit,
        primaryGreen: AppColors.royalGreen,
        accentGold: AppColors.accentGold,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 الفورم بيراقب حالة الكيوبت بنفسه عشان يعرف إمتى يظهر الـ Loading
    return BlocBuilder<PassengerRequestCubit, PassengerRequestState>(
      builder: (context, state) {
        bool isSubmitting = state is TripSubmitting;
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(top: 20.h, left: 20.w, right: 20.w, bottom: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTripCategorySelector(),
              SizedBox(height: 16.h),
              _buildSelectedForm(isSubmitting), 
            ],
          ),
        );
      },
    );
  }
}