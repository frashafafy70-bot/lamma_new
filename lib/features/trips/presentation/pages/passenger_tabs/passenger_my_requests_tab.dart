import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lamma_new/features/trips/cubit/passenger/passenger_my_requests_cubit.dart';
import 'package:lamma_new/features/trips/cubit/passenger/passenger_my_requests_state.dart';
import 'package:lamma_new/features/trips/presentation/widgets/smart_trip_card.dart';
import 'package:lamma_new/features/trips/data/models/trip_model.dart';
// 🟢 استدعاء صفحة الشات بشكل مباشر
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';

class PassengerMyRequestsTab extends StatefulWidget {
  const PassengerMyRequestsTab({super.key});

  @override
  State<PassengerMyRequestsTab> createState() => _PassengerMyRequestsTabState();
}

class _PassengerMyRequestsTabState extends State<PassengerMyRequestsTab> with AutomaticKeepAliveClientMixin {
  final Color royalGreen = const Color(0xFF1B4332);
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
      color: Colors.grey.shade50,
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
              return Center(child: CircularProgressIndicator(color: royalGreen));
            } 
            
            if (state is PassengerMyRequestsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red, size: 60.sp),
                    SizedBox(height: 16.h),
                    Text(state.message, style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.black87)),
                    SizedBox(height: 16.h),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: royalGreen,
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
                      Icon(Icons.inbox_rounded, color: Colors.grey.shade300, size: 80.sp),
                      SizedBox(height: 16.h),
                      Text('لا توجد طلبات نشطة حالياً', style: TextStyle(fontFamily: 'Cairo', fontSize: 18.sp, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: royalGreen,
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
                    
                    return SmartTripCard(
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