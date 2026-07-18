import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lamma_new/l10n/app_localizations.dart';

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart';
import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_trip_tracking_page.dart';

class DriverActiveTripCard extends StatelessWidget {
  final TripEntity trip;

  const DriverActiveTripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    String tripId = trip.id ?? '';
    String status = trip.status.value;
    String destination = trip.destination ?? l10n.dropoffLocationDefault;
    String finalPrice = (trip.finalPrice ?? trip.negotiationPrice ?? trip.price)?.toString() ?? '0';
    bool isNegotiating = status == 'negotiating';
    bool isDriverTurn = isNegotiating && trip.lastNegotiator == 'passenger';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
          color: AppColors.cardWhite, 
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.dividerColor, width: 1.2),
          boxShadow: [
            BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.05),
                blurRadius: 12, 
                offset: const Offset(0, 4)
            )
          ]),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNegotiating) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.handshake_rounded, color: AppColors.warning, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text(isDriverTurn ? l10n.clientProposesNewPrice : l10n.waitingForClientResponse,
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12.sp,
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold))
                ]),
              ),
              SizedBox(height: 12.h),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                    radius: 16.r,
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    child: Icon(Icons.location_on_rounded, color: AppColors.error, size: 18.sp)),
                SizedBox(width: 12.w),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.dropoffLocationDefault,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: AppColors.textMuted)),
                  Text(destination,
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                          color: AppColors.textDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis)
                ])),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.monetization_on_rounded, color: AppColors.success, size: 20.sp),
                  SizedBox(width: 10.w),
                  Text(
                      isNegotiating
                          ? l10n.proposedPrice(finalPrice)
                          : l10n.finalPrice(finalPrice),
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp)),
                ],
              ),
            ),
            Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: const Divider(color: AppColors.dividerColor, thickness: 1)),
            if (isDriverTurn) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          elevation: 0),
                      icon: Icon(Icons.check_circle_rounded, size: 18.sp),
                      label: Text(l10n.agreeWithPrice,
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                      onPressed: () {
                        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                        context.read<TripActionsCubit>().acceptOffer(trip, true, currentUserId);
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: AppColors.textWhite,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            elevation: 0),
                        icon: Icon(Icons.handshake_rounded, size: 18.sp),
                        label: Text(l10n.negotiateBtn,
                            style: TextStyle(
                                fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                        onPressed: () async {
                          final offer = await TripDialogsHelper.showNegotiationDialog(
                            context: context,
                            royalGreen: AppColors.royalGreen,
                          );
                          if (offer != null && context.mounted) {
                            context.read<TripActionsCubit>().submitNegotiationOffer(
                                  tripId: tripId,
                                  price: offer.toString(),
                                  isDriver: true,
                                );
                          }
                        }),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
            ],
            if (status == 'accepted') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold, 
                      foregroundColor: AppColors.primaryNavy,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      elevation: 0),
                  icon: Icon(Icons.play_circle_fill_rounded, size: 20.sp),
                  label: Text(l10n.activateActiveTrip,
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
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
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1.5),
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
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy, 
                        foregroundColor: AppColors.textWhite,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        elevation: 0),
                    icon: Icon(Icons.map_rounded, size: 18.sp),
                    label: Text(l10n.detailsAndMap,
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (context) => DriverTripTrackingPage(tripId: tripId))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}