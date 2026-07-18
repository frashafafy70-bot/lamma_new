import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lamma_new/l10n/app_localizations.dart';    

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/extensions/context_extension.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart';
import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart';
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';

class DriverBookingRequestCard extends StatelessWidget {
  final QueryDocumentSnapshot booking;

  const DriverBookingRequestCard({super.key, required this.booking});

  void _showCancelBookingDialog(BuildContext context, DocumentSnapshot bookingDoc) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text(l10n.cancelBookingTitle, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 18.sp)),
        content: Text(l10n.cancelBookingConfirmation, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: AppColors.textDark)),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: Text(l10n.backBtn, style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textMuted)),
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

              context.read<DriverActiveTripsCubit>().cancelBooking(
                  bookingDoc.id, tripId, passengerId, seatsToReturn, wasAccepted);
            },
            child: Text(l10n.yesCancel, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    var data = booking.data() as Map<String, dynamic>;
    bool isPending = data['status'] == 'pending';

    String timeString = l10n.unspecified;
    if (data['createdAt'] != null) {
      DateTime dt = (data['createdAt'] as Timestamp).toDate();
      timeString = DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(dt);
    }

    return Card(
      elevation: 0,
      color: AppColors.cardWhite,
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
              color: isPending
                  ? AppColors.warning.withValues(alpha: 0.4)
                  : AppColors.success.withValues(alpha: 0.4),
              width: 1.5)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                    radius: 20.r,
                    backgroundColor: isPending
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                    child: Icon(Icons.event_seat_rounded,
                        color: isPending ? AppColors.warning : AppColors.success,
                        size: 22.sp)),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          data['seats'] == 1 && data['tripType'] == 'full_car'
                              ? l10n.fullCarBookingRequest
                              : l10n.seatsBookingRequest,
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15.sp, color: AppColors.textDark)),
                      SizedBox(height: 4.h),
                      Text(
                          isPending
                              ? l10n.pendingSeatsRequest(data['seats'].toString())
                              : l10n.acceptedSeatsRequest(data['seats'].toString()),
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold, color: isPending ? AppColors.warning : AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                  color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(8.r)),
              child: Row(children: [
                Icon(Icons.access_time_filled_rounded, size: 16.sp, color: AppColors.textMuted),
                SizedBox(width: 8.w),
                Text(l10n.requestTime(timeString),
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: AppColors.textDark, fontWeight: FontWeight.w600))
              ]),
            ),
            Padding(padding: EdgeInsets.symmetric(vertical: 12.h), child: const Divider(height: 1, color: AppColors.dividerColor)),
            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          padding: EdgeInsets.symmetric(vertical: 10.h)),
                      icon: Icon(Icons.check_circle_rounded, size: 18.sp),
                      label: Text(l10n.acceptBtn, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        int seatsToDeduct = data['seats'] ?? 1;
                        String tripId = data['tripId'];
                        context.read<DriverActiveTripsCubit>().acceptBooking(
                            booking.id, tripId, seatsToDeduct);
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          padding: EdgeInsets.symmetric(vertical: 10.h)),
                      icon: Icon(Icons.close_rounded, size: 18.sp),
                      label: Text(l10n.rejectBtn, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        String tripId = data['tripId'];
                        String passengerId = data['passengerId'];
                        context.read<DriverActiveTripsCubit>().rejectBooking(
                            booking.id, tripId, passengerId);
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
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      padding: EdgeInsets.symmetric(vertical: 10.h)),
                  icon: Icon(Icons.chat_bubble_rounded, size: 18.sp),
                  label: Text(l10n.messageClient, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: data['tripId']))),
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
                            padding: EdgeInsets.symmetric(vertical: 10.h)),
                        icon: Icon(Icons.edit_note_rounded, size: 18.sp),
                        label: Text(l10n.edit, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final result = await TripDialogsHelper.showEditBookingDialog(
                            context: context,
                            currentSeats: data['seats'] ?? 1,
                            royalGreen: AppColors.royalGreen,
                          );
                          if (result != null && context.mounted) {
                             context.read<TripActionsCubit>().updateBookingSeats(
                              bookingId: booking.id,
                              newSeats: result['seats'],
                              travelDate: result['date'],
                            );
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
                      icon: Icon(Icons.delete_outline_rounded, size: 18.sp),
                      label: Text(l10n.cancel, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold)),
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
  }
}