// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';

// استدعاء ملف الألوان المركزي
import 'package:lamma_new/core/theme/app_colors.dart';

import 'package:lamma_new/features/trips/cubit/passenger/passenger_my_requests_cubit.dart';
import 'package:lamma_new/features/trips/cubit/passenger/passenger_my_requests_state.dart';

// 🟢 التعديل: استدعاء كارت MyRequestTripCard اللي إحنا ظبطناه ودمجنا فيه كل المميزات
import 'package:lamma_new/features/trips/presentation/widgets/my_request_trip_card.dart'; 
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';

class PassengerMyRequestsTab extends StatefulWidget {
  const PassengerMyRequestsTab({super.key});

  @override
  State<PassengerMyRequestsTab> createState() => _PassengerMyRequestsTabState();
}

class _PassengerMyRequestsTabState extends State<PassengerMyRequestsTab> with AutomaticKeepAliveClientMixin {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // عشان نحفظ الرحلات اللي اتفتح ليها الخريطة قبل كده عشان متفتحش مرتين
  final Set<String> _navigatedTripIds = {};

  @override
  bool get wantKeepAlive => true; 

  @override
  void initState() {
    super.initState();
    context.read<PassengerMyRequestsCubit>().startListeningToMyRequests();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: AppColors.backgroundLight,
      child: BlocListener<PassengerMyRequestsCubit, PassengerMyRequestsState>(
        listener: (context, state) {
          if (state is PassengerMyRequestsLoaded) {
            for (var doc in state.requests) {
              final data = (doc.data() as Map<String, dynamic>?) ?? {}; 
              final tripId = doc.id;
              
              // التوجيه التلقائي المباشر والمضمون أول ما الكابتن يوافق
              if (data['status'] == 'accepted' && !_navigatedTripIds.contains(tripId)) {
                _navigatedTripIds.add(tripId); 
                
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TripChatPage(tripId: tripId)),
                );
              }
            }
          }
        },
        child: BlocBuilder<PassengerMyRequestsCubit, PassengerMyRequestsState>(
          builder: (context, state) {
            if (state is PassengerMyRequestsLoading || state is PassengerMyRequestsInitial) {
              return const Center(child: CircularProgressIndicator(color: AppColors.royalGreen));
            } 
            
            if (state is PassengerMyRequestsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, color: AppColors.error, size: 60.sp),
                    SizedBox(height: 16.h),
                    Text(state.message, style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: AppColors.textDark)),
                    SizedBox(height: 16.h),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))
                      ),
                      onPressed: () => context.read<PassengerMyRequestsCubit>().startListeningToMyRequests(),
                      icon: Icon(Icons.refresh_rounded, color: Colors.white, size: 20.sp),
                      label: Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 14.sp)),
                    )
                  ],
                ),
              );
            } 
            
            if (state is PassengerMyRequestsLoaded) {
              final requests = state.requests;
              
              if (requests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, color: AppColors.textMuted.shade300, size: 80.sp),
                      SizedBox(height: 16.h),
                      Text('لا توجد طلبات نشطة حالياً', style: TextStyle(fontFamily: 'Cairo', fontSize: 18.sp, color: AppColors.textMuted.shade600, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.royalGreen,
                onRefresh: () async {
                  context.read<PassengerMyRequestsCubit>().startListeningToMyRequests();
                },
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final doc = requests[index];
                    final data = (doc.data() as Map<String, dynamic>?) ?? {}; 
                    
                    // 🟢 التعديل هنا: نستخدم MyRequestTripCard الجديد اللي فيه الخريطة والتفاوض مدمجين
                    return MyRequestTripCard(
                      docId: doc.id,
                      data: data,
                      royalGreen: AppColors.royalGreen,
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}