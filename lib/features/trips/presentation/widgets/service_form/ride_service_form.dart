// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamma_new/core/theme/app_colors.dart'; 

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
          style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.primaryDark)
        ),
        SizedBox(height: 16.h),
        
        // كروت المركبات
        Row(
          children: [
            Expanded(child: _buildVehicleCard('توكتوك', 'assets/images/tuktuk.png')),
            SizedBox(width: 12.w),
            Expanded(child: _buildVehicleCard('موتوسيكل', 'assets/images/motorcycle.png')),
            SizedBox(width: 12.w),
            Expanded(child: _buildVehicleCard('سيارة', 'assets/images/car.png')),
          ],
        ),
        SizedBox(height: 24.h),
        
        // حقول إدخال المواقع
        _buildSeparateLocationInput(
          prefixText: 'من :',
          label: 'موقعي الحالي', 
          controller: pickupController, 
          icon: Icons.my_location_rounded, 
          iconColor: AppColors.accentGold, 
          onMapTap: () {
            FocusScope.of(context).unfocus(); 
            onOpenMapSelection('pickup');
          }
        ),
        
        _buildSeparateLocationInput(
          prefixText: 'إلى :',
          label: 'وجهة الوصول', 
          controller: destinationController, 
          icon: Icons.location_on_rounded, 
          iconColor: AppColors.primaryDark, 
          onMapTap: () {
            FocusScope.of(context).unfocus();
            onOpenMapSelection('destination');
          }
        ),
        
        // حقل السعر بتصميم "شاشة العرض" الفخمة
        _buildPriceInputDisplay(),

        SizedBox(height: 16.h),

        // أزرار التسعير السريع المخصصة (Custom Buttons)
        _buildPremiumQuickPriceChips(),
        
        SizedBox(height: 28.h),
        
        // زر الإرسال الفخم
        Container(
          width: double.infinity,
          height: 55.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.royalGreen],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.25),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            ),
            onPressed: isSubmittingTrip ? null : () {
              HapticFeedback.mediumImpact(); 
              onSubmit();
            },
            child: isSubmittingTrip 
                ? const CircularProgressIndicator(color: Colors.white) 
                : Text(
                    'إرسال الطلب للكباتن', 
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)
                  ),
          ),
        ),
      ],
    );
  }

  // ودجت حقل السعر المستقل (لإعطائه فخامة خاصة)
  Widget _buildPriceInputDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.05), // لون دهبي خفيف جداً
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        children: [
          // أيقونة السعر
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.payments_rounded, color: AppColors.accentGold, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Text(
            'السعر :', 
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade600)
          ),
          SizedBox(width: 12.w),
          // حقل إدخال السعر
          Expanded(
            child: TextField(
              controller: priceController,
              focusNode: priceFocusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center, // الرقم في النص للفخامة
              style: TextStyle(
                fontFamily: 'Cairo', 
                fontSize: 24.sp, // خط ضخم للرقم
                fontWeight: FontWeight.w900, 
                color: AppColors.primaryDark
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                suffixText: 'ج.م', // إضافة العملة
                suffixStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.accentGold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ودجت أزرار التسعير السريع الفخمة
  Widget _buildPremiumQuickPriceChips() {
    return Row(
      children: [
        _buildActionButton('مسح', 0, isClear: true),
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

  // زر التحكم في السعر (Custom Button)
  Widget _buildActionButton(String label, int amount, {bool isClear = false, bool isNegative = false}) {
    // تحديد ألوان الزر بناءً على نوعه
    Color bgColor = AppColors.accentGold.withValues(alpha: 0.1);
    Color borderColor = AppColors.accentGold.withValues(alpha: 0.3);
    Color textColor = AppColors.primaryDark;

    if (isClear) {
      bgColor = Colors.red.withValues(alpha: 0.08);
      borderColor = Colors.red.withValues(alpha: 0.2);
      textColor = Colors.red.shade700;
    } else if (isNegative) {
      bgColor = Colors.grey.withValues(alpha: 0.1);
      borderColor = Colors.grey.withValues(alpha: 0.3);
      textColor = Colors.grey.shade700;
    }

    return Expanded( // عشان كل الأزرار تاخد نفس العرض بالضبط
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact(); 
          if (isClear) {
            priceController.text = ''; // تصفير كامل
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
              fontFamily: 'Cairo', 
              fontWeight: FontWeight.bold, 
              fontSize: 14.sp,
              color: textColor
            ),
          ),
        ),
      ),
    );
  }

  // 🟢 ودجت إدخال المواقع (من وإلى) - مُعدل
  Widget _buildSeparateLocationInput({
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
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        children: [
          Text(
            prefixText, 
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade600)
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: false, // 🟢 السماح بالكتابة اليدوية
              style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // 🟢 الأيقونة (الدبوس/الزوم) على اليسار وتفتح الخريطة
          GestureDetector(
            onTap: onMapTap,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Icon(icon, color: iconColor, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(String title, String imagePath) {
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

  @override
  Widget build(BuildContext context) {
    IconData fallbackIcon = Icons.directions_car_rounded;
    if (widget.title == 'توكتوك') fallbackIcon = Icons.electric_rickshaw_rounded;
    if (widget.title == 'موتوسيكل') fallbackIcon = Icons.motorcycle_rounded;

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
            color: widget.isSelected ? AppColors.primaryDark : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.isSelected ? AppColors.accentGold : AppColors.primaryDark.withValues(alpha: 0.1),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected ? [BoxShadow(color: AppColors.primaryDarkLight, blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: widget.isSelected ? 1.0 : 0.5, // تقليل شفافية الكروت غير المحددة للتركيز
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
                    child: Image.asset(
                      widget.imagePath,
                      height: 50.h,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, size: 45.sp, color: AppColors.primaryDark.withValues(alpha: 0.3)),
                    ), 
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: widget.isSelected ? Colors.white : AppColors.primaryDark,
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