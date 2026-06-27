import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MapSelectionOverlay extends StatelessWidget {
  final TextEditingController mapSearchController;
  final List<dynamic> placePredictions;
  final bool isReverseGeocoding;
  final Color primaryGreen; 
  final Color accentGold;
  final Function(String) onSearch;
  final Function(String, String) onSelectPlace;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const MapSelectionOverlay({
    super.key,
    required this.mapSearchController,
    required this.placePredictions,
    required this.isReverseGeocoding,
    required this.primaryGreen,
    required this.accentGold,
    required this.onSearch,
    required this.onSelectPlace,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // 🟢 1. الماركر الثابت في منتصف الشاشة (تصميم أوبر وكريم)
          Center(
            // رفعنا الماركر لفوق شوية عشان النقطة السفلية تكون هي مركز الإحداثيات بالظبط
            child: Padding(
              padding: EdgeInsets.only(bottom: 50.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // كارت العنوان العائم (Where from)
                  AnimatedOpacity(
                    opacity: isReverseGeocoding ? 0.4 : 1.0, // بيكون شفاف شوية لو الخريطة بتتحرك أو بيعمل لودينج
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 250.w), // عشان لو العنوان طويل ميبوظش الشاشة
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Where from',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11.sp, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  mapSearchController.text.isNotEmpty 
                                      ? mapSearchController.text 
                                      : 'جاري تحديد الموقع...',
                                  style: TextStyle(color: Colors.black, fontSize: 13.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis, // لو العنوان طويل يظهر نقط
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(Icons.arrow_forward_ios, size: 14.sp, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  // الأيقونة السودة اللي جواها الراجل (Marker Icon)
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                      ],
                    ),
                    child: Icon(Icons.emoji_people_rounded, color: Colors.white, size: 26.sp),
                  ),
                  
                  SizedBox(height: 4.h),
                  
                  // النقطة المركزية اللي بتحدد المكان بالظبط (Bullseye)
                  Container(
                    width: 14.w,
                    height: 14.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 3.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🟢 2. الجزء العلوي: مربع البحث العائم الاحترافي واقتراحات الأماكن (كودك الأصلي)
          Positioned(
            top: 10.h, 
            left: 16.w,
            right: 16.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: mapSearchController,
                    onChanged: onSearch,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن مكان أو حدد على الخريطة...',
                      hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: primaryGreen),
                      suffixIcon: mapSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                mapSearchController.clear();
                                onSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    ),
                  ),
                ),
                
                // قائمة اقتراحات الأماكن بتصميم خفيف ومستقل
                if (placePredictions.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 5.h),
                    constraints: BoxConstraints(maxHeight: 200.h), 
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: placePredictions.length,
                      itemBuilder: (context, index) {
                        final prediction = placePredictions[index];
                        return ListTile(
                          title: Text(
                            prediction['description'] ?? '',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: Icon(Icons.location_on_outlined, color: primaryGreen, size: 20.sp),
                          onTap: () => onSelectPlace(
                            prediction['place_id'],
                            prediction['description'],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 🟢 3. الجزء السفلي: كارت تأكيد الموقع الفخم المستوحى من التطبيقات العالمية (كودك الأصلي)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: accentGold, size: 20.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            isReverseGeocoding ? 'جاري تحديث تفاصيل العنوان...' : 'اضغط على الخريطة لتحديد الموقع بدقة',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                            onPressed: onCancel,
                            child: Text(
                              'إلغاء',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: accentGold,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              elevation: 0,
                            ),
                            onPressed: isReverseGeocoding ? null : onConfirm,
                            child: Text(
                              'تأكيد الموقع المحدد',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}