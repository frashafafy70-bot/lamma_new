// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:intl/intl.dart' hide TextDirection; 

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/extensions/context_extension.dart';
import 'package:lamma_new/core/di/injection_container.dart'; 

import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart'; 
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_trip_tracking_page.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_state.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_state.dart';
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';
import 'package:lamma_new/features/trips/data/models/trip_model.dart'; 
import 'package:lamma_new/features/trips/presentation/widgets/premium_tab_header.dart';

class DriverActiveTripsTab extends StatefulWidget {
  final bool showHeader;
  const DriverActiveTripsTab({super.key, this.showHeader = true});

  @override
  State<DriverActiveTripsTab> createState() => _DriverActiveTripsTabState();
}

class _DriverActiveTripsTabState extends State<DriverActiveTripsTab> with AutomaticKeepAliveClientMixin {
  
  late final Stream<QuerySnapshot> _bookingsStream;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true; 

  @override
  void initState() {
    super.initState();
    
    // ربط الكنترولر بمراقب النزول (Pagination)
    _scrollController.addListener(_onScroll);

    final String driverId = FirebaseAuth.instance.currentUser?.uid ?? '';
    context.read<DriverActiveTripsCubit>().startListeningToActiveTrips(driverId); 
    
    _bookingsStream = FirebaseFirestore.instance.collection('trip_bookings')
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: ['pending', 'accepted'])
        .snapshots();
  }

  void _onScroll() {
    // طلب رحلات جديدة عند الاقتراب من نهاية القائمة
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      context.read<DriverActiveTripsCubit>().fetchMoreActiveTrips();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showCancelBookingDialog(BuildContext context, DocumentSnapshot bookingDoc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text('إلغاء الحجز', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 18.sp)),
        content: Text('هل أنت متأكد من إلغاء هذا الحجز وإزالة الراكب؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('تراجع', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ctx.pop();
              var bookingData = bookingDoc.data() as Map<String, dynamic>;
              int seatsToReturn = bookingData['seats'] ?? 1;
              String tripId = bookingData['tripId'];
              String passengerId = bookingData['passengerId'];
              bool wasAccepted = bookingData['status'] == 'accepted';

              context.read<DriverActiveTripsCubit>().cancelBooking(bookingDoc.id, tripId, passengerId, seatsToReturn, wasAccepted);
            },
            child: const Text('نعم، إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 

    return BlocProvider(
      create: (context) => sl<TripActionsCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight, 
        body: Column(
          children: [
            if (widget.showHeader)
              const PremiumTabHeader(title: 'الرحلات النشطة'),
            
            Expanded(
              child: MultiBlocListener(
                listeners: [
                  BlocListener<TripActionsCubit, TripActionsState>(
                    listener: (context, state) {
                      if (state is TripActionsLoading) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
                        );
                      } else if (state is TripActionsSuccess) {
                        Navigator.of(context).pop(); 
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.success));
                      } else if (state is TripActionsError) {
                        Navigator.of(context).pop(); 
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.error));
                      }
                    },
                  ),
                ],
                child: BlocConsumer<DriverActiveTripsCubit, DriverActiveTripsState>(
                  listener: (context, state) {
                    if (state is DriverActiveTripsActionSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.success));
                    } else if (state is DriverActiveTripsActionError) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.error));
                    } else if (state is DriverActiveTripsPaginationError) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.warning));
                    }
                  },
                  buildWhen: (previous, current) => current is! DriverActiveTripsActionLoading && current is! DriverActiveTripsActionSuccess && current is! DriverActiveTripsActionError && current is! DriverActiveTripsPaginationError,
                  builder: (context, state) {
                    if (state is DriverActiveTripsLoading) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.accentGold)); 
                    }
                    if (state is DriverActiveTripsError) {
                      return Center(child: Text(state.message, style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: AppColors.error)));
                    }

                    if (state is DriverActiveTripsLoaded) {
                      final List<TripModel> trips = state.trips; 

                      // 🟢 تم إضافة RefreshIndicator مع التعديلات اللازمة
                      return RefreshIndicator(
                        color: AppColors.accentGold,
                        backgroundColor: Colors.white,
                        onRefresh: () async {
                          await context.read<DriverActiveTripsCubit>().fetchInitialActiveTrips();
                        },
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          // 🟢 تم ضبط الـ Physics لضمان عمل السحب للأسفل دائماً
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          child: Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StreamBuilder<QuerySnapshot>(
                                  stream: _bookingsStream,
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 8.h),
                                          child: Text('طلبات حجز السفر', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.accentGold)),
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
                                            
                                            String timeString = 'غير محدد';
                                            if (data['createdAt'] != null) {
                                              DateTime dt = (data['createdAt'] as Timestamp).toDate();
                                              timeString = DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(dt);
                                            }
                                            
                                            return Card(
                                              elevation: 3,
                                              margin: EdgeInsets.only(bottom: 16.h),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r), side: BorderSide(color: isPending ? AppColors.warning.withValues(alpha: 0.4) : AppColors.success.withValues(alpha: 0.4), width: 1.5)),
                                              child: Padding(
                                                padding: EdgeInsets.all(16.w),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        CircleAvatar(radius: 20.r, backgroundColor: isPending ? AppColors.warning.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1), child: Icon(Icons.event_seat_rounded, color: isPending ? AppColors.warning : AppColors.success, size: 22.sp)),
                                                        SizedBox(width: 12.w),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(data['seats'] == 1 && data['tripType'] == 'full_car' ? 'طلب حجز رحلة كاملة' : 'طلب حجز مقاعد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15.sp, color: AppColors.textDark)),
                                                              SizedBox(height: 4.h),
                                                              Text(isPending ? '⏳ قيد الانتظار - العميل يطلب ${data['seats']} مقاعد' : '✅ تم القبول - العميل حاجز ${data['seats']} مقاعد', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold, color: isPending ? AppColors.warning : AppColors.success)),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 12.h),
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8.r)),
                                                      child: Row(children: [Icon(Icons.access_time_filled_rounded, size: 16.sp, color: AppColors.textMuted), SizedBox(width: 8.w), Text('وقت الطلب: $timeString', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: AppColors.textDark, fontWeight: FontWeight.w600))]),
                                                    ),
                                                    Padding(padding: EdgeInsets.symmetric(vertical: 12.h), child: const Divider(height: 1)),
                                                    
                                                    if (isPending) ...[
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: ElevatedButton.icon(
                                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)), padding: EdgeInsets.symmetric(vertical: 10.h)),
                                                              icon: Icon(Icons.check_circle_rounded, size: 18.sp, color: Colors.white),
                                                              label: Text('قبول', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                                                              onPressed: () {
                                                                int seatsToDeduct = data['seats'] ?? 1;
                                                                String tripId = data['tripId'];
                                                                context.read<DriverActiveTripsCubit>().acceptBooking(booking.id, tripId, seatsToDeduct);
                                                              },
                                                            ),
                                                          ),
                                                          SizedBox(width: 10.w),
                                                          Expanded(
                                                            child: OutlinedButton.icon(
                                                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)), padding: EdgeInsets.symmetric(vertical: 10.h)),
                                                              icon: Icon(Icons.close_rounded, size: 18.sp),
                                                              label: Text('رفض', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold)),
                                                              onPressed: () {
                                                                String tripId = data['tripId'];
                                                                String passengerId = data['passengerId'];
                                                                context.read<DriverActiveTripsCubit>().rejectBooking(booking.id, tripId, passengerId);
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    ] else ...[
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: ElevatedButton.icon(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: AppColors.primaryDark,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                                            padding: EdgeInsets.symmetric(vertical: 10.h)
                                                          ),
                                                          icon: Icon(Icons.chat_bubble_rounded, size: 18.sp, color: Colors.white),
                                                          label: Text('مراسلة العميل', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                                                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: data['tripId']))),
                                                        ),
                                                      ),
                                                      SizedBox(height: 10.h),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: OutlinedButton.icon(
                                                              style: OutlinedButton.styleFrom(
                                                                foregroundColor: AppColors.royalGreen,
                                                                side: const BorderSide(color: AppColors.royalGreen),
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                                                padding: EdgeInsets.symmetric(vertical: 10.h)
                                                              ),
                                                              icon: Icon(Icons.edit_note_rounded, size: 18.sp),
                                                              label: Text('تعديل', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold)),
                                                              onPressed: () async {
                                                                final result = await TripDialogsHelper.showEditBookingDialog(
                                                                  context: context,
                                                                  currentSeats: data['seats'] ?? 1,
                                                                  royalGreen: AppColors.royalGreen,
                                                                );
                                                                if (result != null) {
                                                                  context.read<TripActionsCubit>().updateBookingSeats(
                                                                    bookingId: booking.id,
                                                                    newSeats: result['seats'],
                                                                    travelDate: result['date'],
                                                                  );
                                                                }
                                                              }
                                                            ),
                                                          ),
                                                          SizedBox(width: 10.w),
                                                          Expanded(
                                                            child: OutlinedButton.icon(
                                                              style: OutlinedButton.styleFrom(
                                                                foregroundColor: AppColors.error,
                                                                side: const BorderSide(color: AppColors.error),
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                                                padding: EdgeInsets.symmetric(vertical: 10.h)
                                                              ),
                                                              icon: Icon(Icons.delete_outline_rounded, size: 18.sp),
                                                              label: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold)),
                                                              onPressed: () => _showCancelBookingDialog(context, booking),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ]
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        Padding(padding: EdgeInsets.symmetric(horizontal: 16.w), child: const Divider(thickness: 1.5)),
                                      ],
                                    );
                                  },
                                ),

                                if (trips.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h, bottom: 4.h),
                                    child: Text('رحلاتك الحالية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.royalGreen)),
                                  ),

                                if (trips.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: 100.h),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.local_taxi_rounded, size: 80.sp, color: AppColors.textMuted.withValues(alpha: 0.5)), 
                                          SizedBox(height: 16.h),
                                          Text('لا توجد رحلات نشطة حالياً', style: TextStyle(fontFamily: 'Cairo', fontSize: 18.sp, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true, 
                                    physics: const NeverScrollableScrollPhysics(), 
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                    itemCount: trips.length + (state.isFetchingMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      
                                      // عرض مؤشر التحميل في نهاية القائمة
                                      if (index >= trips.length) {
                                        return Padding(
                                          padding: EdgeInsets.symmetric(vertical: 16.h),
                                          child: const Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
                                        );
                                      }

                                      TripModel trip = trips[index];
                                      String tripId = trip.id ?? ''; 
                                      String status = trip.status ?? 'pending';
                                      bool isDriverPost = trip.isDriverPost == true;
                                      bool isAvailable = status == 'available';

                                      if (isDriverPost && isAvailable) {
                                        String pickup = trip.pickup ?? 'موقع الانطلاق';
                                        String dropoff = trip.destination ?? 'وجهة الوصول';
                                        String price = trip.price ?? '0';
                                        
                                        int seatsNum = int.tryParse(trip.availableSeats?.toString() ?? '0') ?? 0;
                                        
                                        String seatsDisplay = seatsNum <= 0 ? 'مكتمل 🔴' : 'متاح $seatsNum مقاعد';
                                        Color seatsBgColor = seatsNum <= 0 ? AppColors.error.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1);
                                        Color seatsTextColor = seatsNum <= 0 ? AppColors.error : Colors.blue.shade800;

                                        String timeString = 'غير محدد';
                                        if (trip.travelDate != null) {
                                          timeString = DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(trip.travelDate!);
                                        }

                                        return Card(
                                          elevation: 4,
                                          margin: EdgeInsets.only(bottom: 16.h),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r), side: BorderSide(color: AppColors.accentGold.withValues(alpha: 0.6), width: 1.5)),
                                          child: Padding(
                                            padding: EdgeInsets.all(16.w),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                                      decoration: BoxDecoration(color: AppColors.royalGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
                                                      child: Row(children: [Icon(Icons.radar, color: AppColors.royalGreen, size: 16.sp), SizedBox(width: 6.w), Text('جاري البحث عن ركاب', style: TextStyle(fontFamily: 'Cairo', color: AppColors.royalGreen, fontWeight: FontWeight.bold, fontSize: 12.sp))]),
                                                    ),
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                                      decoration: BoxDecoration(color: seatsBgColor, borderRadius: BorderRadius.circular(8.r)),
                                                      child: Text(seatsDisplay, style: TextStyle(fontFamily: 'Cairo', color: seatsTextColor, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 16.h),
                                                Row(
                                                  children: [
                                                    Column(children: [Icon(Icons.my_location_rounded, color: AppColors.royalGreen, size: 18.sp), Container(height: 25.h, width: 2.w, color: AppColors.dividerColor), Icon(Icons.location_on_rounded, color: AppColors.error, size: 18.sp)]),
                                                    SizedBox(width: 12.w),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(pickup, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                          SizedBox(height: 20.h),
                                                          Text(dropoff, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                                                      Row(children: [Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 16.sp), SizedBox(width: 6.w), Text(timeString, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: AppColors.textDark, fontWeight: FontWeight.w600))]),
                                                      Text('$price ج.م', style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp, color: AppColors.success, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 16.h),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton.icon(
                                                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.royalGreen, side: BorderSide(color: AppColors.royalGreen.withValues(alpha: 0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)), padding: EdgeInsets.symmetric(vertical: 10.h)),
                                                        icon: Icon(Icons.edit_calendar_rounded, size: 18.sp),
                                                        label: Text('تعديل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                                        onPressed: () async {
                                                          final result = await TripDialogsHelper.showEditPublishedTripDialog(
                                                            context: context, 
                                                            currentPrice: price, 
                                                            currentTravelDate: trip.travelDate, 
                                                            royalGreen: AppColors.royalGreen
                                                          );
                                                          if (result != null) {
                                                            // context.read<TripActionsCubit>().editPublishedTrip(...)
                                                          }
                                                        }
                                                      ),
                                                    ),
                                                    SizedBox(width: 10.w),
                                                    Expanded(
                                                      child: OutlinedButton.icon(
                                                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)), padding: EdgeInsets.symmetric(vertical: 10.h)),
                                                        icon: Icon(Icons.cancel_outlined, size: 18.sp),
                                                        label: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                                        onPressed: () async {
                                                          final confirm = await TripDialogsHelper.showCancelTripDialog(context: context);
                                                          if (confirm) {
                                                            context.read<TripActionsCubit>().cancelTripFully(tripId: tripId, isDriver: true);
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      String destination = trip.destination ?? 'موقع محدد من الخريطة';
                                      String finalPrice = trip.finalPrice ?? trip.negotiationPrice ?? trip.price ?? '0';
                                      bool isNegotiating = status == 'negotiating';
                                      bool isDriverTurn = isNegotiating && trip.lastNegotiator == 'passenger';

                                      return Container(
                                        margin: EdgeInsets.only(bottom: 16.h),
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: AppColors.dividerColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                                        child: Padding(
                                          padding: EdgeInsets.all(16.w),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (isNegotiating) ...[
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                                  decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
                                                  child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.handshake_rounded, color: AppColors.warning, size: 16.sp), SizedBox(width: 8.w), Text(isDriverTurn ? 'العميل يقترح سعراً جديداً' : 'في انتظار رد العميل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: AppColors.warning, fontWeight: FontWeight.bold))]),
                                                ),
                                                SizedBox(height: 12.h),
                                              ],
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  CircleAvatar(radius: 16.r, backgroundColor: AppColors.error.withValues(alpha: 0.1), child: Icon(Icons.location_on_rounded, color: AppColors.error, size: 18.sp)), 
                                                  SizedBox(width: 12.w),
                                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('وجهة الوصول', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: AppColors.textMuted)), Text(destination, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15.sp, color: AppColors.textDark), maxLines: 2, overflow: TextOverflow.ellipsis)])),
                                                ],
                                              ),
                                              SizedBox(height: 12.h),
                                              Row(
                                                children: [
                                                  CircleAvatar(radius: 16.r, backgroundColor: AppColors.success.withValues(alpha: 0.1), child: Icon(Icons.monetization_on_rounded, color: AppColors.success, size: 18.sp)), 
                                                  SizedBox(width: 12.w),
                                                  Text(isNegotiating ? 'السعر المقترح: $finalPrice ج.م' : 'السعر النهائي: $finalPrice ج.م', style: TextStyle(fontFamily: 'Cairo', color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 15.sp)),
                                                ],
                                              ),
                                              Padding(padding: EdgeInsets.symmetric(vertical: 12.h), child: const Divider(color: AppColors.dividerColor)), 
                                              if (isDriverTurn) ...[
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)), padding: EdgeInsets.symmetric(vertical: 10.h), elevation: 0),
                                                        icon: Icon(Icons.check_circle_rounded, size: 18.sp),
                                                        label: Text('موافق بالسعر', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                                        onPressed: () async {
                                                          try {
                                                            await FirebaseFirestore.instance.collection('trips').doc(tripId).update({'status': 'accepted', 'finalPrice': trip.negotiationPrice, 'acceptedAt': FieldValue.serverTimestamp()});
                                                          } catch (e) {
                                                            debugPrint('Error accepting trip: $e');
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                    SizedBox(width: 8.w),
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)), padding: EdgeInsets.symmetric(vertical: 10.h), elevation: 0),
                                                        icon: Icon(Icons.handshake_rounded, size: 18.sp),
                                                        label: Text('تفاوض', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                                        onPressed: () async {
                                                          final offer = await TripDialogsHelper.showNegotiationDialog(
                                                            context: context, 
                                                            royalGreen: AppColors.royalGreen,
                                                          );
                                                          if (offer != null) {
                                                            context.read<TripActionsCubit>().submitNegotiationOffer(
                                                              docId: tripId,
                                                              offerPrice: offer,
                                                              isDriver: true,
                                                            );
                                                          }
                                                        }
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
                                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalGreen, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 12.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
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
                                                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)), padding: EdgeInsets.symmetric(vertical: 10.h)),
                                                      icon: Icon(Icons.cancel_outlined, size: 18.sp),
                                                      label: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                                      onPressed: () async {
                                                        final confirm = await TripDialogsHelper.showCancelTripDialog(context: context);
                                                        if (confirm) {
                                                          context.read<TripActionsCubit>().cancelTripFully(tripId: tripId, isDriver: true);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  SizedBox(width: 12.w),
                                                  Expanded(
                                                    flex: 2,
                                                    child: ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)), padding: EdgeInsets.symmetric(vertical: 10.h)),
                                                      icon: Icon(Icons.map_rounded, size: 18.sp),
                                                      label: Text('التفاصيل والخريطة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DriverTripTrackingPage(tripId: tripId))),
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
                                SizedBox(height: 120.h),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
