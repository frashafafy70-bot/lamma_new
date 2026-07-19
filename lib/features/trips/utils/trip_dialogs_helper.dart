import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;

class TripDialogsHelper {
  // اللون الذهبي الملكي الموحد للتطبيق
  static const Color premiumGold = Color(0xFFDDA15E);

  // 🔴 دالة مسح الطلب (ترجع true إذا وافق المستخدم، و false إذا تراجع)
  static Future<bool> showDeleteTripDialog({
    required BuildContext context,
  }) async {
    final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r)),
              title: Row(
                children: [
                  Icon(Icons.delete_forever_rounded,
                      color: Colors.red.shade700, size: 28.sp),
                  SizedBox(width: 8.w),
                  Text('مسح الطلب',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                          fontSize: 18.sp)),
                ],
              ),
              content: Text('هل أنت متأكد من إزالة هذا الطلب؟',
                  style: TextStyle(fontSize: 14.sp)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('تراجع',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r))),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('نعم، امسح',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold))),
              ],
            ));
    return result ?? false;
  }

  // 🔴 دالة إلغاء الرحلة (ترجع true إذا وافق المستخدم، و false إذا تراجع)
  static Future<bool> showCancelTripDialog({
    required BuildContext context,
  }) async {
    final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r)),
              title: Row(
                children: [
                  Icon(Icons.cancel_rounded,
                      color: Colors.red.shade700, size: 28.sp),
                  SizedBox(width: 8.w),
                  Text('إلغاء الرحلة',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                          fontSize: 18.sp)),
                ],
              ),
              content: Text(
                  'هل أنت متأكد من إلغاء هذه الرحلة نهائياً؟ سيتم إشعار جميع الركاب الحاجزين.',
                  style: TextStyle(fontSize: 14.sp)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('تراجع',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r))),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('نعم، إلغاء',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold))),
              ],
            ));
    return result ?? false;
  }

  // 🟢 دالة تعديل الرحلة المنشورة (ترجع Map يحتوي على 'price' و 'date' أو null إذا تم الإلغاء)
  static Future<Map<String, dynamic>?> showEditPublishedTripDialog({
    required BuildContext context,
    required String currentPrice,
    DateTime? currentTravelDate,
    required Color royalGreen,
  }) async {
    TextEditingController priceCtrl = TextEditingController(text: currentPrice);
    DateTime selectedDate = currentTravelDate ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    return await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r)),
            elevation: 20,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 28.h),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          royalGreen.withValues(alpha: 0.08),
                          premiumGold.withValues(alpha: 0.08)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24.r),
                          topRight: Radius.circular(24.r)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: premiumGold.withValues(alpha: 0.3),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                    color: royalGreen.withValues(alpha: 0.15),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                    offset: const Offset(0, 4)),
                                BoxShadow(
                                    color: premiumGold.withValues(alpha: 0.15),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                    offset: const Offset(0, -2)),
                              ]),
                          child: Icon(Icons.edit_calendar_rounded,
                              color: royalGreen, size: 34.sp),
                        ),
                        SizedBox(height: 16.h),
                        Text('تعديل تفاصيل الرحلة',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20.sp,
                                color: royalGreen)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('السعر للمقعد (ج.م)',
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800)),
                        SizedBox(height: 10.h),
                        TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: royalGreen),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 14.h),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide:
                                    BorderSide(color: premiumGold, width: 2)),
                            prefixIcon: Icon(Icons.monetization_on_rounded,
                                color: premiumGold),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text('تاريخ الرحلة',
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800)),
                        SizedBox(height: 10.h),
                        InkWell(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 30)),
                              builder: (context, child) => Theme(
                                  data: ThemeData.light().copyWith(
                                      colorScheme: ColorScheme.light(
                                          primary: royalGreen,
                                          secondary: premiumGold)),
                                  child: child!),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  selectedTime.hour,
                                  selectedTime.minute));
                            }
                          },
                          borderRadius: BorderRadius.circular(14.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 14.h),
                            decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(14.r)),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month_rounded,
                                    color: royalGreen, size: 24.sp),
                                SizedBox(width: 12.w),
                                Text(
                                    DateFormat('yyyy/MM/dd', 'en')
                                        .format(selectedDate),
                                    style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87)),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text('وقت التحرك',
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800)),
                        SizedBox(height: 10.h),
                        InkWell(
                          onTap: () async {
                            TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                              builder: (context, child) => Theme(
                                  data: ThemeData.light().copyWith(
                                      colorScheme: ColorScheme.light(
                                          primary: royalGreen,
                                          secondary: premiumGold)),
                                  child: child!),
                            );
                            if (picked != null) {
                              setState(() {
                                selectedTime = picked;
                                selectedDate = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                    picked.hour,
                                    picked.minute);
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(14.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 14.h),
                            decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(14.r)),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_filled_rounded,
                                    color: royalGreen, size: 24.sp),
                                SizedBox(width: 12.w),
                                Text(selectedTime.format(context),
                                    style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87)),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 36.h),
                        Row(
                          children: [
                            Expanded(
                                child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14.h),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14.r)),
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, null),
                                    child: Text('إلغاء',
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold)))),
                            SizedBox(width: 16.w),
                            Expanded(
                              flex: 2,
                              child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14.r),
                                    boxShadow: [
                                      BoxShadow(
                                          color:
                                              royalGreen.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5))
                                    ],
                                    gradient: LinearGradient(
                                        colors: [
                                          royalGreen,
                                          royalGreen.withValues(alpha: 0.85)
                                        ],
                                        begin: Alignment.centerRight,
                                        end: Alignment.centerLeft),
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 14.h),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14.r))),
                                    onPressed: () {
                                      if (priceCtrl.text.isEmpty) return;
                                      double? parsedPrice = double.tryParse(
                                          priceCtrl.text.trim());
                                      if (parsedPrice == null) return;

                                      // إرجاع البيانات للشاشة التي طلبت التعديل
                                      Navigator.pop(dialogContext, {
                                        'price': parsedPrice,
                                        'date': selectedDate,
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_outline_rounded,
                                            color: premiumGold, size: 20.sp),
                                        SizedBox(width: 8.w),
                                        Text('حفظ التعديلات',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16.sp)),
                                      ],
                                    ),
                                  )),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🟢 دالة تعديل الحجز (ترجع Map يحتوي على 'seats' و 'date' أو null إذا تم الإلغاء)
  static Future<Map<String, dynamic>?> showEditBookingDialog({
    required BuildContext context,
    required int currentSeats,
    required Color royalGreen,
    DateTime? currentBookingDate,
  }) async {
    TextEditingController seatsCtrl =
        TextEditingController(text: currentSeats.toString());
    DateTime selectedDate = currentBookingDate ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    return await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r)),
            elevation: 20,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 28.h),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          royalGreen.withValues(alpha: 0.08),
                          premiumGold.withValues(alpha: 0.08)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24.r),
                          topRight: Radius.circular(24.r)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: premiumGold.withValues(alpha: 0.3),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                    color: royalGreen.withValues(alpha: 0.15),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                    offset: const Offset(0, 4)),
                                BoxShadow(
                                    color: premiumGold.withValues(alpha: 0.15),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                    offset: const Offset(0, -2)),
                              ]),
                          child: Icon(Icons.edit_note_rounded,
                              color: royalGreen, size: 34.sp),
                        ),
                        SizedBox(height: 16.h),
                        Text('تعديل الحجز',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20.sp,
                                color: royalGreen)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('عدد المقاعد المحجوزة',
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800)),
                        SizedBox(height: 10.h),
                        TextField(
                          controller: seatsCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: royalGreen),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 14.h),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide:
                                    BorderSide(color: premiumGold, width: 2)),
                            prefixIcon: Icon(
                                Icons.airline_seat_recline_normal_rounded,
                                color: premiumGold),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text('تاريخ الحجز',
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800)),
                        SizedBox(height: 10.h),
                        InkWell(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 60)),
                              builder: (context, child) => Theme(
                                  data: ThemeData.light().copyWith(
                                      colorScheme: ColorScheme.light(
                                          primary: royalGreen,
                                          secondary: premiumGold)),
                                  child: child!),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  selectedTime.hour,
                                  selectedTime.minute));
                            }
                          },
                          borderRadius: BorderRadius.circular(14.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 14.h),
                            decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(14.r)),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month_rounded,
                                    color: royalGreen, size: 24.sp),
                                SizedBox(width: 12.w),
                                Text(
                                    DateFormat('yyyy/MM/dd', 'en')
                                        .format(selectedDate),
                                    style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87)),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text('وقت الحجز',
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800)),
                        SizedBox(height: 10.h),
                        InkWell(
                          onTap: () async {
                            TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                              builder: (context, child) => Theme(
                                  data: ThemeData.light().copyWith(
                                      colorScheme: ColorScheme.light(
                                          primary: royalGreen,
                                          secondary: premiumGold)),
                                  child: child!),
                            );
                            if (picked != null) {
                              setState(() {
                                selectedTime = picked;
                                selectedDate = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                    picked.hour,
                                    picked.minute);
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(14.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 14.h),
                            decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(14.r)),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_filled_rounded,
                                    color: royalGreen, size: 24.sp),
                                SizedBox(width: 12.w),
                                Text(selectedTime.format(context),
                                    style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87)),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 36.h),
                        Row(
                          children: [
                            Expanded(
                                child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14.h),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14.r)),
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, null),
                                    child: Text('إلغاء',
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold)))),
                            SizedBox(width: 16.w),
                            Expanded(
                              flex: 2,
                              child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14.r),
                                    boxShadow: [
                                      BoxShadow(
                                          color:
                                              royalGreen.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5))
                                    ],
                                    gradient: LinearGradient(
                                        colors: [
                                          royalGreen,
                                          royalGreen.withValues(alpha: 0.85)
                                        ],
                                        begin: Alignment.centerRight,
                                        end: Alignment.centerLeft),
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 14.h),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14.r))),
                                    onPressed: () {
                                      if (seatsCtrl.text.isEmpty) return;
                                      int? newSeats =
                                          int.tryParse(seatsCtrl.text.trim());
                                      if (newSeats == null || newSeats <= 0)
                                        return;

                                      // إرجاع البيانات للشاشة
                                      Navigator.pop(dialogContext, {
                                        'seats': newSeats,
                                        'date': selectedDate,
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_outline_rounded,
                                            color: premiumGold, size: 20.sp),
                                        SizedBox(width: 8.w),
                                        Text('حفظ التعديل',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16.sp)),
                                      ],
                                    ),
                                  )),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🟡 دالة التفاوض (ترجع السعر المقترح كـ double أو null إذا تم الإلغاء)
  static Future<double?> showNegotiationDialog({
    required BuildContext context,
    required Color royalGreen,
  }) async {
    TextEditingController offerCtrl = TextEditingController();

    return await showDialog<double>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r)),
                title: Row(
                  children: [
                    Icon(Icons.handshake_rounded,
                        color: premiumGold, size: 28.sp),
                    SizedBox(width: 8.w),
                    Text('التفاوض على الأجرة',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                            color: royalGreen)),
                  ],
                ),
                content: TextField(
                    controller: offerCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                        labelText: 'اكتب سعرك المقترح',
                        labelStyle:
                            TextStyle(fontSize: 14.sp, color: royalGreen),
                        suffixText: 'جنيه',
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide:
                                BorderSide(color: premiumGold, width: 2)),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r)))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, null),
                      child: Text('إلغاء',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold))),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: royalGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r))),
                      onPressed: () {
                        if (offerCtrl.text.isEmpty) return;
                        double? parsedOffer =
                            double.tryParse(offerCtrl.text.trim());
                        if (parsedOffer == null) return;

                        // إرجاع السعر
                        Navigator.pop(ctx, parsedOffer);
                      },
                      child: Text('إرسال',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp)))
                ]));
  }

  // ⭐ دالة إنهاء الرحلة والتقييم (ترجع عدد النجوم كـ int أو null)
  static Future<int?> showRatingDialog({
    required BuildContext context,
    required Color royalGreen,
  }) async {
    int stars = 5;

    return await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) =>
            StatefulBuilder(builder: (dialogContext, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child: Icon(Icons.verified_rounded,
                          color: Colors.green, size: 60.sp),
                    ),
                    SizedBox(height: 20.h),
                    Text('حمد لله على السلامة!\nلقد وصلت لوجهتك.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: royalGreen)),
                    SizedBox(height: 20.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                              5,
                              (index) => IconButton(
                                  icon: Icon(
                                      index < stars
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: premiumGold,
                                      size: 40.sp),
                                  onPressed: () => setDialogState(
                                      () => stars = index + 1)))),
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: royalGreen,
                            minimumSize: Size(double.infinity, 50.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r)),
                            elevation: 5,
                            shadowColor: royalGreen.withValues(alpha: 0.4)),
                        onPressed: () {
                          // إرجاع التقييم
                          Navigator.pop(dialogContext, stars);
                        },
                        child: Text('تقييم الرحلة',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp)))
                  ],
                ),
              );
            }));
  }
}
