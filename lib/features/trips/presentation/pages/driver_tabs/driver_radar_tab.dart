// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import 'package:intl/intl.dart' hide TextDirection;

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/data/services/driver_radar_service.dart'; 
import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart'; 
import '../../../cubit/driver/driver_radar_cubit.dart';
import '../../../cubit/driver/driver_radar_state.dart';
// 💡 تنبيه: تأكد من إضافة ملف الـ DriverRadarService في الـ imports هنا لو مش موجود
// import '../../../services/driver_radar_service.dart'; 

class DriverRadarTab extends StatelessWidget {
  final TabController tabController;
  
  const DriverRadarTab({super.key, required this.tabController});

  // دالة لقبول الرحلة مباشرة
  Future<void> _acceptTrip(BuildContext context, String tripId) async {
    try {
      String driverId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot driverDoc = await FirebaseFirestore.instance.collection('users').doc(driverId).get();
      String driverName = driverDoc.exists ? (driverDoc.data() as Map<String, dynamic>)['name'] : 'كابتن لَمَّة';

      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'status': 'accepted',
        'driverId': driverId,
        'driverName': driverName,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم قبول الرحلة بنجاح! 🚗', style: TextStyle(fontFamily: 'Cairo')), 
            backgroundColor: AppColors.success,
          )
        );
        tabController.animateTo(1); 
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')), 
            backgroundColor: AppColors.error,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // 🟢 هنا التعديل: تم تمرير DriverRadarService() للكيوبت
      create: (context) => DriverRadarCubit(DriverRadarService())..startListeningToRadar(),
      child: BlocBuilder<DriverRadarCubit, DriverRadarState>(
        builder: (context, state) {
          if (state is DriverRadarLoading || state is DriverRadarInitial) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentGold));
          }

          if (state is DriverRadarError) {
            return Center(child: Text(state.message, style: TextStyle(color: AppColors.error, fontFamily: 'Cairo', fontSize: 16.sp)));
          }

          if (state is DriverRadarLoaded) {
            var activeTrips = state.trips.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return data['isDeletedForDriver'] != true && 
                     (data['status'] == 'pending' || data['status'] == 'negotiating');
            }).toList();

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
                var doc = activeTrips[index];
                var data = doc.data() as Map<String, dynamic>;
                
                String timeStr = 'الآن';
                if (data['createdAt'] != null) {
                  timeStr = DateFormat('hh:mm a').format((data['createdAt'] as Timestamp).toDate());
                }

                String displayPrice = data['status'] == 'negotiating' && data['negotiationPrice'] != null 
                    ? data['negotiationPrice'].toString() 
                    : data['price']?.toString() ?? '0';

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
                                    Text(data['clientName'] ?? 'عميل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.textDark)),
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
                        
                        if (data['status'] == 'negotiating') ...[
                          SizedBox(height: 10.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8.r)),
                            child: Row(
                              children: [
                                Icon(Icons.handshake_rounded, color: AppColors.warning, size: 16.sp),
                                SizedBox(width: 8.w),
                                Text(
                                  data['lastNegotiator'] == 'driver' ? 'في انتظار رد العميل' : 'العميل يقترح هذا السعر', 
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
                            Expanded(child: Text(data['pickupAddress'] ?? 'موقع الانطلاق', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppColors.error, size: 20),
                            SizedBox(width: 8.w),
                            Expanded(child: Text(data['dropoffAddress'] ?? 'وجهة الوصول', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp), maxLines: 2, overflow: TextOverflow.ellipsis)),
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
                                    docId: doc.id, 
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
                                onPressed: () => _acceptTrip(context, doc.id),
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