// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection; 

import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';
import '../../../cubit/passenger/available_travels_cubit.dart';
import '../../../cubit/passenger/available_travels_state.dart';

class AvailableTravelsTab extends StatelessWidget {
  const AvailableTravelsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AvailableTravelsCubit()..init(),
      child: const _AvailableTravelsView(),
    );
  }
}

class _AvailableTravelsView extends StatelessWidget {
  const _AvailableTravelsView();

  @override
  Widget build(BuildContext context) {
    final Color royalGreen = const Color(0xFF1B4332);
    final Color accentGold = const Color(0xFFD4AF37);
    final Color darkSlate = const Color(0xFF0F172A);
    
    final cubit = context.read<AvailableTravelsCubit>();

    return BlocConsumer<AvailableTravelsCubit, AvailableTravelsState>(
      listener: (context, state) {
        if (state is AvailableTravelsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      builder: (context, state) {
        bool showOnlyNearby = false;
        List<Map<String, dynamic>> trips = [];
        bool isLoading = state is AvailableTravelsInitial || state is AvailableTravelsLoading;

        if (state is AvailableTravelsLoaded) {
          showOnlyNearby = state.showOnlyNearby;
          String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
          
          trips = state.trips.where((trip) {
            var data = trip['data'] as Map<String, dynamic>? ?? {};
            String tripOwnerId = data['userId'] ?? data['driverId'] ?? data['uid'] ?? '';
            return tripOwnerId != currentUserId;
          }).toList();
        }

        return Column(
          children: [
            // 🟢 شريط الفلترة العلوي
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(color: showOnlyNearby ? royalGreen.withOpacity(0.1) : Colors.grey.shade100, shape: BoxShape.circle),
                        child: Icon(Icons.radar_rounded, color: showOnlyNearby ? royalGreen : Colors.grey, size: 20.sp),
                      ),
                      SizedBox(width: 10.w),
                      Text('الرحلات القريبة مني فقط', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp, color: darkSlate)),
                    ],
                  ),
                  Switch(
                    value: showOnlyNearby,
                    activeColor: Colors.white,
                    activeTrackColor: royalGreen,
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade200,
                    onChanged: (val) => cubit.toggleNearby(val),
                  )
                ],
              ),
            ),
            
            if (isLoading)
              LinearProgressIndicator(color: accentGold, backgroundColor: royalGreen.withOpacity(0.1), minHeight: 3.h),

