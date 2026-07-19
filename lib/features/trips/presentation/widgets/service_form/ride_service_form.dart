// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/utils/passenger_utils.dart';
import 'package:lamma_new/features/trips/cubit/passenger/passenger_request_cubit.dart';
// تأكد من استيراد امتداد اللغة الخاص بك هنا، غالباً يكون:
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RideServiceForm extends StatelessWidget {
  final String vehicleType;
  final Function(String) onVehicleChanged;
  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final TextEditingController priceController;
  final FocusNode priceFocusNode;
  final Function(String) onOpenMapSelection;
  final VoidCallback onSubmit;
  final bool isSubmittingTrip;

  final Color primaryGreen;
  final Color accentGold;

  const RideServiceForm({
    super.key,
    required this.vehicleType,
    required this.onVehicleChanged,
    required this.pickupController,
    required this.destinationController,
    required this.priceController,
    required this.priceFocusNode,
    required this.onOpenMapSelection,
    required this.onSubmit,
    required this.isSubmittingTrip,
    required this.primaryGreen,
    required this.accentGold,
  });

  @override
  Widget build(BuildContext context) {
    // استخدمنا امتداد اللغة l10n
    final l10n = context.l10n;

    return BlocListener<PassengerRequestCubit, PassengerRequestState>(
      listener: (context, state) {
        if (state is TripSubmitSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.requestSentSuccess,
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
          Text(l10n.carType,
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy)),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                  child: _buildVehicleCard(
                      context, l10n.tuktukVehicle, 'assets/images/tuktuk.png')),
              SizedBox(width: 12.w),
              Expanded(
                  child: _buildVehicleCard(
                      context, l10n.motorcycleVehicle, 'assets/images/motorcycle.png')),
              SizedBox(width: 12.w),
              Expanded(
                  child: _buildVehicleCard(
                      context, l10n.carVehicle, 'assets/images/car.png')),
            ],
          ),
          SizedBox(height: 24.h),
          _buildSeparateLocationInput(
              context: context,
              prefixText: l10n.pickupLocation,
              label: l10n.pickupLocationLabel,
              controller: pickupController,
              icon: Icons.my_location_rounded,
              iconColor: accentGold,
              onMapTap: () {
                FocusScope.of(context).unfocus();
                onOpenMapSelection('pickup');
              }),
          _buildSeparateLocationInput(
              context: context,
              prefixText: l10n.toDestination,
              label: l10n.destinationLocation,
              controller: destinationController,
              icon: Icons.location_on_rounded,
              iconColor: AppColors.primaryNavy,
              onMapTap: () {
                FocusScope.of(context).unfocus();
                onOpenMapSelection('destination');
              }),
          _buildPriceInputDisplay(context),
          SizedBox(height: 16.h),
          _buildPremiumQuickPriceChips(context),
          SizedBox(height: 28.h),
          Container(
            width: double.infinity,
            height: 55.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryNavy, primaryGreen],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNavy.withValues(alpha: 0.25),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r)),
              ),
              onPressed: isSubmittingTrip
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      onSubmit();
                    },
              child: isSubmittingTrip
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(l10n.sendRequestBtn,
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInputDisplay(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
          color: accentGold.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
              color: accentGold.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: accentGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.payments_rounded,
                color: accentGold, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Text(context.l10n.priceLabel,
              style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600)),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              controller: priceController,
              focusNode: priceFocusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryNavy),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                suffixText: context.l10n.currencyEGP,
                suffixStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: accentGold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumQuickPriceChips(BuildContext context) {
    return Row(
      children: [
        _buildActionButton(context.l10n.delete, 0, isClear: true),
        SizedBox(width: 6.w),
        _buildActionButton('- 5', -5, isNegative: true),
        SizedBox(width: 6.w),
        _buildActionButton('+ 5', 5),
        SizedBox(width: 6.w),
        _buildActionButton('+ 10', 10),
        SizedBox(width: 6.w),
        _buildActionButton('+ 20', 20),
      ],
    );
  }

  Widget _buildActionButton(String label, int amount,
      {bool isClear = false, bool isNegative = false}) {
    Color bgColor = accentGold.withValues(alpha: 0.1);
    Color borderColor = accentGold.withValues(alpha: 0.3);
    Color textColor = AppColors.primaryNavy;

    if (isClear) {
      bgColor = Colors.red.withValues(alpha: 0.08);
      borderColor = Colors.red.withValues(alpha: 0.2);
      textColor = Colors.red.shade700;
    } else if (isNegative) {
      bgColor = Colors.grey.withValues(alpha: 0.1);
      borderColor = Colors.grey.withValues(alpha: 0.3);
      textColor = Colors.grey.shade700;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (isClear) {
            priceController.text = '';
          } else {
            int currentPrice = int.tryParse(priceController.text) ?? 0;
            int newPrice = currentPrice + amount;
            if (newPrice < 0) newPrice = 0;
            priceController.text = newPrice.toString();
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14.sp, color: textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildSeparateLocationInput({
    required BuildContext context,
    required String prefixText,
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onMapTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          border:
              Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Row(
        children: [
          Text(prefixText,
              style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600)),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: false,
              style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w600),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: onMapTap,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2))
                ],
              ),
              child: Icon(icon, color: iconColor, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(
      BuildContext context, String title, String imagePath) {
    return _Floating3DVehicleCard(
      title: title,
      imagePath: imagePath,
      isSelected: vehicleType == title,
      onTap: () {
        HapticFeedback.selectionClick();
        onVehicleChanged(title);
      },
    );
  }
}

class _Floating3DVehicleCard extends StatefulWidget {
  final String title;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const _Floating3DVehicleCard({
    required this.title,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_Floating3DVehicleCard> createState() => _Floating3DVehicleCardState();
}

class _Floating3DVehicleCardState extends State<_Floating3DVehicleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  bool isPressed = false;

  @override
  void initState() {
    super.initState();
    _floatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IconData fallbackIcon = Icons.directions_car_rounded;
    // تم ربط التحقق من اسم المركبة بملف الترجمة أيضاً
    if (widget.title == context.l10n.tuktukVehicle) {
      fallbackIcon = Icons.electric_rickshaw_rounded;
    }
    if (widget.title == context.l10n.motorcycleVehicle) {
      fallbackIcon = Icons.motorcycle_rounded;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedScale(
        scale: isPressed ? 0.92 : (widget.isSelected ? 1.05 : 1.0),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryNavy
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.accentGold
                  : AppColors.primaryNavy.withValues(alpha: 0.1),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                        color: AppColors.primaryNavy.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: widget.isSelected ? 1.0 : 0.5,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                            0,
                            widget.isSelected
                                ? _floatAnimation.value
                                : (_floatAnimation.value / 2)),
                        child: child,
                      );
                    },
                    child: Image.asset(
                      widget.imagePath,
                      height: 50.h,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                          fallbackIcon,
                          size: 45.sp,
                          color: AppColors.primaryNavy.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: widget.isSelected
                        ? Colors.white
                        : AppColors.primaryNavy,
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