// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:intl/intl.dart' hide TextDirection; // 🟢 مهم جداً عشان نظبط الوقت والتاريخ

import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart'; 
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_trip_tracking_page.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_state.dart';
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';

class DriverActiveTripsTab extends StatefulWidget {
  const DriverActiveTripsTab({super.key});

  @override
  State<DriverActiveTripsTab> createState() => _DriverActiveTripsTabState();
}

class _DriverActiveTripsTabState extends State<DriverActiveTripsTab> {
  
  @override
  void initState() {
    super.initState();
    context.read<DriverActiveTripsCubit>().startListeningToActiveTrips();
  }

  // 🟢 ديالوج التأكيد قبل إلغاء الحجز
  void _showCancelBookingDialog(BuildContext context, DocumentReference bookingRef) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text('إلغاء الحجز', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18.sp)),
        content: Text('هل أنت متأكد من إلغاء هذا الحجز وإزالة الراكب؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تراجع', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await bookingRef.delete(); // مسح الحجز من الداتا بيز
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الحجز بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
              }
            },
            child: const Text('نعم، إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentDriverId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: BlocBuilder<DriverActiveTripsCubit, DriverActiveTripsState>(
        builder: (context, state) {
          if (state is DriverActiveTripsLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))); 
          }

          if (state is DriverActiveTripsError) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.red.shade700), 
              ),
            );
          }

          if (state is DriverActiveTripsLoaded) {
            final trips = state.trips;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // =================================================================
                  // 💺 أولاً: جزء طلبات حجز المقاعد (تمت الشياكة هنا بالكامل ✨)
                  // =================================================================
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('trip_bookings')
                        .where('driverId', isEqualTo: currentDriverId)
                        .where('status', whereIn: ['pending', 'accepted']) 
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h, bottom: 8.h),
                            child: Text(
                              'طلبات حجز السفر', 
                              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: const Color(0xFFD4AF37))
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              var booking = snapshot.data!.docs[index];
                              var data = booking.data() as Map<String, dynamic>;
                              bool isPending = data['status'] == 'pending';
                              
                              // 🟢 تظبيط شكل الوقت والتاريخ
                              String timeString = 'غير محدد';
                              if (data['createdAt'] != null) {
                                DateTime dt = (data['createdAt'] as Timestamp).toDate();
                                timeString = DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(dt);
                              }
                              
                              return Card(
                                elevation: 3,
                                margin: EdgeInsets.only(bottom: 16.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r), 
                                  side: BorderSide(color: isPending ? Colors.orange.withValues(alpha: 0.4) : Colors.green.withValues(alpha: 0.4), width: 1.5)
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(16.w),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // الجزء العلوي: الأيقونة والعنوان
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20.r,
                                            backgroundColor: isPending ? Colors.orange.shade50 : Colors.green.shade50, 
                                            child: Icon(Icons.event_seat_rounded, color: isPending ? Colors.orange : Colors.green, size: 22.sp)
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(data['seats'] == 1 && data['tripType'] == 'full_car' ? 'طلب حجز رحلة كاملة' : 'طلب حجز مقاعد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15.sp, color: const Color(0xFF0F172A))),
                                                SizedBox(height: 4.h),
                                                Text(
                                                  isPending ? '⏳ قيد الانتظار - العميل يطلب ${data['seats']} مقاعد' : '✅ تم القبول - العميل حاجز ${data['seats']} مقاعد', 
                                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold, color: isPending ? Colors.orange.shade700 : Colors.green.shade700)
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      SizedBox(height: 12.h),
                                      
                                      // 🟢 الجزء الأوسط: الوقت والتاريخ
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8.r)),
                                        child: Row(
                                          children: [
                                            Icon(Icons.access_time_filled_rounded, size: 16.sp, color: Colors.grey.shade500),
                                            SizedBox(width: 8.w),
                                            Text('وقت الطلب: $timeString', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),

                                      Padding(padding: EdgeInsets.symmetric(vertical: 12.h), child: const Divider(height: 1)),

                                      // 🟢 الجزء السفلي: الأزرار الشيك (قبول/رفض) أو (شات/إلغاء)
                                      Row(
                                        children: [
                                          if (isPending) ...[
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green.shade700,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                                  padding: EdgeInsets.symmetric(vertical: 10.h)
                                                ),
                                                icon: Icon(Icons.check_circle_rounded, size: 18.sp, color: Colors.white),
                                                label: Text('قبول', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                                                onPressed: () {
                                                  booking.reference.update({'status': 'accepted'});
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم قبول الحجز بنجاح!', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
                                                },
                                              ),
                                            ),
                                            SizedBox(width: 10.w),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.redAccent,
                                                  side: BorderSide(color: Colors.redAccent.shade200),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                                  padding: EdgeInsets.symmetric(vertical: 10.h)
                                                ),
                                                icon: Icon(Icons.close_rounded, size: 18.sp),
                                                label: Text('رفض', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold)),
                                                onPressed: () {
                                                  booking.reference.delete(); // مسح الطلب لو اترفض
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض الطلب بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.redAccent));
                                                },
                                              ),
                                            ),
                                          ] else ...[
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF0F172A),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                                  padding: EdgeInsets.symmetric(vertical: 10.h)
                                                ),
                                                icon: Icon(Icons.chat_bubble_rounded, size: 18.sp, color: Colors.white),
                                                label: Text('مراسلة العميل', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                                                onPressed: () {
                                                  Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: data['tripId'])));
                                                },
                                              ),
                                            ),
                                            SizedBox(width: 10.w),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.redAccent,
                                                  side: BorderSide(color: Colors.redAccent.shade200),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                                  padding: EdgeInsets.symmetric(vertical: 10.h)
                                                ),
                                                icon: Icon(Icons.delete_outline_rounded, size: 18.sp),
                                                label: Text('إلغاء الحجز', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold)),
                                                onPressed: () => _showCancelBookingDialog(context, booking.reference),
                                              ),
                                            ),
                                          ]
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: const Divider(thickness: 1.5),
                          ),
                        ],
                      );
                    },
                  ),

                  // =================================================================
                  // 🚗 ثانياً: جزء المشاوير النشطة العادية (الكود القديم بتاعك)
                  // =================================================================
                  if (trips.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 100.h),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_taxi_rounded, size: 80.sp, color: Colors.grey.shade300), 
                            SizedBox(height: 16.h),
                            Text(
                              'لا توجد رحلات نشطة حالياً',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 18.sp, color: Colors.grey.shade600, fontWeight: FontWeight.bold), 
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(), 
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        var tripData = trips[index].data() as Map<String, dynamic>;
                        String tripId = trips[index].id; 
                        
                        String destination = tripData['destination'] ?? tripData['dropoffAddress'] ?? 'موقع محدد من الخريطة';
                        
                        String finalPrice = tripData['finalPrice']?.toString() 
                                         ?? tripData['negotiationPrice']?.toString() 
                                         ?? tripData['price']?.toString() 
                                         ?? '0';
                                         
                        String status = tripData['status'] ?? 'pending';
                        bool isNegotiating = status == 'negotiating';
                        
                        bool isDriverTurn = isNegotiating && tripData['lastNegotiator'] == 'passenger';

                        return Container(
                          margin: EdgeInsets.only(bottom: 16.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                
                                if (isNegotiating) ...[
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8.r)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.handshake_rounded, color: Colors.orange.shade800, size: 16.sp),
                                        SizedBox(width: 8.w),
                                        Text(
                                          isDriverTurn ? 'العميل يقترح سعراً جديداً' : 'في انتظار رد العميل', 
                                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.orange.shade800, fontWeight: FontWeight.bold)
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                ],

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16.r,
                                      backgroundColor: Colors.red.shade50,
                                      child: Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 18.sp),
                                    ), 
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'وجهة الوصول',
                                            style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade500),
                                          ),
                                          Text(
                                            destination,
                                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15.sp, color: const Color(0xFF0F172A)), 
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16.r,
                                      backgroundColor: Colors.green.shade50,
                                      child: Icon(Icons.monetization_on_rounded, color: Colors.green, size: 18.sp),
                                    ), 
                                    SizedBox(width: 12.w),
                                    Text(
                                      isNegotiating ? 'السعر المقترح: $finalPrice ج.م' : 'السعر النهائي: $finalPrice ج.م',
                                      style: TextStyle(fontFamily: 'Cairo', color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 15.sp), 
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  child: const Divider(color: Color(0xFFEEEEEE)), 
                                ),
                                
                                if (isDriverTurn) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.shade700, 
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                            padding: EdgeInsets.symmetric(vertical: 10.h),
                                            elevation: 0,
                                          ),
                                          icon: Icon(Icons.check_circle_rounded, size: 18.sp),
                                          label: Text('موافق بالسعر', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                          onPressed: () async {
                                            try {
                                              await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
                                                'status': 'accepted',
                                                'finalPrice': tripData['negotiationPrice'], 
                                                'acceptedAt': FieldValue.serverTimestamp(),
                                              });
                                            } catch (e) {
                                              debugPrint('Error accepting trip: $e');
                                            }
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange.shade700, 
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                            padding: EdgeInsets.symmetric(vertical: 10.h),
                                            elevation: 0,
                                          ),
                                          icon: Icon(Icons.handshake_rounded, size: 18.sp),
                                          label: Text('تفاوض', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                          onPressed: () {
                                            TripDialogsHelper.showNegotiationDialog(
                                              context: context, 
                                              docId: tripId,
                                              royalGreen: const Color(0xFF1B4332), 
                                              isDriver: true, 
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                ],

                                if (status == 'accepted') ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1B4332), 
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 12.h),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                      ),
                                      icon: Icon(Icons.play_circle_fill_rounded, size: 20.sp),
                                      label: Text('تفعيل الرحلة النشطة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
                                      onPressed: () {
                                        context.read<DriverActiveTripsCubit>().activateDriverTripFunction(tripId);
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                ],

                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.redAccent, 
                                          side: const BorderSide(color: Colors.redAccent), 
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                          padding: EdgeInsets.symmetric(vertical: 10.h),
                                        ),
                                        icon: Icon(Icons.cancel_outlined, size: 18.sp),
                                        label: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                        onPressed: () {
                                          TripDialogsHelper.showCancelTripDialog(
                                            context: context, 
                                            docId: tripId,
                                            isDriver: true, 
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0F172A), 
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                          padding: EdgeInsets.symmetric(vertical: 10.h),
                                        ),
                                        icon: Icon(Icons.map_rounded, size: 18.sp),
                                        label: Text('التفاصيل والخريطة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                        onPressed: () {
                                          // التعديل هنا: نمرر tripId فقط
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DriverTripTrackingPage(
                                                tripId: tripId,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}