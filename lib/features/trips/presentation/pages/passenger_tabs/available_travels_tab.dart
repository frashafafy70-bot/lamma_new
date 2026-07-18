// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection; 

// 🟢 استيراد الـ Injection
import '../../../trip_injection.dart'; 

import '../../../cubit/passenger/available_travels_cubit.dart';
import '../../../cubit/passenger/available_travels_state.dart';
import '../../../cubit/passenger/trip_booking_cubit.dart';
import '../../../cubit/passenger/trip_booking_state.dart';
import '../../data/models/trip_model.dart';

class AvailableTravelsTab extends StatelessWidget {
  const AvailableTravelsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 🟢 استخدام MultiBlocProvider لتوفير كيوبيت العرض وكيوبيت الحجز معاً باستخدام sl
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<AvailableTravelsCubit>()..init(FirebaseAuth.instance.currentUser?.uid ?? ''),
        ),
        BlocProvider(
          create: (context) => sl<TripBookingCubit>(),
        ),
      ],
      child: const _AvailableTravelsView(),
    );
  }
}

class _AvailableTravelsView extends StatefulWidget {
  const _AvailableTravelsView();

  @override
  State<_AvailableTravelsView> createState() => _AvailableTravelsViewState();
}

class _AvailableTravelsViewState extends State<_AvailableTravelsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= (maxScroll - 200)) {
      context.read<AvailableTravelsCubit>().fetchMoreTrips();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color royalGreen = const Color(0xFF1B4332);
    final Color accentGold = const Color(0xFFD4AF37);
    final Color darkSlate = const Color(0xFF0F172A);
    
    final cubit = context.read<AvailableTravelsCubit>();

    // 🟢 الاستماع لنتيجة الحجز من TripBookingCubit
    return MultiBlocListener(
      listeners: [
        BlocListener<AvailableTravelsCubit, AvailableTravelsState>(
          listener: (context, state) {
            if (state is AvailableTravelsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red.shade700),
              );
            }
          },
        ),
        BlocListener<TripBookingCubit, TripBookingState>(
          listener: (context, state) {
            if (state is TripBookingSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green),
              );
            } else if (state is TripBookingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red.shade700),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<AvailableTravelsCubit, AvailableTravelsState>(
        builder: (context, state) {
          bool showOnlyNearby = false;
          List<ProcessedTrip> processedTrips = [];
          bool isLoading = state is AvailableTravelsInitial || state is AvailableTravelsLoading;
          bool isFetchingMore = false;

          if (state is AvailableTravelsLoaded) {
            showOnlyNearby = state.showOnlyNearby;
            processedTrips = state.trips;
            isFetchingMore = state.isFetchingMore;
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
                child: RefreshIndicator(
                  color: royalGreen,
                  onRefresh: () async {
                    cubit.init(FirebaseAuth.instance.currentUser?.uid ?? ''); 
                  },
                  child: _buildTripsList(context, processedTrips, isLoading, isFetchingMore, royalGreen, accentGold, darkSlate),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🟢 ديالوج اختيار عدد المقاعد
  void _showBookingDialog(BuildContext context, String tripId, String driverId, int maxSeats, Color royalGreen) {
    int selectedSeats = 1;

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
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14.sp)),
              ),
              
              // 🟢 الاستماع لـ TripBookingCubit لإظهار اللودينج داخل الزرار
              BlocBuilder<TripBookingCubit, TripBookingState>(
                builder: (context, bookingState) {
                  bool isSubmitting = bookingState is TripBookingLoading;
                  
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: royalGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    ),
                    onPressed: isSubmitting ? null : () {
                      final passengerId = FirebaseAuth.instance.currentUser?.uid ?? '';
                      
                      // 🟢 توجيه أمر الحجز للكيوبيت المختص
                      context.read<TripBookingCubit>().bookSelectedTrip(
                        tripId: tripId, 
                        driverId: driverId, 
                        passengerId: passengerId,
                        requestedSeats: selectedSeats
                      );
                      
                      Navigator.pop(ctx); // نقفل الديالوج، والـ Listener هيطلع رسالة النجاح
                    },
                    child: isSubmitting 
                      ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('تأكيد الحجز', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
                  );
                }
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildTripsList(BuildContext context, List<ProcessedTrip> processedTrips, bool isLoading, bool isFetchingMore, Color royalGreen, Color accentGold, Color darkSlate) {
    if (isLoading && processedTrips.isEmpty) {
      return Center(child: CircularProgressIndicator(color: royalGreen));
    }

    if (processedTrips.isEmpty) {
      return ListView( 
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car_filled_rounded, size: 80.sp, color: Colors.grey.shade300),
                SizedBox(height: 16.h),
                Text('لا توجد رحلات متاحة حالياً', style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      itemCount: processedTrips.length + (isFetchingMore ? 1 : 0),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        
        if (index >= processedTrips.length) {
          return Padding(
            padding: EdgeInsets.all(16.w),
            child: Center(child: CircularProgressIndicator(color: royalGreen)),
          );
        }

        var processedTrip = processedTrips[index];
        TripEntity trip = processedTrip.trip;
        
        double dist = processedTrip.distance;
        String distanceText = dist != double.infinity ? 'يبعد: ${(dist / 1000).toStringAsFixed(1)} كم' : '';

        String driverName = (trip.driverName?.trim().isNotEmpty ?? false) ? trip.driverName! : 'كابتن لَمَّة';
        String price = trip.price ?? 'غير محدد';
        String pickup = trip.pickup ?? trip.fromCity ?? 'نقطة الانطلاق غير محددة';
        String dropoff = trip.destination ?? trip.toCity ?? 'نقطة الوصول غير محددة';
        int maxSeats = int.tryParse(trip.availableSeats ?? '0') ?? 0;
        
        String timeString = 'غير محدد';
        if (trip.travelDate != null) {
          timeString = DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(trip.travelDate!);
        }

        String tripDriverId = trip.driverId ?? '';

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
                      onPressed: null, 
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
                      onPressed: () => _showBookingDialog(context, trip.id ?? '', tripDriverId, maxSeats, royalGreen), 
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