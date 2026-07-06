// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import 'package:intl/intl.dart' hide TextDirection;

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/data/repositories/driver_radar_repository_impl.dart'; 
import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart'; 
import 'package:lamma_new/features/trips/data/models/trip_model.dart'; 

import '../../../cubit/driver/driver_radar_cubit.dart';
import '../../../cubit/driver/driver_radar_state.dart';

// 🟢 استيراد الـ HomeCubit عشان نقدر ننقل الكابتن لتاب الرحلات النشطة
import 'package:lamma_new/features/home/cubit/home_cubit.dart';

class DriverRadarTab extends StatelessWidget {
  // 🟢 تم إزالة الـ tabController نهائياً من هنا
  const DriverRadarTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DriverRadarCubit(DriverRadarRepositoryImpl())..listenToRadarTrips(),
      child: BlocConsumer<DriverRadarCubit, DriverRadarState>(
        listener: (context, state) {
          if (state is DriverRadarActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم قبول الرحلة بنجاح! 🚗', style: TextStyle(fontFamily: 'Cairo')), 
                backgroundColor: AppColors.success,
              )
            );
            // 🟢 استخدام الـ HomeCubit لنقل الكابتن لتاب الرحلات النشطة (رقم 2)
            context.read<HomeCubit>().changeTab(2); 
          } 
          else if (state is DriverRadarActionError) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')), 
                backgroundColor: AppColors.error,
              )
            );
          }
        },
        buildWhen: (previous, current) => current is DriverRadarLoaded || current is DriverRadarLoading || current is DriverRadarError,
        builder: (context, state) {
          if (state is DriverRadarLoading || state is DriverRadarInitial) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentGold));
          }

          if (state is DriverRadarError) {
            return Center(child: Text(state.message, style: TextStyle(color: AppColors.error, fontFamily: 'Cairo', fontSize: 16.sp)));
          }

          if (state is DriverRadarLoaded) {
            final activeTrips = state.radarTrips;

            if (activeTrips.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(30.w),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accentGoldLight),
                      child: Icon(Icons.radar_rounded, size: 80.sp, color: AppColors.accentGold),
                    ),
                    SizedBox(height: 24.h),
                    Text('جاري البحث عن طلبات...', style: TextStyle(fontFamily: 'Cairo', fontSize: 18.sp, color: AppColors.textDark, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16.w),
              physics: const BouncingScrollPhysics(),
              itemCount: activeTrips.length,
              itemBuilder: (context, index) {
                TripModel trip = activeTrips[index];
                
                String timeStr = 'الآن';
                if (trip.createdAt != null) {
                  timeStr = DateFormat('hh:mm a').format(trip.createdAt!);
                }

                String displayPrice = trip.status == 'negotiating' && trip.negotiationPrice != null 
                    ? trip.negotiationPrice!
                    : trip.price ?? '0';

                String clientName = trip.passengerName ?? 'عميل';
                String pickupPoint = trip.pickup ?? 'موقع الانطلاق';
                String dropoffPoint = trip.destination ?? 'وجهة الوصول';

                return Card(
                  elevation: 4,
                  shadowColor: Colors.black12,
                  margin: EdgeInsets.only(bottom: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
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
                                  backgroundColor: AppColors.textDark.withValues(alpha: 0.1), 
                                  child: const Icon(Icons.person, color: AppColors.textDark)
                                ),
                                SizedBox(width: 10.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(clientName, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.textDark)),
                                    Text(timeStr, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: AppColors.textMuted.shade500)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20.r)),
                              child: Text('$displayPrice ج.م', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 14.sp)),
                            ),
                          ],
                        ),
                        
                        if (trip.status == 'negotiating') ...[
                          SizedBox(height: 10.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8.r)),
                            child: Row(
                              children: [
                                Icon(Icons.handshake_rounded, color: AppColors.warning, size: 16.sp),
                                SizedBox(width: 8.w),
                                Text(
                                  trip.lastNegotiator == 'driver' ? 'في انتظار رد العميل' : 'العميل يقترح هذا السعر', 
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: AppColors.textDark, fontWeight: FontWeight.bold)
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        Divider(height: 30.h, color: AppColors.dividerColor),
                        Row(
                          children: [
                            const Icon(Icons.my_location_rounded, color: AppColors.info, size: 20),
                            SizedBox(width: 8.w),
                            Expanded(child: Text(pickupPoint, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppColors.error, size: 20),
                            SizedBox(width: 8.w),
                            Expanded(child: Text(dropoffPoint, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryDark,
                                  side: const BorderSide(color: AppColors.primaryDark),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                ),
                                icon: Icon(Icons.handshake_rounded, size: 18.sp),
                                label: Text('تفاوض', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  TripDialogsHelper.showNegotiationDialog(
                                    context: context, 
                                    docId: trip.id!,
                                    royalGreen: AppColors.royalGreen,
                                    isDriver: true, 
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDark,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                ),
                                icon: Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18.sp),
                                label: Text('موافق بالسعر', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                                onPressed: () {
                                  String? negotiatedPrice = trip.status == 'negotiating' ? displayPrice : null;
                                  context.read<DriverRadarCubit>().acceptTrip(trip.id!, negotiatedPrice: negotiatedPrice);
                                },
                              ),
                            ),
                          ],
                        )
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
}