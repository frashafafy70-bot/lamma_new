// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:intl/intl.dart' hide TextDirection; // 🟢 عشان نظبط الوقت والتاريخ بشياكة

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/cubit/passenger/passenger_my_requests_cubit.dart';
import 'package:lamma_new/features/trips/cubit/passenger/passenger_my_requests_state.dart';
import 'package:lamma_new/features/trips/presentation/widgets/my_request_trip_card.dart'; 
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';

class PassengerMyRequestsTab extends StatefulWidget {
  const PassengerMyRequestsTab({super.key});

  @override
  State<PassengerMyRequestsTab> createState() => _PassengerMyRequestsTabState();
}

class _PassengerMyRequestsTabState extends State<PassengerMyRequestsTab> with AutomaticKeepAliveClientMixin {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Set<String> _navigatedTripIds = {};

  @override
  bool get wantKeepAlive => true; 

  @override
  void initState() {
    super.initState();
    context.read<PassengerMyRequestsCubit>().startListeningToMyRequests();
  }

  // 🟢 ديالوج التأكيد قبل ما العميل يلغي حجز الكرسي
  void _showCancelBookingDialog(BuildContext context, DocumentReference bookingRef) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text('إلغاء الحجز', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18.sp)),
        content: Text('هل أنت متأكد من إلغاء طلب الحجز؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تراجع', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await bookingRef.delete(); // 🟢 مسح الحجز فوراً
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الحجز بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
              }
            },
            child: const Text('نعم، إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final Color primaryNavy = const Color(0xFF0F172A);

    return Container(
      color: AppColors.backgroundLight,
      child: BlocListener<PassengerMyRequestsCubit, PassengerMyRequestsState>(
        listener: (context, state) {
          if (state is PassengerMyRequestsLoaded) {
            for (var doc in state.requests) {
              final data = (doc.data() as Map<String, dynamic>?) ?? {}; 
              final tripId = doc.id;
              
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
              
              return RefreshIndicator(
                color: AppColors.royalGreen,
                onRefresh: () async {
                  context.read<PassengerMyRequestsCubit>().startListeningToMyRequests();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      // =================================================================
                      // 💺 أولاً: جزء حجوزات رحلات السفر (تصميم بريميوم شيك جداً ✨)
                      // =================================================================
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('trip_bookings')
                            .where('passengerId', isEqualTo: currentUserId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h, bottom: 8.h),
                                child: Text('حجوزات السفر الخاصة بي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.royalGreen)),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  var booking = snapshot.data!.docs[index];
                                  var data = booking.data() as Map<String, dynamic>;
                                  bool isAccepted = data['status'] == 'accepted';
                                  
                                  // 🟢 تظبيط شكل الوقت والتاريخ
                                  String timeString = 'غير محدد';
                                  if (data['createdAt'] != null) {
                                    DateTime dt = (data['createdAt'] as Timestamp).toDate();
                                    timeString = DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(dt);
                                  }
                                  
                                  return Card(
                                    elevation: 3,
                                    margin: EdgeInsets.only(bottom: 16.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.r), 
                                      side: BorderSide(color: isAccepted ? Colors.green.withValues(alpha: 0.4) : Colors.orange.withValues(alpha: 0.4), width: 1.5)
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(16.w),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // الجزء العلوي: الأيقونة والعنوان
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 20.r,
                                                backgroundColor: isAccepted ? Colors.green.shade50 : Colors.orange.shade50, 
                                                child: Icon(Icons.directions_bus_filled_rounded, color: isAccepted ? Colors.green : Colors.orange, size: 22.sp)
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(data['seats'] == 1 && data['tripType'] == 'full_car' ? 'حجز رحلة كاملة' : 'حجز مقاعد سفر', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15.sp, color: primaryNavy)),
                                                    SizedBox(height: 4.h),
                                                    Text(
                                                      isAccepted ? '✅ تم القبول - حجزت ${data['seats']} مقاعد' : '⏳ قيد الانتظار - طلبت ${data['seats']} مقاعد', 
                                                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold, color: isAccepted ? Colors.green.shade700 : Colors.orange.shade700)
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          SizedBox(height: 12.h),
                                          
                                          // 🟢 الجزء الأوسط: الوقت والتاريخ
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8.r)),
                                            child: Row(
                                              children: [
                                                Icon(Icons.access_time_filled_rounded, size: 16.sp, color: Colors.grey.shade500),
                                                SizedBox(width: 8.w),
                                                Text('وقت الطلب: $timeString', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),

                                          Padding(padding: EdgeInsets.symmetric(vertical: 12.h), child: const Divider(height: 1)),

                                          // 🟢 الجزء السفلي: الأزرار الشيك (شات + إلغاء)
                                          Row(
                                            children: [
                                              if (isAccepted) ...[
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: primaryNavy,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                                      padding: EdgeInsets.symmetric(vertical: 10.h)
                                                    ),
                                                    icon: Icon(Icons.chat_bubble_rounded, size: 18.sp, color: Colors.white),
                                                    label: Text('مراسلة السائق', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                                                    onPressed: () {
                                                      Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: data['tripId'])));
                                                    },
                                                  ),
                                                ),
                                                SizedBox(width: 10.w),
                                              ],
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.redAccent,
                                                    side: BorderSide(color: Colors.redAccent.shade200),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                                    padding: EdgeInsets.symmetric(vertical: 10.h)
                                                  ),
                                                  icon: Icon(Icons.delete_outline_rounded, size: 18.sp),
                                                  label: Text('إلغاء الحجز', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold)),
                                                  onPressed: () => _showCancelBookingDialog(context, booking.reference),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: const Divider(thickness: 1.5),
                              ),
                            ],
                          );
                        },
                      ),

                      // =================================================================
                      // 🚗 ثانياً: جزء الطلبات والمشاوير العادية (الكود القديم بتاعك)
                      // =================================================================
                      if (requests.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 100.h),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_rounded, color: AppColors.textMuted.shade300, size: 80.sp),
                                SizedBox(height: 16.h),
                                Text('لا توجد طلبات نشطة حالياً', style: TextStyle(fontFamily: 'Cairo', fontSize: 18.sp, color: AppColors.textMuted.shade600, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true, // مهم للـ Column الداخلي
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final doc = requests[index];
                            final data = (doc.data() as Map<String, dynamic>?) ?? {}; 
                            
                            return MyRequestTripCard(
                              docId: doc.id,
                              data: data,
                              royalGreen: AppColors.royalGreen,
                            );
                          },
                        ),
                    ],
                  ),
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