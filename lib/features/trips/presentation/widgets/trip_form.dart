import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  Widget _buildVehicleTypeSelector() {
    List<Map<String, dynamic>> vehicles = [
      {'name': 'سيارة', 'icon': Icons.directions_car_rounded},
      {'name': 'موتوسيكل', 'icon': Icons.two_wheeler_rounded},
      {'name': 'توكتوك', 'icon': Icons.electric_rickshaw_rounded}
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اختر نوع المركبة:', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: vehicles.map((v) {
            bool isSelected = vehicleType == v['name'];
            return Expanded(
              child: GestureDetector(
                onTap: () => onVehicleChanged(v['name']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected ? accentGold.withValues(alpha: 0.1) : Colors.white,
                    border: Border.all(color: isSelected ? accentGold : Colors.grey.shade300, width: isSelected ? 2 : 1),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: isSelected ? [BoxShadow(color: accentGold.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : []
                  ),
                  child: Column(
                    children: [
                      Icon(v['icon'], color: isSelected ? accentGold : Colors.grey.shade400, size: 32.sp),
                      SizedBox(height: 4.h),
                      Text(v['name'], style: TextStyle(fontFamily: 'Cairo', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? primaryGreen : Colors.black87, fontSize: 13.sp))
                    ]
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isErrand = tripCategory == 'طلبات';
    
    // حساب مساحة الكيبورد الحالية ديناميكياً لزق العناصر
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(top: 20.h, left: 20.w, right: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTripCategorySelector(),
          SizedBox(height: 16.h),
          
          if (isErrand)
            Column(
              children: [
                TextField(
                  controller: errandDetailsController,
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  // إجبار الحقل على الارتفاع فوق الكيبورد عند التركيز
                  scrollPadding: EdgeInsets.only(bottom: keyboardHeight + 120.h),
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp),
                  decoration: InputDecoration(
                    labelText: 'اكتب طلباتك بالتفصيل',
                    prefixIcon: Icon(Icons.shopping_basket, color: accentGold),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none)
                  )
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: errandEstimatedCostController,
                  keyboardType: TextInputType.number,
                  // إجبار الحقل على الارتفاع فوق الكيبورد عند التركيز
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
                SizedBox(height: 16.h)
              ]
            ),
          
          if (!isErrand)
            Column(
              children: [
                _buildVehicleTypeSelector(),
                SizedBox(height: 16.h)
              ]
            ),
          
          TextField(
            controller: pickupController,
            keyboardType: TextInputType.text,
            // إجبار الحقل على الارتفاع فوق الكيبورد عند التركيز
            scrollPadding: EdgeInsets.only(bottom: keyboardHeight + 120.h),
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: isErrand ? 'مكان الشراء' : 'موقع التحرك',
              suffixIcon: IconButton(
                icon: Icon(Icons.my_location, color: accentGold),
                onPressed: () => onOpenMapSelection('pickup'),
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
            // إجبار الحقل على الارتفاع فوق الكيبورد عند التركيز
            scrollPadding: EdgeInsets.only(bottom: keyboardHeight + 120.h),
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: isErrand ? 'مكان تسليم الطلب' : 'وجهة الوصول',
              suffixIcon: IconButton(
                icon: Icon(Icons.location_on, color: primaryGreen),
                onPressed: () => onOpenMapSelection('destination'),
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
            // إجبار الحقل على الارتفاع فوق الكيبورد عند التركيز ليظهر تماماً هو وما تحته
            scrollPadding: EdgeInsets.only(bottom: keyboardHeight + 140.h),
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: isErrand ? 'أجرة التوصيل للكابتن' : 'سعرك المقترح',
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
                : Text(
                    isErrand ? 'إرسال الطلب للكباتن' : 'طلب الكابتن وتأكيد السعر',
                    style: TextStyle(color: accentGold, fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')
                  )
          ),
          
          // المساحة السحرية: تتمدد بمساحة الكيبورد لتسمح بالقوائم بالارتفاع التام للأعلى رؤية واضحة
          SizedBox(height: keyboardHeight > 0 ? keyboardHeight + 20.h : 40.h),
        ],
      ),
    );
  }
}