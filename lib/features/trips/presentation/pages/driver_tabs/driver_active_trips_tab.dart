// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:lamma_new/l10n/app_localizations.dart';

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/di/injection_container.dart'; 
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';

import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_state.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_state.dart';
import 'package:lamma_new/features/trips/presentation/widgets/premium_tab_header.dart';

import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/widgets/driver_booking_request_card.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/widgets/driver_published_trip_card.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/widgets/driver_active_trip_card.dart';

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
    
    _scrollController.addListener(_onScroll);

    final String driverId = FirebaseAuth.instance.currentUser?.uid ?? '';
    context.read<DriverActiveTripsCubit>().startListeningToActiveTrips(driverId); 
    
    _bookingsStream = FirebaseFirestore.instance.collection('trip_bookings')
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: ['pending', 'accepted'])
        .snapshots();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      context.read<DriverActiveTripsCubit>().fetchMoreActiveTrips();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) => sl<TripActionsCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight, 
        body: Stack(
          children: [
            Column(
              children: [
                if (widget.showHeader)
                  PremiumTabHeader(title: l10n.activeTripsTabTitle),
                
                Expanded(
                  child: MultiBlocListener(
                    listeners: [
                      BlocListener<TripActionsCubit, TripActionsState>(
                        listener: (context, state) {
                          if (state is TripActionsSuccess) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.success));
                          } else if (state is TripActionsError) {
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
                          final List<TripEntity> trips = state.trips; 

                          return RefreshIndicator(
                            color: AppColors.accentGold,
                            backgroundColor: AppColors.cardWhite,
                            onRefresh: () async {
                              await context.read<DriverActiveTripsCubit>().fetchInitialActiveTrips();
                            },
                            child: SingleChildScrollView(
                              controller: _scrollController,
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
                                              child: Text(l10n.travelBookingRequests, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.accentGold)),
                                            ),
                                            ListView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                                              itemCount: snapshot.data!.docs.length,
                                              itemBuilder: (context, index) {
                                                var booking = snapshot.data!.docs[index];
                                                return DriverBookingRequestCard(booking: booking);
                                              },
                                            ),
                                            Padding(padding: EdgeInsets.symmetric(horizontal: 16.w), child: const Divider(thickness: 1.5, color: AppColors.dividerColor)),
                                          ],
                                        );
                                      },
                                    ),

                                    if (trips.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h, bottom: 4.h),
                                        child: Text(l10n.yourCurrentTrips, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.royalGreen)),
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
                                              Text(l10n.noActiveTripsCurrently, style: TextStyle(fontFamily: 'Cairo', fontSize: 18.sp, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
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
                                          
                                          if (index >= trips.length) {
                                            return Padding(
                                              padding: EdgeInsets.symmetric(vertical: 16.h),
                                              child: const Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
                                            );
                                          }

                                          TripEntity trip = trips[index];
                                          String status = trip.status.value;
                                          bool isDriverPost = trip.isDriverPost == true;
                                          bool isAvailable = status == 'available';

                                          if (isDriverPost && isAvailable) {
                                            return DriverPublishedTripCard(trip: trip);
                                          }

                                          return DriverActiveTripCard(trip: trip);
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
            
            BlocBuilder<TripActionsCubit, TripActionsState>(
              builder: (context, state) {
                if (state is TripActionsLoading) {
                  return Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.accentGold),
                    ),
                  );
                }
                return const SizedBox.shrink(); 
              },
            ),
          ],
        ),
      ),
    );
  }
}