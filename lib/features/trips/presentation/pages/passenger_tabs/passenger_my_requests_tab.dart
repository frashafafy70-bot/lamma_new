// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/di/injection_container.dart'; // 🟢
import 'package:lamma_new/features/trips/cubit/passenger/passenger_my_requests_cubit.dart';
import 'package:lamma_new/features/trips/cubit/passenger/passenger_my_requests_state.dart';
import 'package:lamma_new/features/trips/presentation/widgets/my_request_trip_card.dart';
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';

import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart';
import 'package:lamma_new/features/trips/data/models/trip_model.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart'; // 🟢 تم إضافة الـ Entity هنا

// 🟢
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_state.dart';

class PassengerMyRequestsTab extends StatefulWidget {
  const PassengerMyRequestsTab({super.key});

  @override
  State<PassengerMyRequestsTab> createState() => _PassengerMyRequestsTabState();
}

class _PassengerMyRequestsTabState extends State<PassengerMyRequestsTab>
    with AutomaticKeepAliveClientMixin {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Set<String> _navigatedTripIds = {};
  final Set<String> _completedTripIds = {};

  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      if (mounted)
        context.read<PassengerMyRequestsCubit>().startListeningToMyRequests();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= (maxScroll - 200)) {
      context.read<PassengerMyRequestsCubit>().fetchMorePassengerTrips();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _showCancelBookingDialog(
      BuildContext context, DocumentReference bookingRef) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text('إلغاء الحجز',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 18.sp)),
        content: Text('هل أنت متأكد من إلغاء طلب الحجز؟',
            style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تراجع', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await bookingRef.delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('تم إلغاء الحجز بنجاح',
                        style: TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: Colors.red));
              }
            },
            child: const Text('نعم، إلغاء',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final Color primaryNavy = const Color(0xFF0F172A);

    return BlocProvider(
      create: (context) => sl<TripActionsCubit>(), // 🟢 توفير الكيوبت
      child: Container(
        color: AppColors.backgroundLight,
        // 🟢 الاستماع للأكشنز لعرض التحميل والنجاح للتقييم
        child: MultiBlocListener(
          listeners: [
            BlocListener<TripActionsCubit, TripActionsState>(
              listener: (context, state) {
                if (state is TripActionsLoading) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.royalGreen)),
                  );
                } else if (state is TripActionsSuccess) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.message,
                          style: const TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: AppColors.success));
                } else if (state is TripActionsError) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.message,
                          style: const TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: AppColors.error));
                }
              },
            ),
            BlocListener<PassengerMyRequestsCubit, PassengerMyRequestsState>(
              listener: (context, state) async {
                if (state is PassengerMyRequestsLoaded) {
                  for (TripEntity trip in state.requests) {
                    final tripId = trip.id ?? '';
                    final status = trip.status;

                    if (status == 'accepted' &&
                        !_navigatedTripIds.contains(tripId)) {
                      _navigatedTripIds.add(tripId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TripChatPage(tripId: tripId)),
                      );
                    }

                    if (status == 'completed' &&
                        !_completedTripIds.contains(tripId)) {
                      _completedTripIds.add(tripId);

                      final doc = await FirebaseFirestore.instance
                          .collection('trips')
                          .doc(tripId)
                          .get();
                      if (doc.exists &&
                          doc.data()?['passengerRatingForDriver'] == null) {
                        if (context.mounted) {
                          // 🟢 استدعاء الهيلبر النظيف ثم تمرير النتيجة للكيوبت
                          final stars =
                              await TripDialogsHelper.showRatingDialog(
                            context: context,
                            royalGreen: AppColors.royalGreen,
                          );
                          if (stars != null && context.mounted) {
                            context.read<TripActionsCubit>().submitRating(
                                  tripId: tripId,
                                  rating: stars.toDouble(),
                                  comment:
                                      '', // يمكن تعديل الديالوج مستقبلاً لإرجاع تعليق أيضاً
                                );
                          }
                        }
                      }
                    }
                  }
                }
              },
            ),
          ],
          child:
              BlocBuilder<PassengerMyRequestsCubit, PassengerMyRequestsState>(
            builder: (context, state) {
              if (state is PassengerMyRequestsLoading ||
                  state is PassengerMyRequestsInitial) {
                return const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.royalGreen));
              }

              if (state is PassengerMyRequestsError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 60.sp),
                      SizedBox(height: 16.h),
                      Text(state.message,
                          style: TextStyle(
                              fontSize: 16.sp, color: AppColors.textDark)),
                      SizedBox(height: 16.h),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.royalGreen,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r))),
                        onPressed: () => context
                            .read<PassengerMyRequestsCubit>()
                            .startListeningToMyRequests(),
                        icon: Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 20.sp),
                        label: Text('إعادة المحاولة',
                            style: TextStyle(
                                color: Colors.white, fontSize: 14.sp)),
                      )
                    ],
                  ),
                );
              }

              if (state is PassengerMyRequestsLoaded) {
                final requests = state.requests;

                return RefreshIndicator(
                  color: AppColors.royalGreen,
                  onRefresh: () async {
                    await context
                        .read<PassengerMyRequestsCubit>()
                        .fetchInitialPassengerTrips();
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('trip_bookings')
                              .where('passengerId', isEqualTo: currentUserId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty)
                              return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                      left: 16.w,
                                      right: 16.w,
                                      top: 16.h,
                                      bottom: 8.h),
                                  child: Text('حجوزات السفر الخاصة بي',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.sp,
                                          color: AppColors.royalGreen)),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.w),
                                  itemCount: snapshot.data!.docs.length,
                                  itemBuilder: (context, index) {
                                    var booking = snapshot.data!.docs[index];
                                    var data =
                                        booking.data() as Map<String, dynamic>;
                                    bool isAccepted =
                                        data['status'] == 'accepted';

                                    String timeString = 'غير محدد';
                                    if (data['createdAt'] != null) {
                                      DateTime dt =
                                          (data['createdAt'] as Timestamp)
                                              .toDate();
                                      timeString = DateFormat(
                                              'yyyy/MM/dd - hh:mm a', 'en')
                                          .format(dt);
                                    }

                                    return Card(
                                      elevation: 3,
                                      margin: EdgeInsets.only(bottom: 16.h),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16.r),
                                          side: BorderSide(
                                              color: isAccepted
                                                  ? Colors.green
                                                      .withValues(alpha: 0.4)
                                                  : Colors.orange
                                                      .withValues(alpha: 0.4),
                                              width: 1.5)),
                                      child: Padding(
                                        padding: EdgeInsets.all(16.w),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                    radius: 20.r,
                                                    backgroundColor: isAccepted
                                                        ? Colors.green.shade50
                                                        : Colors.orange.shade50,
                                                    child: Icon(
                                                        Icons
                                                            .directions_bus_filled_rounded,
                                                        color: isAccepted
                                                            ? Colors.green
                                                            : Colors.orange,
                                                        size: 22.sp)),
                                                SizedBox(width: 12.w),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          data['seats'] == 1 &&
                                                                  data['tripType'] ==
                                                                      'full_car'
                                                              ? 'حجز رحلة كاملة'
                                                              : 'حجز مقاعد سفر',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 15.sp,
                                                              color:
                                                                  primaryNavy)),
                                                      SizedBox(height: 4.h),
                                                      Text(
                                                          isAccepted
                                                              ? '✅ تم القبول - حجزت ${data['seats']} مقاعد'
                                                              : '⏳ قيد الانتظار - طلبت ${data['seats']} مقاعد',
                                                          style: TextStyle(
                                                              fontSize: 12.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: isAccepted
                                                                  ? Colors.green
                                                                      .shade700
                                                                  : Colors
                                                                      .orange
                                                                      .shade700)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 12.h),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12.w,
                                                  vertical: 8.h),
                                              decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.r)),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .access_time_filled_rounded,
                                                      size: 16.sp,
                                                      color:
                                                          Colors.grey.shade500),
                                                  SizedBox(width: 8.w),
                                                  Text('وقت الطلب: $timeString',
                                                      style: TextStyle(
                                                          fontSize: 12.sp,
                                                          color: Colors
                                                              .grey.shade700,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 12.h),
                                                child:
                                                    const Divider(height: 1)),
                                            Row(
                                              children: [
                                                if (isAccepted) ...[
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              primaryNavy,
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(10
                                                                          .r)),
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  vertical:
                                                                      10.h)),
                                                      icon: Icon(
                                                          Icons
                                                              .chat_bubble_rounded,
                                                          size: 18.sp,
                                                          color: Colors.white),
                                                      label: Text(
                                                          'مراسلة السائق',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 13.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      onPressed: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (_) =>
                                                                    TripChatPage(
                                                                        tripId:
                                                                            data['tripId'])));
                                                      },
                                                    ),
                                                  ),
                                                  SizedBox(width: 10.w),
                                                ],
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    style: OutlinedButton.styleFrom(
                                                        foregroundColor:
                                                            Colors.redAccent,
                                                        side: BorderSide(
                                                            color: Colors
                                                                .redAccent
                                                                .shade200),
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10.r)),
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                vertical:
                                                                    10.h)),
                                                    icon: Icon(
                                                        Icons
                                                            .delete_outline_rounded,
                                                        size: 18.sp),
                                                    label: Text('إلغاء الحجز',
                                                        style: TextStyle(
                                                            fontSize: 13.sp,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    onPressed: () =>
                                                        _showCancelBookingDialog(
                                                            context,
                                                            booking.reference),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.w),
                                  child: const Divider(thickness: 1.5),
                                ),
                              ],
                            );
                          },
                        ),
                        if (requests.isEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 100.h),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_rounded,
                                      color: AppColors.textMuted.shade300,
                                      size: 80.sp),
                                  SizedBox(height: 16.h),
                                  Text('لا توجد طلبات نشطة حالياً',
                                      style: TextStyle(
                                          fontSize: 18.sp,
                                          color: AppColors.textMuted.shade600,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 16.h),
                            itemCount: requests.length,
                            itemBuilder: (context, index) {
                              final trip = requests[index];

                              // 🟢 التحويل هنا بيتم بشكل سليم
                              Map<String, dynamic> tripDataMap =
                                  (trip as TripModel).toMap();
                              tripDataMap['id'] = trip.id;

                              return MyRequestTripCard(
                                docId: trip.id ?? '',
                                data: tripDataMap,
                                royalGreen: AppColors.royalGreen,
                              );
                            },
                          ),
                        if (state.isFetchingMore)
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.royalGreen),
                            ),
                          ),
                        SizedBox(height: 100.h),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
