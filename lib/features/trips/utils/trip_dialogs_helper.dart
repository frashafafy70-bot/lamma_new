// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// استدعاء ملف الألوان المركزي
import 'package:lamma_new/core/theme/app_colors.dart';

class TripDialogsHelper {
  
  // 1. حوار مسح الطلب من القائمة (مخصص للكابتن والعميل)
  static Future<void> showDeleteTripDialog({
    required BuildContext context,
    required String docId,
    required bool isDriver, 
  }) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('مسح الطلب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 18.sp)),
        content: Text('هل أنت متأكد من إزالة هذا الطلب من القائمة عندك؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('تراجع', style: TextStyle(fontFamily: 'Cairo', color: AppColors.textMuted, fontSize: 14.sp))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), 
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text('نعم، امسح', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 14.sp))
          ),
        ],
      )
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('trips').doc(docId).update({
          isDriver ? 'isDeletedForDriver' : 'isDeletedForPassenger': true
        });
      } catch (e) {
        debugPrint('خطأ في إخفاء الرحلة: $e');
      }
    }
  }

  // 2. حوار إلغاء الرحلة والاعتذار
  static Future<void> showCancelTripDialog({
    required BuildContext context,
    required String docId,
    required bool isDriver, 
  }) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('إلغاء الرحلة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 18.sp)),
        content: Text('هل أنت متأكد من إلغاء هذه الرحلة؟ سيتم إبلاغ الطرف الآخر.', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('تراجع', style: TextStyle(fontFamily: 'Cairo', color: AppColors.textMuted, fontSize: 14.sp))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), 
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text('نعم، إلغاء', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 14.sp))
          ),
        ],
      )
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('trips').doc(docId).update({
          'status': 'cancelled', 
          'cancelledBy': isDriver ? 'driver' : 'passenger' 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إلغاء الرحلة بنجاح', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: AppColors.warning)
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الإلغاء', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: AppColors.error)
        );
      }
    }
  }

  // 3. حوار التفاوض وإرسال سعر جديد
  static void showNegotiationDialog({
    required BuildContext context,
    required String docId,
    required Color royalGreen,
    required bool isDriver, 
  }) {
    TextEditingController offerCtrl = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('التفاوض على الأجرة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18.sp)), 
        content: TextField(
          controller: offerCtrl, 
          keyboardType: TextInputType.number,
          style: TextStyle(color: AppColors.textDark, fontFamily: 'Cairo', fontSize: 14.sp),
          decoration: InputDecoration(
            labelText: 'اكتب سعرك المقترح', 
            labelStyle: TextStyle(fontSize: 14.sp, color: AppColors.textMuted.shade600),
            suffixText: 'جنيه', 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: AppColors.dividerColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: royalGreen, width: 2))
          )
        ), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: AppColors.textMuted, fontSize: 14.sp))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: royalGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
            onPressed: () async { 
              if (offerCtrl.text.isEmpty) return;
              try {
                await FirebaseFirestore.instance.collection('trips').doc(docId).update({
                  'status': 'negotiating', 
                  'negotiationPrice': offerCtrl.text.trim(), 
                  'lastNegotiator': isDriver ? 'driver' : 'passenger' 
                }); 
                Navigator.pop(ctx); 
              } catch (e) {
                debugPrint('خطأ في إرسال التفاوض: $e');
              }
            }, 
            child: Text('إرسال', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp))
          )
        ]
      )
    );
  }

  // 4. حوار إنهاء الرحلة والتقييم بالنجوم
  static void showRatingDialog({
    required BuildContext context,
    required String docId,
    required Color royalGreen,
    required bool isDriver, 
  }) {
    int stars = 5; 
    bool isSubmitting = false;

    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.close, color: AppColors.textMuted, size: 24.sp),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                Icon(Icons.verified_rounded, color: AppColors.success, size: 60.sp),
                SizedBox(height: 16.h),
                Text('تم إنهاء الرحلة!', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppColors.textDark)),
                SizedBox(height: 16.h),
                
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: List.generate(5, (index) => IconButton(
                      icon: Icon(index < stars ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.warning, size: 35.sp), 
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
                        'status': 'completed'
                      }); 
                      Navigator.pop(ctx); 
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      debugPrint('خطأ في التقييم: $e');
                    }
                  }, 
                  child: isSubmitting 
                      ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('إرسال التقييم', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 14.sp))
                )
              ],
            ),
          );
        }
      )
    );
  }
}