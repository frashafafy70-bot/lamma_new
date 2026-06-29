// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import 'package:intl/intl.dart' hide TextDirection; 

import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';
import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart';

// 💡 خطوة الحل النهائي بعد نسخ هذا الكود:
// 1. انزل في الكود للسطر رقم 106 أو أي مكان فيه كلمة `TripDialogsHelper` (هتلاقي تحتها خط أحمر).
// 2. ضع مؤشر الماوس (الكيرسور) على الكلمة.
// 3. اضغط من لوحة المفاتيح على: `Ctrl + .` (كنترول مع حرف الزين).
// 4. هتظهرلك قائمة صغيرة، اختار منها أول خيار: `Import library '...'`
// المحرر هيكتب المسار الصحيح فوق تلقائياً والـ 6 أخطاء هيختفوا فوراً!

class ActiveTripCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final Color royalGreen;
  final bool isDriver; 

  const ActiveTripCard({
    super.key,
    required this.docId,
    required this.data,
    required this.royalGreen,
    required this.isDriver, 
  });

  String _formatTripDate(dynamic createdAt) {
    if (createdAt == null) return 'الوقت غير متاح';
    
    DateTime date;
    if (createdAt is Timestamp) {
      date = createdAt.toDate();
    } else if (createdAt is String) {
      date = DateTime.tryParse(createdAt) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }
    
    return DateFormat('dd MMM yyyy, hh:mm a', 'ar').format(date);
  }

  Future<void> _acceptOffer(String acceptedPrice) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(docId).update({
        'status': 'accepted', 
        'finalPrice': acceptedPrice
      });
    } catch (e) {
      debugPrint('خطأ في قبول العرض: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isNegotiating = data['status'] == 'negotiating';
    bool isCanceled = data['status'] == 'cancelled';
    bool isErrand = data['tripCategory'] == 'طلبات';
    
    String finalPrice = data['finalPrice']?.toString() ?? data['negotiationPrice']?.toString() ?? data['price']?.toString() ?? 'غير محدد';

    return Card(
      elevation: 4, 
      margin: EdgeInsets.only(bottom: 16.h),
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: Colors.grey.shade200)
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(isErrand ? Icons.shopping_bag : (isDriver ? Icons.local_taxi : Icons.person_pin), color: royalGreen, size: 24.sp),
                    SizedBox(width: 8.w),
                    Text(
                      isErrand ? 'طلب أوردر' : (isDriver ? 'توصيل عميل (${data['vehicleType'] ?? ''})' : 'رحلتي (${data['vehicleType'] ?? ''})'), 
                      style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 15.sp, color: royalGreen)
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isCanceled ? Colors.red.shade50 : (isNegotiating ? Colors.orange.shade50 : Colors.green.shade50),
                        borderRadius: BorderRadius.circular(12.r)
                      ),
                      child: Text(
                        isCanceled ? 'ملغي' : (isNegotiating ? 'تفاوض' : 'مقبول'),
                        style: TextStyle(
                          color: isCanceled ? Colors.red : (isNegotiating ? Colors.orange.shade800 : Colors.green.shade800),
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    InkWell(
                      onTap: () => TripDialogsHelper.showDeleteTripDialog(context: context, docId: docId, isDriver: isDriver),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20.sp),
                      ),
                    ),
                  ],
                )
              ],
            ),
            
            SizedBox(height: 12.h),
            
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: Colors.grey.shade500, size: 18.sp),
                SizedBox(width: 6.w),
                Text(
                  _formatTripDate(data['createdAt']),
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            
            Divider(height: 24.h, color: Colors.grey.shade200),
            
            Row(
              children: [
                Icon(Icons.my_location, color: Colors.green, size: 16.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    data['pickup'] ?? 'غير محدد',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 16.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    data['destination'] ?? 'غير محدد',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('السعر:', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade700, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                Text('$finalPrice ج.م', style: TextStyle(fontFamily: 'Cairo', color: Colors.amber.shade700, fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            if (isCanceled)
              Container(
                width: double.infinity, 
                padding: EdgeInsets.all(12.w), 
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8.r)),
                child: Text('لقد تم إلغاء هذه الرحلة', textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14.sp))
              )
            else if (isNegotiating)
              Builder(
                builder: (context) {
                  bool isMyTurnToNegotiate = (isDriver && data['lastNegotiator'] == 'passenger') || (!isDriver && data['lastNegotiator'] == 'driver');
                  bool isWaitingForOther = !isMyTurnToNegotiate;

                  if (isWaitingForOther) {
                    return Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.orange, size: 20.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text('في انتظار رد ${isDriver ? "العميل" : "الكابتن"} على عرضك (${data['negotiationPrice']} ج)', style: TextStyle(color: Colors.orange, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
                          child: Text('عرض ${isDriver ? "العميل" : "الكابتن"}: ${data['negotiationPrice']} ج', style: TextStyle(color: Colors.blue, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: royalGreen, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), 
                                onPressed: () => _acceptOffer(data['negotiationPrice'].toString()), 
                                child: Text('موافق', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 13.sp))
                              )
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), 
                                onPressed: () => TripDialogsHelper.showNegotiationDialog(context: context, docId: docId, royalGreen: royalGreen, isDriver: isDriver), 
                                child: Text('تفاوض', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 13.sp))
                              )
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), 
                                onPressed: () => TripDialogsHelper.showCancelTripDialog(context: context, docId: docId, isDriver: isDriver), 
                                child: Text('رفض', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 13.sp))
                              )
                            ),
                          ],
                        )
                      ],
                    );
                  }
                }
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            elevation: 0,
                          ), 
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TripChatPage(tripId: docId)),
                            );
                          }, 
                          icon: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18.sp), 
                          label: Text('فتح المحادثة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp))
                        )
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: royalGreen, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            elevation: 0,
                          ), 
                          onPressed: () => TripDialogsHelper.showRatingDialog(context: context, docId: docId, royalGreen: royalGreen, isDriver: isDriver), 
                          icon: Icon(Icons.done_all, color: Colors.white, size: 18.sp), 
                          label: Text('إنهاء الرحلة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp))
                        )
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
                      onPressed: () => TripDialogsHelper.showCancelTripDialog(context: context, docId: docId, isDriver: isDriver), 
                      icon: Icon(Icons.cancel, color: Colors.red, size: 18.sp), 
                      label: Text('إلغاء واعتذار', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 13.sp))
                    ),
                  )
                ],
              )
          ],
        ),
      ),
    );
  }
}