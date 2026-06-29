// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🟢 تمت إضافته لتمكين زر قبول التسعيرة

import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart'; 
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_trip_tracking_page.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_state.dart';

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

  @override
  Widget build(BuildContext context) {
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

            if (trips.isEmpty) {
              return Center(
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
              );
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
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
                
                // 🟢 متغير للتحقق هل الدور على الكابتن للرد على السعر؟
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
                        
                        // 🟢 إشعار حالة التفاوض (في انتظار رد العميل / أو العميل يقترح سعراً)
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
                        
                        // 🟢 تمت إضافة أزرار الموافقة والتفاوض للكابتن هنا
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
                                      // 🟢 قبول السعر وتثبيته كـ finalPrice وتحويل الحالة إلى accepted
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

                        // 🟢 زر تفعيل الرحلة (يظهر فقط إذا تمت الموافقة النهائية)
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

                        // 🟢 الأزرار الافتراضية (إلغاء والتفاصيل)
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DriverTripTrackingPage(
                                        tripId: tripId,
                                        destination: destination,
                                        price: finalPrice,
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
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}