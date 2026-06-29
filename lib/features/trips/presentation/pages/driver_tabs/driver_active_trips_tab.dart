// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lamma_new/core/theme/app_colors.dart';
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
      backgroundColor: AppColors.backgroundLight, 
      body: BlocBuilder<DriverActiveTripsCubit, DriverActiveTripsState>(
        builder: (context, state) {
          if (state is DriverActiveTripsLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentGold)); 
          }

          if (state is DriverActiveTripsError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, color: AppColors.error), 
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
                    Icon(Icons.local_taxi_rounded, size: 60, color: AppColors.textMuted.shade400), 
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد رحلات نشطة حالياً',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: AppColors.textMuted.shade600), 
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                var tripData = trips[index].data() as Map<String, dynamic>;
                String tripId = trips[index].id; 
                
                String destination = tripData['destination'] ?? 'موقع محدد من الخريطة';
                String finalPrice = tripData['finalPrice']?.toString() ?? '0';

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: AppColors.error, size: 24), 
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                destination,
                                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark), 
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on, color: AppColors.success, size: 24), 
                            const SizedBox(width: 8),
                            Text(
                              'السعر: $finalPrice جنيه',
                              style: const TextStyle(fontFamily: 'Cairo', color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 15), 
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(color: AppColors.dividerColor), 
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error, 
                                  side: const BorderSide(color: AppColors.error), 
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                icon: const Icon(Icons.cancel_outlined, size: 18),
                                label: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  TripDialogsHelper.showCancelTripDialog(
                                    context: context, 
                                    docId: tripId,
                                    isDriver: true, 
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDark, 
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                icon: const Icon(Icons.map_rounded, size: 18),
                                label: const Text('التفاصيل والخريطة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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