            Expanded(
              child: _buildTripsList(context, trips, isLoading, royalGreen, accentGold, darkSlate),
            ),
          ],
        );
      },
    );
  }

  // 🟢 ديالوج اختيار عدد المقاعد
  void _showBookingDialog(BuildContext context, Map<String, dynamic> trip, String driverId, int maxSeats, Color royalGreen) {
    int selectedSeats = 1;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            title: Text('حجز مقاعد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18.sp, color: royalGreen), textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('حدد عدد المقاعد التي تريد حجزها', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: selectedSeats > 1 ? () => setState(() => selectedSeats--) : null,
                      icon: Icon(Icons.remove_circle_outline, color: selectedSeats > 1 ? Colors.red : Colors.grey, size: 28.sp),
                    ),
                    SizedBox(width: 16.w),
                    Text('$selectedSeats', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 22.sp)),
                    SizedBox(width: 16.w),
                    IconButton(
                      onPressed: selectedSeats < maxSeats ? () => setState(() => selectedSeats++) : null,
                      icon: Icon(Icons.add_circle_outline, color: selectedSeats < maxSeats ? royalGreen : Colors.grey, size: 28.sp),
                    ),
                  ],
                ),
                if (maxSeats > 1) ...[
                  SizedBox(height: 8.h),
                  Text('(الحد الأقصى $maxSeats مقاعد)', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade600)),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14.sp)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: royalGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                ),
                onPressed: isSubmitting ? null : () async {
                  setState(() => isSubmitting = true);
                  bool success = await context.read<AvailableTravelsCubit>().bookSeatInDriverPost(trip['docId'], driverId, selectedSeats);
                  if (success && ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال طلب الحجز للكابتن بنجاح! تابع "متابعة طلباتي"', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green),
                    );
                  } else {
                    setState(() => isSubmitting = false);
                  }
                },
                child: isSubmitting 
                  ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('تأكيد الحجز', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildTripsList(BuildContext context, List<Map<String, dynamic>> trips, bool isLoading, Color royalGreen, Color accentGold, Color darkSlate) {
    if (isLoading && trips.isEmpty) {
      return Center(child: CircularProgressIndicator(color: royalGreen));
    }

    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_filled_rounded, size: 80.sp, color: Colors.grey.shade300),
            SizedBox(height: 16.h),
            Text('لا توجد رحلات متاحة حالياً', style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: trips.length,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemBuilder: (context, index) {
        var trip = trips[index];
        var data = trip['data'];
        
        double dist = (trip['distance'] as num).toDouble();
        String distanceText = dist != double.infinity ? 'يبعد: ${(dist / 1000).toStringAsFixed(1)} كم' : '';

        String driverName = (data['driverName']?.toString().trim().isNotEmpty ?? false) ? data['driverName'] : 'كابتن لَمَّة';
        String price = data['price']?.toString() ?? 'غير محدد';
        String pickup = data['pickup'] ?? data['pickupAddress'] ?? data['fromCity'] ?? 'نقطة الانطلاق غير محددة';
        String dropoff = data['destination'] ?? data['dropoffAddress'] ?? data['toCity'] ?? 'نقطة الوصول غير محددة';
        int maxSeats = int.tryParse(data['availableSeats']?.toString() ?? '0') ?? 0;
        
        String timeString = 'غير محدد';
        if (data['travelDate'] != null) {
          DateTime dt = (data['travelDate'] as Timestamp).toDate();
          timeString = DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(dt);
        } else if (data['departureTime'] != null) {
          DateTime dt = (data['departureTime'] as Timestamp).toDate();
          timeString = DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(dt);
        }

        String tripDriverId = data['driverId'] ?? data['userId'] ?? data['uid'] ?? '';

        return Card(
          elevation: 4, 
          margin: EdgeInsets.only(bottom: 16.h), 
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r), side: BorderSide(color: accentGold.withOpacity(0.5), width: 1.5)),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس الكارت: بيانات الكابتن والمقاعد
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18.r,
                          backgroundColor: Colors.grey.shade200,
                          child: Icon(Icons.person, color: Colors.grey.shade600, size: 20.sp),
                        ),
                        SizedBox(width: 8.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(driverName, style: TextStyle(fontWeight: FontWeight.bold, color: darkSlate, fontFamily: 'Cairo', fontSize: 14.sp)),
                            Text('كابتن موثوق', style: TextStyle(color: Colors.green.shade700, fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h), 
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8.r)), 
                      child: Text('متاح $maxSeats مقاعد', style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12.sp, fontFamily: 'Cairo'))
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                
                // خط السير (فخم زي شاشة الكابتن)
                Row(
                  children: [
                    Column(
                      children: [
                        Icon(Icons.my_location_rounded, color: royalGreen, size: 18.sp),
                        Container(height: 25.h, width: 2.w, color: Colors.grey.shade300),
                        Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 18.sp),
                      ],
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pickup, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: darkSlate), maxLines: 1, overflow: TextOverflow.ellipsis),
                          SizedBox(height: 20.h),
                          Text(dropoff, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: darkSlate), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16.h),
                
                // الوقت والسعر
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10.r)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, color: Colors.grey.shade600, size: 16.sp),
                          SizedBox(width: 6.w),
                          Text(timeString, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text('$price ج.م', style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                // 🟢 تم إضافة شرط التحقق من عدد المقاعد هنا 🟢
                maxSeats <= 0
                ? SizedBox(
                    width: double.infinity, 
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade400, 
                        disabledBackgroundColor: Colors.grey.shade400,
                        disabledForegroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))
                      ), 
                      onPressed: null, // تعطيل الزر تماماً
                      icon: Icon(Icons.event_seat_rounded, size: 18.sp, color: Colors.white), 
                      label: Text('الرحلة مكتملة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp))
                    )
                  )
                : SizedBox(
                    width: double.infinity, 
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkSlate, 
                        foregroundColor: accentGold,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))
                      ), 
                      onPressed: () => _showBookingDialog(context, trip, tripDriverId, maxSeats, royalGreen), 
                      icon: Icon(Icons.event_seat_rounded, size: 18.sp), 
                      label: Text('احجز مقعدك الآن', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp))
                    )
                  )
              ],
            ),
          ),
        );
      },
    );
  }
}