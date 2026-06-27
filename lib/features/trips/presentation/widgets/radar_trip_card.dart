// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import '../../cubit/driver/driver_radar_cubit.dart';
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';

class RadarTripCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String currentUserId;
  final Color royalGreen;
  final TabController tabController;

  const RadarTripCard({
    super.key,
    required this.docId,
    required this.data,
    required this.currentUserId,
    required this.royalGreen,
    required this.tabController,
  });

  void _showNegotiationDialog(BuildContext context) {
    TextEditingController offerCtrl = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('التفاوض على الأجرة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18.sp)), 
        content: TextField(
          controller: offerCtrl, 
          keyboardType: TextInputType.number,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
          decoration: InputDecoration(
            labelText: 'اكتب سعرك المقترح (جنيه)',
            labelStyle: TextStyle(fontSize: 14.sp),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r))
          ),
        ), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14.sp))),
          // 🟢 تم إضافة زر الموافقة المباشرة على سعر العميل من داخل التفاوض
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
            onPressed: () async { 
              await context.read<DriverRadarCubit>().acceptTrip(docId, data['suggestedPrice'].toString());
              if (ctx.mounted) {
                Navigator.pop(ctx); 
                tabController.animateTo(2); 
              }
            }, 
            child: Text('موافق (${data['suggestedPrice']} ج)', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12.sp))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: royalGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
            onPressed: () async { 
              if (offerCtrl.text.trim().isEmpty) return;
              
              // نكلم الكيوبت عشان يرفع التفاوض لفايربيز
              await context.read<DriverRadarCubit>().negotiateTrip(docId, offerCtrl.text.trim());
              
              if (ctx.mounted) {
                Navigator.pop(ctx); 
                tabController.animateTo(2); 
              }
            }, 
            child: Text('إرسال العرض', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12.sp))
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isErrand = data['tripCategory'] == 'طلبات';
    bool isNegotiating = data['status'] == 'negotiating';
    
    String formattedDate = '';
    if (data.containsKey('createdAt') && data['createdAt'] != null) {
      Timestamp timestamp = data['createdAt'];
      DateTime dt = timestamp.toDate();
      formattedDate = "${dt.day}/${dt.month}/${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    
    return Card(
      elevation: 4, 
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h), 
                  decoration: BoxDecoration(color: isErrand ? Colors.indigo.shade50 : royalGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)), 
                  child: Text(isErrand ? '🛒 شراء طلبات' : '🚕 مشوار توصيل', style: TextStyle(color: isErrand ? Colors.indigo : royalGreen, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12.sp))
                ),
                if (isNegotiating)
                  Text('جاري التفاوض..', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12.sp)),
              ],
            ),
            SizedBox(height: 12.h),
            Text('العميل: ${data['passengerName'] ?? 'عميل'}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, fontFamily: 'Cairo')),
            SizedBox(height: 6.h),
            Text(isErrand ? 'من: ${data['pickup']}\nإلى: ${data['destination']}' : '📍 من: ${data['pickup']}\n🏁 إلى: ${data['destination']}', style: TextStyle(fontSize: 13.sp, color: Colors.black54, fontFamily: 'Cairo')),
            
            if (formattedDate.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14.sp, color: Colors.grey.shade500),
                  SizedBox(width: 4.w),
                  Text(formattedDate, style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade500, fontSize: 11.sp, fontWeight: FontWeight.w600)),
                ],
              ),
            ],

            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.w), 
              decoration: BoxDecoration(color: isNegotiating ? Colors.orange.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(8.r)), 
              child: Text(isNegotiating ? 'عرضك الأخير: ${data['negotiationPrice']} ج' : 'سعر العميل: ${data['suggestedPrice'] ?? '0'} ج', textAlign: TextAlign.center, style: TextStyle(color: isNegotiating ? Colors.orange.shade800 : Colors.green.shade800, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14.sp)),
            ),
            SizedBox(height: 12.h),
            if (!isNegotiating)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: royalGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), 
                      onPressed: () async {
                        // نكلم الكيوبت عشان يقبل الرحلة
                        await context.read<DriverRadarCubit>().acceptTrip(docId, data['suggestedPrice'].toString());
                        if (context.mounted) tabController.animateTo(2); 
                      }, 
                      child: Text('قبول فوراً', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp))
                    )
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), 
                      onPressed: () => _showNegotiationDialog(context), 
                      child: Text('تفاوض', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp))
                    )
                  ),
                ],
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: Size(double.infinity, 45.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: docId))),
                child: Text('متابعة المحادثة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp))
              )
          ],
        ),
      ),
    );
  }
}