import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';

class NegotiationWidget extends StatefulWidget {
  final TripEntity trip;
  final bool isDriver;
  final String currentUserId;

  const NegotiationWidget({
    super.key,
    required this.trip,
    required this.isDriver,
    required this.currentUserId,
  });

  @override
  State<NegotiationWidget> createState() => _NegotiationWidgetState();
}

class _NegotiationWidgetState extends State<NegotiationWidget> {
  final TextEditingController _priceController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String currentUserRole = widget.isDriver ? 'driver' : 'passenger';
    bool isMyTurnToReply = widget.trip.lastNegotiator != currentUserRole;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.info),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake_rounded, color: AppColors.info, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                'تفاوض على السعر',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: AppColors.textDark),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'السعر المعروض حالياً: ${widget.trip.negotiationPrice ?? widget.trip.price} ج.م',
            style: TextStyle(fontSize: 15.sp, color: AppColors.primaryDark),
          ),
          SizedBox(height: 16.h),
          if (isMyTurnToReply) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success),
                    onPressed: () {
                      // 🟢 رجعناها 3 Positional Arguments زي ما الكيوبت طالب
                      context.read<TripActionsCubit>().acceptOffer(
                          widget.trip, widget.isDriver, widget.currentUserId);
                    },
                    child: const Text('قبول',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error),
                    onPressed: () {
                      // 🟢 رجعناها 2 Positional Arguments
                      context
                          .read<TripActionsCubit>()
                          .rejectOrCancelTrip(widget.trip, widget.isDriver);
                    },
                    child: const Text('رفض',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'سعر جديد',
                      hintStyle: const TextStyle(fontFamily: 'Cairo'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold),
                    onPressed: () {
                      if (_priceController.text.isNotEmpty) {
                        // 🟢 عدلنا أسماء البارامترز لتطابق المتوقع غالباً (استخدمنا tripId بدل trip)
                        context.read<TripActionsCubit>().submitNegotiationOffer(
                              tripId: widget.trip.id ?? '',
                              price: _priceController.text,
                              isDriver: widget.isDriver,
                            );
                      }
                    },
                    child: const Text('عرض',
                        style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
          ] else ...[
            Center(
              child: Text(
                'في انتظار رد الطرف الآخر...',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
