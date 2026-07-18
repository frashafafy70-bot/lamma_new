import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TripDialogsHelper {
  
  // 1. حوار مسح الطلب من القائمة (مخصص للسائق والعميل)
  static Future<void> showDeleteTripDialog({
    required BuildContext context,
    required String docId,
    required bool isDriver, 
  }) async {
    final localizations = AppLocalizations.of(context)!;
    
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(localizations.deleteTripTitle, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18.sp)),
        content: Text(localizations.deleteTripConfirmation, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(localizations.goBack, style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14.sp))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), 
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(localizations.yesDelete, style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 14.sp))
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
    final localizations = AppLocalizations.of(context)!;
    
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(localizations.cancelTripTitle, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18.sp)),
        content: Text(localizations.cancelTripConfirmation, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(localizations.goBack, style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14.sp))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), 
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(localizations.yesCancel, style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 14.sp))
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.tripCancelledSuccessfully, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: Colors.orange)
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.errorDuringCancellation, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: Colors.red)
          );
        }
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
    final localizations = AppLocalizations.of(context)!;
    TextEditingController offerCtrl = TextEditingController();
    
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(localizations.negotiateFareTitle, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18.sp)), 
        content: TextField(
          controller: offerCtrl, 
          keyboardType: TextInputType.number,
          style: TextStyle(color: Colors.black, fontFamily: 'Cairo', fontSize: 14.sp),
          decoration: InputDecoration(
            labelText: localizations.suggestedPriceHint, 
            labelStyle: TextStyle(fontSize: 14.sp),
            suffixText: localizations.currencyEGP, 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r))
          )
        ), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(localizations.cancel, style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14.sp))),
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
                if (ctx.mounted) Navigator.pop(ctx); 
              } catch (e) {
                debugPrint('خطأ في إرسال التفاوض: $e');
              }
            }, 
            child: Text(localizations.sendBtn, style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp))
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
    final localizations = AppLocalizations.of(context)!;
    int stars = 5; 
    bool isSubmitting = false;

    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
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
                Text(localizations.tripEndedTitle, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
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
                        'status': 'completed'
                      }); 
                      if (ctx.mounted) Navigator.pop(ctx); 
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      debugPrint('خطأ في التقييم: $e');
                    }
                  }, 
                  child: isSubmitting 
                      ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(localizations.submitRatingBtn, style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 14.sp))
                )
              ],
            ),
          );
        }
      )
    );
  }
}