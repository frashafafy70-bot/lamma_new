import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// استدعاء ملف الألوان المركزي والـ Dialogs
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart';

import 'package:lamma_new/features/trips/cubit/passenger/passenger_my_requests_cubit.dart';
import 'package:lamma_new/features/trips/cubit/passenger/passenger_my_requests_state.dart';
import 'package:lamma_new/features/trips/presentation/widgets/smart_trip_card.dart';
import 'package:lamma_new/features/trips/data/models/trip_model.dart';
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
              
              // 🟢 التوجيه التلقائي المباشر والمضمون أول ما الكابتن يوافق
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
                    TripModel tripModel = TripModel.fromMap(data, doc.id);
                    
                    return Column(
                      children: [
                        SmartTripCard(
                          trip: tripModel,
                          isDriver: false,
                          currentUserId: currentUserId,
                          onChatPressed: () {
                            // 🟢 التوجيه اليدوي الصريح عند ضغط زر المحادثة للعميل
                            if (!_navigatedTripIds.contains(doc.id)) {
                               _navigatedTripIds.add(doc.id);
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TripChatPage(tripId: doc.id)),
                            );
                          },
                        ),
                        // 🟢 ظهور كارت التفاوض تحت الطلب لو حالته التفاوض شغالة
                        if (data['status'] == 'negotiating') 
                          Container(
                            margin: EdgeInsets.only(bottom: 16.h, top: 4.h),
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: AppColors.warning, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.handshake_rounded, color: AppColors.warning, size: 20.sp),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        data['lastNegotiator'] == 'driver' 
                                          ? 'كابتن ${data['driverName'] ?? ''} يقترح سعر: ${data['negotiationPrice']} ج.م'
                                          : 'في انتظار رد الكابتن على سعرك: ${data['negotiationPrice']} ج.م',
                                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp, color: AppColors.textDark),
                                      ),
                                    ),
                                  ],
                                ),
                                // نظهر الزراير للعميل لو الكابتن هو اللي باعت العرض الأخير
                                if (data['lastNegotiator'] == 'driver') ...[
                                  SizedBox(height: 12.h),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primaryDark,
                                            side: const BorderSide(color: AppColors.primaryDark),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                          ),
                                          onPressed: () {
                                             TripDialogsHelper.showNegotiationDialog(
                                                context: context,
                                                docId: doc.id,
                                                royalGreen: AppColors.royalGreen,
                                                isDriver: false,
                                             );
                                          },
                                          child: Text('تفاوض', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primaryDark,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                          ),
                                          onPressed: () async {
                                             // موافقة العميل على العرض
                                             await FirebaseFirestore.instance.collection('trips').doc(doc.id).update({
                                               'status': 'accepted',
                                               'price': data['negotiationPrice'], 
                                               'acceptedAt': FieldValue.serverTimestamp(),
                                             });
                                          },
                                          child: Text('موافق', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                        ),
                                      ),
                                    ],
                                  )
                                ]
                              ],
                            ),
                          ),
                      ],
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