import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lamma_new/l10n/app_localizations.dart';

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart';
import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart';

class DriverPublishedTripCard extends StatelessWidget {
  final TripEntity trip;

  const DriverPublishedTripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    String tripId = trip.id ?? '';
    String pickup = trip.pickup ?? l10n.pickupLocationDefault;
    String dropoff = trip.destination ?? l10n.dropoffLocationDefault;
    String price = trip.price?.toString() ?? '0';

    int seatsNum = int.tryParse(trip.availableSeats?.toString() ?? '0') ?? 0;

    String seatsDisplay = seatsNum <= 0 ? l10n.fullSeats : l10n.availableSeats(seatsNum.toString());
    Color seatsBgColor = seatsNum <= 0
        ? AppColors.error.withValues(alpha: 0.1)
        : AppColors.info.withValues(alpha: 0.1);
    Color seatsTextColor = seatsNum <= 0 ? AppColors.error : AppColors.info.shade800;

    String timeString = l10n.unspecified;
    if (trip.travelDate != null) {
      timeString = DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(trip.travelDate!);
    }

    return Card(
      elevation: 0,
      color: AppColors.cardWhite,
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: AppColors.accentGold.withValues(alpha: 0.6), width: 1.5)),
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
                  decoration: BoxDecoration(
                      color: AppColors.royalGreenLight,
                      borderRadius: BorderRadius.circular(8.r)),
                  child: Row(children: [
                    Icon(Icons.radar, color: AppColors.royalGreen, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text(l10n.searchingForPassengers,
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.royalGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp))
                  ]),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(color: seatsBgColor, borderRadius: BorderRadius.circular(8.r)),
                  child: Text(seatsDisplay,
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          color: seatsTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp)),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Column(children: [
                  Icon(Icons.my_location_rounded, color: AppColors.royalGreen, size: 18.sp),
                  Container(height: 25.h, width: 2.w, color: AppColors.dividerColor),
                  Icon(Icons.location_on_rounded, color: AppColors.error, size: 18.sp)
                ]),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pickup,
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      SizedBox(height: 20.h),
                      Text(dropoff,
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(10.r)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text(timeString,
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.sp,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600))
                  ]),
                  Text(l10n.priceWithCurrency(price),
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15.sp,
                          color: AppColors.success,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.royalGreen,
                          side: BorderSide(color: AppColors.royalGreen.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          padding: EdgeInsets.symmetric(vertical: 10.h)),
                      icon: Icon(Icons.edit_calendar_rounded, size: 18.sp),
                      label: Text(l10n.edit,
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                      onPressed: () async {
                        final result = await TripDialogsHelper.showEditPublishedTripDialog(
                            context: context,
                            currentPrice: price,
                            currentTravelDate: trip.travelDate,
                            royalGreen: AppColors.royalGreen);
                        if (result != null) {
                          // TODO: Call Cubit logic
                        }
                      }),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(vertical: 10.h)),
                    icon: Icon(Icons.cancel_outlined, size: 18.sp),
                    label: Text(l10n.cancel,
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                    onPressed: () async {
                      final confirm = await TripDialogsHelper.showCancelTripDialog(context: context);
                      if (confirm && context.mounted) {
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
}