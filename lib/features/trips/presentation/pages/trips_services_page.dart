// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:rxdart/rxdart.dart';

import 'package:lamma_new/core/di/injection_container.dart';
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/utils/passenger_utils.dart'; // 🟢 استيراد امتداد اللغة

import 'package:lamma_new/features/trips/cubit/passenger/passenger_my_requests_cubit.dart';
import 'package:lamma_new/features/trips/cubit/passenger/available_travels_cubit.dart';
import 'package:lamma_new/features/trips/cubit/passenger/available_travels_state.dart';
import 'package:lamma_new/features/trips/cubit/passenger/trip_booking_cubit.dart';
import 'package:lamma_new/features/trips/cubit/passenger/trip_booking_state.dart';

import 'package:lamma_new/features/trips/presentation/pages/passenger_tabs/passenger_request_tab.dart';
import 'package:lamma_new/features/trips/presentation/pages/passenger_tabs/passenger_my_requests_tab.dart';
import 'package:lamma_new/features/trips/trip_injection.dart';

class TripsServicesPage extends StatefulWidget {
  const TripsServicesPage({super.key});

  @override
  State<TripsServicesPage> createState() => _TripsServicesPageState();
}

class _TripsServicesPageState extends State<TripsServicesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final PassengerRealtimeService _realtimeService = PassengerRealtimeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              sl<AvailableTravelsCubit>()..init(_currentUserId),
        ),
        BlocProvider(
          create: (context) => sl<TripBookingCubit>(),
        ),
        BlocProvider(
          create: (context) => sl<PassengerMyRequestsCubit>(),
        ),
      ],
      child: BlocListener<TripBookingCubit, TripBookingState>(
        listener: (context, state) {
          if (state is TripBookingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: AppColors.primaryNavy,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _tabController.animateTo(2);
          } else if (state is TripBookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message,
                      style: const TextStyle(fontFamily: 'Cairo')),
                  backgroundColor: Colors.red),
            );
          }
        },
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor, // 🟢 دعم الثيم الليلي
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: AppColors.primaryNavy, // 🔵 الكحلي الموحد
              elevation: 0,
              centerTitle: true,
              title: Text(l10n.deliveryAndTrips, // 🟢 من ملف الترجمة
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24.sp,
                      color: Colors.white)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.home_rounded,
                      color: AppColors.accentGold, size: 26),
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                ),
                SizedBox(width: 8.w),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(70.h),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Container(
                    width: double.infinity,
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy,
                      borderRadius: BorderRadius.circular(25.r),
                      border: Border.all(
                          color: AppColors.accentGold.withValues(alpha: 0.5),
                          width: 1),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: false,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: BorderRadius.circular(25.r),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ],
                      ),
                      labelColor: AppColors.primaryNavy,
                      unselectedLabelColor: Colors.white.withValues(alpha: 0.9),
                      labelStyle: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13.sp),
                      labelPadding: EdgeInsets.zero,
                      tabs: [
                        Tab(text: l10n.requestDriverService), // 🟢 ترجمة
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(l10n.tripForm_travelName), // 🟢 ترجمة
                              StreamBuilder<int>(
                                stream: _realtimeService
                                    .getAvailableTravelTripsCountStream(
                                        _currentUserId),
                                builder: (context, snapshot) {
                                  int count = snapshot.data ?? 0;
                                  if (count > 0) {
                                    return Padding(
                                      padding: EdgeInsets.only(right: 6.w),
                                      child: Badge(
                                          label: Text(count.toString(),
                                              style:
                                                  TextStyle(fontSize: 10.sp)),
                                          backgroundColor: Colors.redAccent),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(l10n.activeOrdersTitle), // 🟢 ترجمة
                              StreamBuilder<int>(
                                stream: _realtimeService
                                    .getActiveRequestsCountStream(
                                        _currentUserId),
                                builder: (context, snapshot) {
                                  int activeCount = snapshot.data ?? 0;
                                  if (activeCount > 0) {
                                    return Padding(
                                      padding: EdgeInsets.only(right: 6.w),
                                      child: Badge(
                                          label: Text(activeCount.toString(),
                                              style:
                                                  TextStyle(fontSize: 10.sp)),
                                          backgroundColor: Colors.redAccent),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                PassengerRequestTab(tabController: _tabController),
                PassengerTravelTripsTab(tabController: _tabController),
                const PassengerMyRequestsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PassengerTravelTripsTab extends StatefulWidget {
  final TabController tabController;

  const PassengerTravelTripsTab({super.key, required this.tabController});

  @override
  State<PassengerTravelTripsTab> createState() =>
      _PassengerTravelTripsTabState();
}

class _PassengerTravelTripsTabState extends State<PassengerTravelTripsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      context.read<AvailableTravelsCubit>().fetchMoreTrips();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.primaryNavy;

    return Container(
      color: Theme.of(context).colorScheme.surface, // 🟢 دعم الثيم الليلي
      child: BlocBuilder<AvailableTravelsCubit, AvailableTravelsState>(
        builder: (context, state) {
          if (state is AvailableTravelsLoading && state.trips.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accentGold));
          }

          if (state is AvailableTravelsError) {
            return Center(
                child: Text(state.message,
                    style: TextStyle(fontSize: 16.sp, color: Colors.red)));
          }

          if (state is AvailableTravelsLoaded) {
            if (state.trips.isEmpty) return _buildEmptyState(context);

            return ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              itemCount: state.trips.length + (state.isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.trips.length) {
                  return const Center(
                      child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                              color: AppColors.accentGold)));
                }

                var processedTrip = state.trips[index];
                var trip = processedTrip.trip;

                bool isMyOwnTrip = trip.driverId == currentUserId;
                bool isFullCar = trip.tripType == 'full_car';
                int availableSeats =
                    int.tryParse(trip.availableSeats?.toString() ?? '0') ?? 0;

                String travelTimeStr = l10n.notSpecified; // 🟢 ترجمة
                if (trip.travelDate != null) {
                  travelTimeStr = DateFormat('yyyy/MM/dd - hh:mm a', 'en')
                      .format(trip.travelDate!);
                }

                return Card(
                  elevation: 3,
                  margin: EdgeInsets.only(bottom: 16.h),
                  color: Theme.of(context).cardColor, // 🟢 لدعم الألوان الليلية
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: BorderSide(
                        color: AppColors.accentGold.withValues(alpha: 0.3), width: 1),
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
                                CircleAvatar(
                                  radius: 18.r,
                                  backgroundColor:
                                      AppColors.primaryNavy.withValues(alpha: 0.1),
                                  child: const Icon(Icons.person_pin,
                                      color: AppColors.primaryNavy, size: 20),
                                ),
                                SizedBox(width: 8.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(trip.driverName ?? l10n.lammaCaptain,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.sp,
                                            color: textColor)),
                                    Text('سائق موثوق', // لم أجدها في القاموس
                                        style: TextStyle(
                                            fontSize: 11.sp,
                                            color: Colors.green)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                  color: AppColors.accentGold.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20.r)),
                              child: Text(
                                  '${trip.price ?? trip.seatPrice ?? '0'} ${l10n.currencyEGP}', // 🟢 ترجمة
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                      color: textColor)),
                            ),
                          ],
                        ),
                        Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            child: Divider(thickness: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                        Row(
                          children: [
                            Column(
                              children: [
                                Icon(Icons.my_location_rounded,
                                    color: Colors.blueAccent, size: 18.sp),
                                Container(
                                    width: 2.w,
                                    height: 20.h,
                                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                Icon(Icons.location_on_rounded,
                                    color: Colors.redAccent, size: 18.sp),
                              ],
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(trip.pickup ?? trip.fromCity ?? '',
                                      style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: textColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  SizedBox(height: 12.h),
                                  Text(trip.destination ?? trip.toCity ?? '',
                                      style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: textColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time_filled_rounded,
                                    color: Colors.orange, size: 18.sp),
                                SizedBox(width: 8.w),
                                Text('التحرك: $travelTimeStr',
                                    style: TextStyle(
                                        fontSize: 13.sp,
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                  color: isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8.r)),
                              child: Text(
                                  isFullCar
                                      ? l10n.travel_fullCar // 🟢 ترجمة
                                      : l10n.availableSeats(availableSeats.toString()), // 🟢 ترجمة
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        isMyOwnTrip
                            ? Center(
                                child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 8.h, horizontal: 16.w),
                                decoration: BoxDecoration(
                                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10.r)),
                                child: Text('هذه رحلتك الخاصة (لا يمكنك حجزها)',
                                    style: TextStyle(
                                        fontSize: 13.sp,
                                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                                        fontWeight: FontWeight.bold)),
                              ))
                            : BlocBuilder<TripBookingCubit, TripBookingState>(
                                builder: (context, bookingState) {
                                  bool isLoading =
                                      bookingState is TripBookingLoading;
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 45.h,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryNavy,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.r)),
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : () {
                                              _showBookingDialog(
                                                  context,
                                                  trip.id ?? '',
                                                  trip.driverId ?? '',
                                                  trip.driverName ?? l10n.lammaCaptain,
                                                  isFullCar,
                                                  availableSeats);
                                            },
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                  color: AppColors.accentGold,
                                                  strokeWidth: 2))
                                          : Text(
                                              isFullCar
                                                  ? l10n.fullCarBookingRequest // 🟢 ترجمة
                                                  : l10n.bookAction, // 🟢 ترجمة
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14.sp,
                                                  color: AppColors.accentGold)),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_filled_outlined,
              size: 80.sp, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          SizedBox(height: 16.h),
          Text(l10n.noTripsAvailable, // 🟢 ترجمة
              style: TextStyle(
                  fontSize: 16.sp,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text('السائقين لسه منزلوش رحلات، جرب تدخل وقت تاني.',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context, String tripId, String driverId,
      String driverName, bool isFullCar, int maxSeats) {
    int requestedSeats = 1;
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (dialogContext, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.primaryNavy;

          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.r)),
            title: Text('تأكيد الحجز',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                    fontSize: 18.sp)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('هل تريد تأكيد الحجز مع الكابتن $driverName؟',
                    style: TextStyle(fontSize: 14.sp, color: textColor)),
                SizedBox(height: 16.h),
                if (!isFullCar) ...[
                  Text('حدد عدد المقاعد المطلوبة:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13.sp, color: textColor)),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.redAccent),
                        onPressed: () {
                          if (requestedSeats > 1) {
                            setState(() => requestedSeats--);
                          }
                        },
                      ),
                      Text('$requestedSeats',
                          style: TextStyle(
                              fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.green),
                        onPressed: () {
                          if (requestedSeats < maxSeats) {
                            setState(() => requestedSeats++);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    Text(l10n.cancel, style: const TextStyle(color: Colors.grey)), // 🟢 ترجمة
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<TripBookingCubit>().bookSelectedTrip(
                      tripId: tripId,
                      driverId: driverId,
                      passengerId: FirebaseAuth.instance.currentUser?.uid ?? '',
                      requestedSeats: isFullCar ? 1 : requestedSeats);
                },
                child: Text(l10n.sendBtn, // 🟢 ترجمة
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGold)),
              ),
            ],
          );
        });
      },
    );
  }
}

class PassengerRealtimeService {
  Stream<int> getAvailableTravelTripsCountStream(String currentUserId) {
    return FirebaseFirestore.instance
        .collection('trips')
        .where('isDriverPost', isEqualTo: true)
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        var data = doc.data() as Map<String, dynamic>? ?? {};
        String ownerId =
            data['userId'] ?? data['driverId'] ?? data['uid'] ?? '';
        bool isFullCar = data['tripType'] == 'full_car';
        int availableSeats =
            int.tryParse(data['availableSeats'].toString()) ?? 0;
        bool hasSeats = isFullCar || availableSeats > 0;
        return ownerId != currentUserId && hasSeats;
      }).length;
    });
  }

  Stream<int> getActiveRequestsCountStream(String currentUserId) {
    Stream<QuerySnapshot> tripsStream = FirebaseFirestore.instance
        .collection('trips')
        .where('passengerId', isEqualTo: currentUserId)
        .where('isDriverPost', isEqualTo: false)
        .snapshots();

    Stream<QuerySnapshot> bookingsStream = FirebaseFirestore.instance
        .collection('trip_bookings')
        .where('passengerId', isEqualTo: currentUserId)
        .where('status', whereIn: ['pending', 'accepted']).snapshots();

    return Rx.combineLatest2(tripsStream, bookingsStream,
        (QuerySnapshot trips, QuerySnapshot bookings) {
      int validTrips = 0;
      for (var doc in trips.docs) {
        final data = (doc.data() as Map<String, dynamic>?) ?? {};
        bool isDeleted =
            data['isDeletedForPassenger'] == true || data['isDeleted'] == true;
        String status = data['status'] ?? '';
        bool isFinished = status == 'canceled' || status == 'completed';
        if (!isDeleted && !isFinished) validTrips++;
      }
      return validTrips + bookings.docs.length;
    });
  }
}