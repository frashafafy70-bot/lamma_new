import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart'; 

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
            // 🟢 تم التعديل بأسماء الملفات اللي ظاهرة عندك في الـ VS Code بالمللي
            Expanded(child: _buildVehicleCard('توكتوك', 'assets/animations/tuktuk.json')),
            SizedBox(width: 12.w),
            Expanded(child: _buildVehicleCard('موتوسيكل', 'assets/animations/motorcycle.json')),
            SizedBox(width: 12.w),
            Expanded(child: _buildVehicleCard('سيارة', 'assets/animations/car.json')),
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
    return _Floating3DVehicleCard(
      title: title,
      imagePath: imagePath,
      isSelected: vehicleType == title,
      onTap: () => onVehicleChanged(title),
      primaryGreen: primaryGreen,
      accentGold: accentGold,
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

class _Floating3DVehicleCard extends StatefulWidget {
  final String title;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryGreen;
  final Color accentGold;

  const _Floating3DVehicleCard({
    required this.title,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
    required this.primaryGreen,
    required this.accentGold,
  });

  @override
  State<_Floating3DVehicleCard> createState() => _Floating3DVehicleCardState();
}

class _Floating3DVehicleCardState extends State<_Floating3DVehicleCard> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  bool isPressed = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Widget _buildMediaContent() {
    IconData fallbackIcon = Icons.directions_car_rounded;
    if (widget.title == 'توكتوك') fallbackIcon = Icons.electric_rickshaw_rounded;
    if (widget.title == 'موتوسيكل') fallbackIcon = Icons.motorcycle_rounded;

    if (widget.imagePath.endsWith('.json')) {
      return Lottie.asset(
        widget.imagePath,
        height: 55.h,
        width: double.infinity,
        fit: BoxFit.contain,
        animate: widget.isSelected, 
        repeat: true,
        errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, size: 45.sp, color: widget.primaryGreen.withValues(alpha: 0.3)),
      );
    } else {
      return Image.asset(
        widget.imagePath,
        height: 55.h,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, size: 45.sp, color: widget.primaryGreen.withValues(alpha: 0.3)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: widget.isSelected ? widget.accentGold.withValues(alpha: 0.15) : widget.primaryGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: widget.isSelected ? widget.accentGold : widget.primaryGreen.withValues(alpha: 0.15),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected ? widget.accentGold.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                blurRadius: widget.isSelected ? 12 : 6,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, widget.isSelected ? _floatAnimation.value : (_floatAnimation.value / 2)),
                      child: child,
                    );
                  },
                  child: _buildMediaContent(), 
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                widget.title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: widget.isSelected ? FontWeight.w900 : FontWeight.bold,
                  fontSize: 13.sp,
                  color: widget.isSelected ? widget.primaryGreen : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}