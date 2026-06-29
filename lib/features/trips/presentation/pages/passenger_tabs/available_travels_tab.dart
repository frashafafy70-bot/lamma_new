// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    final Color primaryBlack = const Color(0xFF121212);
    final Color accentGold = const Color(0xFFD4AF37);
    
    final cubit = context.read<AvailableTravelsCubit>();

    return BlocConsumer<AvailableTravelsCubit, AvailableTravelsState>(
      listener: (context, state) {
        if (state is AvailableTravelsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: primaryBlack,
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
          trips = state.trips;
        }

        return Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.radar_rounded, color: showOnlyNearby ? accentGold : Colors.grey, size: 24.sp),
                      SizedBox(width: 8.w),
                      Text('الرحلات القريبة مني فقط', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp, color: primaryBlack)),
                    ],
                  ),
                  Switch(
                    value: showOnlyNearby,
                    activeThumbColor: accentGold,
                    activeTrackColor: primaryBlack,
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade200,
                    onChanged: (val) => cubit.toggleNearby(val),
                  )
                ],
              ),
            ),
            
            if (isLoading)
              LinearProgressIndicator(color: accentGold, backgroundColor: primaryBlack.withValues(alpha: 0.1), minHeight: 3.h),

            Expanded(
              child: _buildTripsList(context, trips, isLoading, primaryBlack, accentGold),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTripsList(BuildContext context, List<Map<String, dynamic>> trips, bool isLoading, Color primaryBlack, Color accentGold) {
    if (isLoading && trips.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accentGold));
    }

    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 50.sp, color: Colors.grey.shade400),
            SizedBox(height: 10.h),
            Text('لا توجد رحلات قريبة في نطاق مدينتك', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
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
        
        String distanceText = dist != double.infinity 
            ? 'يبعد عنك: ${(dist / 1000).toStringAsFixed(1)} كم'
            : '';

        return Card(
          elevation: 4, 
          margin: EdgeInsets.only(bottom: 12.h), 
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الكابتن: ${data['driverName'] ?? 'كابتن لمة'}', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlack, fontFamily: 'Cairo', fontSize: 14.sp)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), 
                      decoration: BoxDecoration(color: accentGold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8.r)), 
                      child: Text('سعر: ${data['price']} ج', style: TextStyle(color: primaryBlack, fontWeight: FontWeight.bold, fontSize: 13.sp))
                    ),
                  ],
                ),
                const Divider(),
                Text('من: ${data['fromCity']} الى: ${data['toCity']}', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
                SizedBox(height: 8.h),
                Text('المركبة: ${data['vehicleType'] ?? 'سيارة'} | المقاعد المتاحة: ${data['availableSeats']}', style: TextStyle(color: Colors.grey.shade700, fontFamily: 'Cairo', fontSize: 13.sp)),
                SizedBox(height: 4.h),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الموعد: ${data['time']}', style: TextStyle(color: Colors.grey.shade700, fontFamily: 'Cairo', fontSize: 13.sp)),
                    if (distanceText.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14.sp, color: accentGold),
                          Text(distanceText, style: TextStyle(color: primaryBlack, fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold)),
                        ],
                      )
                  ],
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity, 
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlack, 
                      foregroundColor: accentGold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))
                    ), 
                    onPressed: () async {
                      try {
                        bool success = await context.read<AvailableTravelsCubit>().bookDriverPost(trip['docId']);
                        if (success && context.mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: trip['docId'])));
                        }
                      } catch (e) {
                         debugPrint('خطأ في الحجز: $e');
                      }
                    }, 
                    icon: Icon(Icons.event_seat_rounded, size: 18.sp), 
                    label: Text('حجز مقعد والتواصل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp))
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