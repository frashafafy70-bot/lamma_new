// ignore_for_file: use_build_context_synchronously

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🟢 المسار الصحيح لملف الترجمة الفعلي الموجود في مشروعك
import '../../../../l10n/app_localizations.dart';

// 🟢 المسار الصحيح لملف الألوان
import '../../../../core/theme/app_colors.dart';

// 🟢 المسارات الصحيحة للكيوبت كما كانت في كودك الأصلي
import '../../cubit/passenger/trip_search_cubit.dart';
import '../../cubit/passenger/trip_search_state.dart';
import '../../cubit/passenger/trip_booking_cubit.dart';
import '../../cubit/passenger/trip_booking_state.dart';

@RoutePage() 
class PassengerSearchPage extends StatefulWidget {
  const PassengerSearchPage({super.key});

  @override
  State<PassengerSearchPage> createState() => _PassengerSearchPageState();
}

class _PassengerSearchPageState extends State<PassengerSearchPage> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<TripBookingCubit, TripBookingState>(
      listener: (context, state) {
        if (state is TripBookingLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.bookingLoadingMsg, style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: AppColors.primaryDark,
              duration: const Duration(seconds: 1),
            ),
          );
        } else if (state is TripBookingSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is TripBookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryDark,
          title: Text(
            l10n.searchForTripTitle,
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18.sp, color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              TextField(
                controller: _fromController,
                decoration: InputDecoration(
                  labelText: l10n.fromCity,
                  labelStyle: const TextStyle(fontFamily: 'Cairo'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                  prefixIcon: const Icon(Icons.my_location, color: AppColors.primaryDark),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _toController,
                decoration: InputDecoration(
                  labelText: l10n.toCity,
                  labelStyle: const TextStyle(fontFamily: 'Cairo'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                  prefixIcon: const Icon(Icons.location_on, color: Colors.redAccent),
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                  onPressed: () {
                    final from = _fromController.text.trim();
                    final to = _toController.text.trim();
                    
                    if (from.isEmpty || to.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.enterCitiesWarning, style: const TextStyle(fontFamily: 'Cairo')),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    
                    context.read<TripSearchCubit>().searchForRides(from, to);
                  },
                  child: Text(
                    l10n.searchTripsButton,
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.accentGold),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: BlocBuilder<TripSearchCubit, TripSearchState>(
                  builder: (context, state) {
                    if (state is TripSearchLoading) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.accentGold));
                    } 
                    else if (state is TripSearchError) {
                      return Center(child: Text(state.message, style: TextStyle(fontFamily: 'Cairo', color: Colors.red, fontSize: 14.sp)));
                    } 
                    else if (state is TripSearchLoaded) {
                      final trips = state.trips;
                      if (trips.isEmpty) {
                        return Center(child: Text(l10n.noTripsAvailable, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey)));
                      }

                      return ListView.builder(
                        itemCount: trips.length,
                        itemBuilder: (context, index) {
                          final trip = trips[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            child: ListTile(
                              title: Text(l10n.tripRoute(trip.fromCity ?? '', trip.toCity ?? ''), style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                              subtitle: Text(l10n.tripDetailsSubtitle(trip.driverName ?? l10n.notSpecified, trip.price.toString()), style: const TextStyle(fontFamily: 'Cairo')),
                              trailing: StatefulBuilder(
                                builder: (context, setLocalState) {
                                  bool isPressed = false;
                                  return GestureDetector(
                                    onTapDown: (_) {
                                      HapticFeedback.lightImpact(); 
                                      setLocalState(() => isPressed = true);
                                    },
                                    onTapUp: (_) => setLocalState(() => isPressed = false),
                                    onTapCancel: () => setLocalState(() => isPressed = false),
                                    onTap: () {
                                      context.read<TripBookingCubit>().bookSelectedTrip(
                                        tripId: trip.id ?? '',
                                        driverId: trip.driverId ?? '',
                                        passengerId: FirebaseAuth.instance.currentUser?.uid ?? '',
                                        requestedSeats: 1,
                                      );
                                    },
                                    child: AnimatedScale(
                                      scale: isPressed ? 0.90 : 1.0, 
                                      duration: const Duration(milliseconds: 100),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryDark,
                                          elevation: isPressed ? 0 : 4,
                                        ),
                                        onPressed: null, 
                                        child: Text(
                                          l10n.bookAction,
                                          style: TextStyle(fontFamily: 'Cairo', color: AppColors.accentGold, fontSize: 12.sp),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    }
                    return Center(child: Text(l10n.searchPrompt, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey)));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}