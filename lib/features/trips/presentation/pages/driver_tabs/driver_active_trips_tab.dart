// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import 'package:intl/intl.dart' hide TextDirection; 

// استدعاء صفحة الشات
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';

// الاستدعاءات الصحيحة المطلقة لملفات الكيوبت بناءً على مسارات مشروعك
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_state.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_location_cubit.dart';

class DriverActiveTripsTab extends StatefulWidget {
  final TabController tabController; 
  const DriverActiveTripsTab({super.key, required this.tabController});

  @override
  State<DriverActiveTripsTab> createState() => _DriverActiveTripsTabState();
}

class _DriverActiveTripsTabState extends State<DriverActiveTripsTab> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color royalGreen = const Color(0xFF1B4332);

  @override
  void initState() {
    super.initState();
    // 1. تشغيل جلب الرحلات عن طريق الكيوبت
    context.read<DriverActiveTripsCubit>().startListeningToActiveTrips();
    
    // 2. تشغيل تتبع الموقع (Throttling)
    context.read<DriverLocationCubit>().startLocationTracking();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverActiveTripsCubit, DriverActiveTripsState>(
      builder: (context, state) {
        if (state is DriverActiveTripsLoading) {
          return Center(child: CircularProgressIndicator(color: royalGreen));
        }
        
        if (state is DriverActiveTripsError) {
          return Center(
            child: Text(
              state.message, 
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.red)
            )
          );
        }

        if (state is DriverActiveTripsLoaded) {
          var trips = state.trips;

          if (trips.isEmpty) {
            return Center(child: Text('لا توجد رحلات/طلبات نشطة حاليا.', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              var docId = trips[index].id;
              var data = trips[index].data() as Map<String, dynamic>;
              
              return _ActiveTripCard(
                docId: docId,
                data: data,
                royalGreen: royalGreen,
              );
            },
          );
        }

        return const SizedBox.shrink(); 
      },
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final Color royalGreen;

  const _ActiveTripCard({
    required this.docId,
    required this.data,
    required this.royalGreen,
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

  Future<void> _deleteTripForUser(BuildContext context) async {
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

  Future<void> _cancelTrip(BuildContext context) async {
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
          'status': 'canceled', 
          'cancelledBy': 'driver'
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم إلغاء الرحلة بنجاح', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: Colors.orange)
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ أثناء الإلغاء', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: Colors.red)
          );
        }
      }
    }
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

  void _showRatingDialog(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    bool isNegotiating = data['status'] == 'negotiating';
    bool isCanceled = data['status'] == 'canceled';
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
                    Icon(isErrand ? Icons.shopping_bag : Icons.local_taxi, color: royalGreen, size: 24.sp),
                    SizedBox(width: 8.w),
                    Text(
                      isErrand ? 'طلب أوردر' : 'توصيل عميل (${data['vehicleType'] ?? ''})', 
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
                      onTap: () => _deleteTripForUser(context),
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
              if (data['lastNegotiator'] == 'driver')
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.orange, size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text('في انتظار رد العميل على عرضك (${data['negotiationPrice']} ج)', style: TextStyle(color: Colors.orange, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
                      child: Text('عرض العميل: ${data['negotiationPrice']} ج', style: TextStyle(color: Colors.blue, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: royalGreen, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), 
                            onPressed: () => _acceptOffer(data['negotiationPrice']), 
                            child: Text('موافق', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 13.sp))
                          )
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), 
                            onPressed: () => _showNegotiationDialog(context), 
                            child: Text('تفاوض', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 13.sp))
                          )
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), 
                            onPressed: () => _cancelTrip(context), 
                            child: Text('رفض', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 13.sp))
                          )
                        ),
                      ],
                    )
                  ],
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
                          onPressed: () => _showRatingDialog(context), 
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
                      onPressed: () => _cancelTrip(context), 
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