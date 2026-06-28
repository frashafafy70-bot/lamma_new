import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 

// 🟢 استدعاء الألوان وخدمة التوجيه (المايسترو)
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/services/navigation_service.dart';

import '../../../cubit/driver/driver_radar_cubit.dart';
import '../../../cubit/driver/driver_radar_state.dart';
import '../../widgets/smart_trip_card.dart';
import '../../../data/models/trip_model.dart';

class DriverRadarTab extends StatelessWidget {
  final TabController tabController;
  const DriverRadarTab({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return BlocProvider(
      create: (context) => DriverRadarCubit()..startListeningToRadar(),
      child: BlocBuilder<DriverRadarCubit, DriverRadarState>(
        builder: (context, state) {
          if (state is DriverRadarLoading || state is DriverRadarInitial) {
            return const Center(child: CircularProgressIndicator(color: AppColors.royalGreen));
          }

          if (state is DriverRadarError) {
            return Center(
              child: Text(state.message, style: TextStyle(color: AppColors.error, fontFamily: 'Cairo', fontSize: 16.sp)),
            );
          }

          if (state is DriverRadarLoaded) {
            // 🟢 الفلترة السحرية: استبعاد أي طلب تم مسحه بواسطة هذا الكابتن
            var activeTrips = state.trips.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return data['isDeletedForDriver'] != true;
            }).toList();

            // 🟢 التأكد إن القائمة الجديدة مش فاضية
            if (activeTrips.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.radar_outlined, size: 60.sp, color: AppColors.textMuted.withValues(alpha: 0.4)),
                    SizedBox(height: 10.h),
                    Text('لا توجد طلبات حالياً', style: TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.only(top: 16.h, bottom: 100.h), 
              itemCount: activeTrips.length, // 🟢 استخدام القائمة المفلترة
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemBuilder: (context, index) {
                var doc = activeTrips[index]; // 🟢 استخدام القائمة المفلترة
                var data = doc.data() as Map<String, dynamic>;
                
                TripModel tripModel = TripModel.fromMap(data, doc.id);
                
                return SmartTripCard(
                  trip: tripModel,
                  isDriver: true, 
                  currentUserId: currentUserId,
                  onChatPressed: () {
                    NavigationService.navigateToTripChat(doc.id);
                  },
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