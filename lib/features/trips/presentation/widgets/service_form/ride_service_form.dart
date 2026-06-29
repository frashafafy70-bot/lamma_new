import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'اختر نوع المركبة:', 
          style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp, fontWeight: FontWeight.w900, color: Colors.black87)
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(child: _buildVehicleCard('توكتوك', 'assets/images/tuktok_3d.png')),
            SizedBox(width: 12.w),
            Expanded(child: _buildVehicleCard('موتوسيكل', 'assets/images/bike_3d.png')),
            SizedBox(width: 12.w),
            Expanded(child: _buildVehicleCard('سيارة', 'assets/images/car_3d.png')),
          ],
        ),
        SizedBox(height: 24.h),
        
        _buildLocationInput(
          prefixText: 'من :',
          label: 'موقع التحرك', 
          controller: pickupController, 
          icon: Icons.my_location_rounded, 
          iconColor: accentGold, 
          onMapTap: () {
            FocusScope.of(context).unfocus(); 
            onOpenMapSelection('pickup');
          }
        ),
        SizedBox(height: 16.h),
        
        _buildLocationInput(
          prefixText: 'إلى :',
          label: 'وجهة الوصول', 
          controller: destinationController, 
          icon: Icons.location_on_rounded, 
          iconColor: primaryGreen, 
          onMapTap: () {
            FocusScope.of(context).unfocus();
            onOpenMapSelection('destination');
          }
        ),
        SizedBox(height: 16.h),
        
        _buildIconTextField(
          controller: priceController,
          focusNode: priceFocusNode,
          hint: 'سعرك المقترح',
          leftIcon: Icons.payments_outlined,
          iconColor: accentGold,
        ),
        SizedBox(height: 28.h),
        
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

  Widget _buildVehicleCard(String title, String imagePath) {
    bool isSelected = vehicleType == title;
    bool isPressed = false; 

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) {
            setState(() => isPressed = false);
            onVehicleChanged(title);
          },
          onTapCancel: () => setState(() => isPressed = false),
          
          child: AnimatedScale(
            scale: isPressed ? 0.92 : 1.0, 
            duration: const Duration(milliseconds: 100), 
            curve: Curves.easeInOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
              decoration: BoxDecoration(
                color: isSelected ? accentGold.withValues(alpha: 0.15) : primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isSelected ? accentGold : primaryGreen.withValues(alpha: 0.15), 
                  width: isSelected ? 2 : 1
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? accentGold.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                    blurRadius: isSelected ? 12 : 6,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.asset(
                      imagePath,
                      height: 55.h,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        IconData fallbackIcon = Icons.directions_car_rounded;
                        if (title == 'توكتوك') fallbackIcon = Icons.electric_rickshaw_rounded; 
                        if (title == 'موتوسيكل') fallbackIcon = Icons.motorcycle_rounded;

                        return Icon(fallbackIcon, size: 45.sp, color: primaryGreen.withValues(alpha: 0.3));
                      },
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    title, 
                    style: TextStyle(
                      fontFamily: 'Cairo', 
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold, 
                      fontSize: 13.sp, 
                      color: isSelected ? primaryGreen : Colors.grey.shade800 
                    )
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildLocationInput({
    required String prefixText, 
    required String label, 
    required TextEditingController controller, 
    required IconData icon, 
    required Color iconColor, 
    required VoidCallback onMapTap
  }) {
    return Container(
      padding: EdgeInsets.only(right: 16.w, left: 8.w, top: 4.h, bottom: 4.h),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.08), 
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3))
        ]
      ),
      child: Row(
        children: [
          Text(
            prefixText, 
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.w900, color: primaryGreen)
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
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
              child: Icon(icon, color: iconColor, size: 22.sp)
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIconTextField({required TextEditingController controller, required FocusNode focusNode, required String hint, required IconData leftIcon, required Color iconColor}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.08), 
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3))
        ]
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: primaryGreen),
              decoration: InputDecoration(
                hintText: hint, 
                hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade400, fontWeight: FontWeight.w600), 
                border: InputBorder.none, 
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(color: accentGold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10.r)),
            child: Icon(leftIcon, color: iconColor, size: 22.sp),
          ), 
        ],
      ),
    );
  }
}