// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TripDialogsHelper {
  
  // 1. حوار مسح الطلب من قائمة الكابتن
  static Future<void> showDeleteTripDialog({
    required BuildContext context,
    required String docId,
  }) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('مسح الطلب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18.sp)),
        content: Text('هل أنت متأكد من إزالة هذا الطلب من القائمة عندك؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
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
      try {
        await FirebaseFirestore.instance.collection('trips').doc(docId).update({'isDeletedForDriver': true});
      } catch (e) {
        debugPrint('خطأ في إخفاء الرحلة: $e');
      }
    }
  }

  // 2. حوار إلغاء الرحلة والاعتذار
  static Future<void> showCancelTripDialog({
    required BuildContext context,
    required String docId,
  }) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('إلغاء الرحلة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18.sp)),
        content: Text('هل أنت متأكد من إلغاء هذه الرحلة؟ سيتم إبلاغ الطرف الآخر.', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
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
        await FirebaseFirestore.instance.collection('trips').doc(docId).update({
          'status': 'cancelled', 
          'cancelledBy': 'driver'
        });
        
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إلغاء الرحلة بنجاح', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: Colors.orange)
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الإلغاء', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: Colors.red)
        );
      }
    }
  }

  // 3. حوار التفاوض
  static void showNegotiationDialog({
    required BuildContext context,
    required String docId,
    required Color royalGreen,
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
              try {
                await FirebaseFirestore.instance.collection('trips').doc(docId).update({
                  'status': 'negotiating', 
                  'negotiationPrice': offerCtrl.text.trim(), 
                  'lastNegotiator': 'driver'
                }); 
                
                if (!ctx.mounted) return;
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

  // 4. حوار التقييم
  static void showRatingDialog({
    required BuildContext context,
    required String docId,
    required Color royalGreen,
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
                    icon: Icon(Icons.close, color: Colors.grey, size: 24.sp),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                Icon(Icons.verified_rounded, color: Colors.green, size: 60.sp),
                SizedBox(height: 16.h),
                Text('تم إنهاء الرحلة!', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
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
                        'driverRatingForPassenger': stars, 
                        'status': 'completed'
                      }); 
                      
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx); 
                    } catch (e) {
                      if (ctx.mounted) {
                        setDialogState(() => isSubmitting = false);
                      }
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