// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  // دالة إلغاء الرحلة
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
        content: Text('هل أنت متأكد من إلغاء هذه الرحلة؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
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
      await FirebaseFirestore.instance.collection('trips').doc(docId).update({
        'status': 'cancelled', 
        'cancelledBy': isDriver ? 'driver' : 'passenger' 
      });
    }
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

  // 🟢 دالة إنهاء الرحلة والتقييم (محدثة بالرسائل والمنطق الجديد)
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
                // 🟢 الرسالة المحدثة
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
                      // 🟢 حفظ التقييم لكل طرف بوضوح
                      await FirebaseFirestore.instance.collection('trips').doc(docId).update({
                        isDriver ? 'driverRatingForPassenger' : 'passengerRatingForDriver': stars, 
                        'status': 'completed',
                        // إضافة ختم زمني للإتمام
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