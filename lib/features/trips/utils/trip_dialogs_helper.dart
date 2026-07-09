// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;

class TripDialogsHelper {
  
  // دالة مسح الطلب
  static Future<void> showDeleteTripDialog({
    required BuildContext context,
    required String docId,
    required bool isDriver, 
  }) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('مسح الطلب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18.sp)),
        content: Text('هل أنت متأكد من إزالة هذا الطلب؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('تراجع', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14.sp))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), 
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text('نعم، امسح', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 14.sp))
          ),
        ],
      )
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('trips').doc(docId).update({
        isDriver ? 'isDeletedForDriver' : 'isDeletedForPassenger': true
      });
    }
  }

  // 🟢 دالة إلغاء الرحلة (محدثة لدعم الـ Batch Write وإشعارات الركاب)
  static Future<void> showCancelTripDialog({
    required BuildContext context,
    required String docId,
    required bool isDriver, 
  }) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('إلغاء الرحلة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18.sp)),
        content: Text('هل أنت متأكد من إلغاء هذه الرحلة نهائياً؟ سيتم إشعار جميع الركاب الحاجزين.', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('تراجع', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14.sp))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), 
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text('نعم، إلغاء', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 14.sp))
          ),
        ],
      )
    ) ?? false;

    if (confirm) {
      try {
        WriteBatch batch = FirebaseFirestore.instance.batch();

        // 1. تحديث حالة الرحلة الأساسية
        DocumentReference tripRef = FirebaseFirestore.instance.collection('trips').doc(docId);
        batch.update(tripRef, {
          'status': 'cancelled', 
          'cancelledBy': isDriver ? 'driver' : 'passenger',
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        // 2. لو كابتن هو اللي لغى، نحدث كل الحجوزات المرتبطة عشان الـ Cloud Functions تبعت إشعارات
        if (isDriver) {
          QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
              .collection('trip_bookings')
              .where('tripId', isEqualTo: docId)
              .get();

          for (var doc in bookingsSnapshot.docs) {
            batch.update(doc.reference, {
              'status': 'canceled_by_driver',
              'cancelledAt': FieldValue.serverTimestamp(),
            });
          }
        }

        await batch.commit();
      } catch (e) {
        debugPrint('حدث خطأ أثناء إلغاء الرحلة: $e');
      }
    }
  }

  // 🟢 دالة جديدة لتعديل الرحلة المنشورة (السعر - التاريخ - الوقت)
  static Future<void> showEditPublishedTripDialog({
    required BuildContext context,
    required String docId,
    required String currentPrice,
    DateTime? currentTravelDate,
    required Color royalGreen,
  }) async {
    TextEditingController priceCtrl = TextEditingController(text: currentPrice);
    DateTime selectedDate = currentTravelDate ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            title: Row(
              children: [
                Icon(Icons.edit_calendar_rounded, color: royalGreen, size: 24.sp),
                SizedBox(width: 8.w),
                Text('تعديل تفاصيل الرحلة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: royalGreen)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // حقل السعر
                  Text('السعر للمقعد (ج.م)', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                      prefixIcon: Icon(Icons.monetization_on_outlined, color: Colors.green.shade700),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  // تعديل التاريخ
                  Text('تاريخ الرحلة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: royalGreen)), child: child!),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = DateTime(picked.year, picked.month, picked.day, selectedTime.hour, selectedTime.minute));
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(10.r)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('yyyy/MM/dd', 'en').format(selectedDate), style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
                          Icon(Icons.calendar_today_rounded, size: 18.sp, color: royalGreen),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // تعديل الوقت
                  Text('وقت التحرك', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  InkWell(
                    onTap: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: royalGreen)), child: child!),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                          selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, picked.hour, picked.minute);
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(10.r)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(selectedTime.format(context), style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
                          Icon(Icons.access_time_rounded, size: 18.sp, color: royalGreen),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(ctx), child: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14.sp))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: royalGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
                onPressed: isSubmitting ? null : () async {
                  if (priceCtrl.text.isEmpty) return;
                  setState(() => isSubmitting = true);
                  try {
                    await FirebaseFirestore.instance.collection('trips').doc(docId).update({
                      'price': priceCtrl.text.trim(),
                      'travelDate': Timestamp.fromDate(selectedDate),
                      'departureTime': Timestamp.fromDate(selectedDate), // لتغطية أي مسميات أخرى في الكود
                    });
                    Navigator.pop(ctx);
                  } catch (e) {
                    debugPrint('خطأ في التعديل: $e');
                    setState(() => isSubmitting = false);
                  }
                },
                child: isSubmitting 
                  ? SizedBox(height: 15.h, width: 15.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
              )
            ],
          );
        },
      ),
    );
  }

  // دالة التفاوض
  static Future<void> showNegotiationDialog({
    required BuildContext context,
    required String docId,
    required Color royalGreen,
    required bool isDriver, 
  }) async {
    TextEditingController offerCtrl = TextEditingController();
    await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('التفاوض على الأجرة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18.sp)), 
        content: TextField(
          controller: offerCtrl, 
          keyboardType: TextInputType.number,
          style: TextStyle(color: Colors.black, fontFamily: 'Cairo', fontSize: 14.sp),
          decoration: InputDecoration(
            labelText: 'اكتب سعرك المقترح', 
            labelStyle: TextStyle(fontSize: 14.sp),
            suffixText: 'جنيه', 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r))
          )
        ), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14.sp))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: royalGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
            onPressed: () async { 
              if (offerCtrl.text.isEmpty) return;
              Map<String, dynamic> updates = {
                'status': 'negotiating', 
                'negotiationPrice': offerCtrl.text.trim(), 
                'lastNegotiator': isDriver ? 'driver' : 'passenger' 
              };
              if (isDriver) {
                String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                updates['driverId'] = uid;
              }
              await FirebaseFirestore.instance.collection('trips').doc(docId).update(updates); 
              Navigator.pop(ctx); 
            }, 
            child: Text('إرسال', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp))
          )
        ]
      )
    );
  }

  // دالة إنهاء الرحلة والتقييم
  static Future<void> showRatingDialog({
    required BuildContext context,
    required String docId,
    required Color royalGreen,
    required bool isDriver, 
  }) async {
    int stars = 5; 
    bool isSubmitting = false;

    await showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: Colors.green, size: 60.sp),
                SizedBox(height: 16.h),
                Text('حمد لله على السلامة!\nلقد وصلت لوجهتك.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                SizedBox(height: 16.h),
                
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: List.generate(5, (index) => IconButton(
                      icon: Icon(index < stars ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 35.sp), 
                      onPressed: () => setDialogState(() => stars = index + 1)
                    ))
                  ),
                ),
                
                SizedBox(height: 16.h),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: royalGreen, minimumSize: Size(double.infinity, 45.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), 
                  onPressed: isSubmitting ? null : () async { 
                    setDialogState(() => isSubmitting = true);
                    try {
                      await FirebaseFirestore.instance.collection('trips').doc(docId).update({
                        isDriver ? 'driverRatingForPassenger' : 'passengerRatingForDriver': stars, 
                        'status': 'completed',
                        'completedAt': FieldValue.serverTimestamp()
                      }); 
                      Navigator.pop(ctx); 
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      debugPrint('خطأ في التقييم: $e');
                    }
                  }, 
                  child: isSubmitting 
                      ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('تقييم الرحلة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 14.sp))
                )
              ],
            ),
          );
        }
      )
    );
  }
}