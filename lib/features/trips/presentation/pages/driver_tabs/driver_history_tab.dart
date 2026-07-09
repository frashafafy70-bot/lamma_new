// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; 

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart'; 
import 'package:lamma_new/features/trips/cubit/driver/driver_history_cubit.dart'; 

import 'package:lamma_new/features/trips/presentation/widgets/premium_tab_header.dart'; 

class DriverHistoryTab extends StatefulWidget {
  const DriverHistoryTab({super.key});

  @override
  State<DriverHistoryTab> createState() => _DriverHistoryTabState();
}

class _DriverHistoryTabState extends State<DriverHistoryTab> with AutomaticKeepAliveClientMixin {
  
  static const Color _primaryNavy = Color(0xFF0F172A);
  static const Color _royalGreen = Color(0xFF1B4332);

  @override
  bool get wantKeepAlive => true; 

  @override
  Widget build(BuildContext context) {
    super.build(context); 
    
    return BlocProvider(
      create: (context) => DriverHistoryCubit()..startListeningToHistoryTrips(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Column(
          children: [
            PremiumTabHeader(title: 'سجل الرحلات'),
            
            Expanded(
              child: BlocBuilder<DriverHistoryCubit, DriverHistoryState>(
                builder: (context, state) {
                  
                  if (state is DriverHistoryInitial || state is DriverHistoryLoading) {
                    return const Center(child: CircularProgressIndicator(color: _royalGreen));
                  }

                  if (state is DriverHistoryError) {
                    return Center(
                      child: Text(
                        state.message, 
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.red)
                      ),
                    );
                  }

                  if (state is DriverHistoryLoaded) {
                    if (state.trips.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 80.sp, color: Colors.grey.shade300),
                            SizedBox(height: 16.h),
                            Text(
                              'لا يوجد لديك رحلات سابقة حتى الآن.', 
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.grey.shade600, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(16.w),
                      itemCount: state.trips.length,
                      itemBuilder: (context, index) {
                        var data = state.trips[index].data() as Map<String, dynamic>;
                        String docId = state.trips[index].id;
                        
                        bool isCompleted = data['status'] == 'completed';
                        
                        // تجهيز البيانات الأساسية
                        String pickup = data['pickup'] ?? data['pickupAddress'] ?? 'موقع الانطلاق';
                        String destination = data['destination'] ?? data['dropoffAddress'] ?? 'وجهة الوصول';
                        String finalPrice = data['finalPrice']?.toString() ?? data['price']?.toString() ?? '0';
                        String passengerName = data['passengerName'] ?? 'عميل (غير محدد)';
                        
                        // بيانات المسافة والوقت
                        String distance = data['distance']?.toString() ?? 'غير محدد';
                        String duration = data['duration']?.toString() ?? 'غير محدد';
                        
                        String timeStr = 'غير معروف';
                        if (data['createdAt'] != null) {
                          DateTime dt = (data['createdAt'] as Timestamp).toDate();
                          timeStr = DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(dt);
                        }

                        return Card(
                          elevation: 2, 
                          margin: EdgeInsets.only(bottom: 16.h), 
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            side: BorderSide(color: Colors.grey.shade200, width: 1),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. الجزء العلوي (النوع والحالة ومسح الرحلة)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14.r,
                                          backgroundColor: _royalGreen.withOpacity(0.1),
                                          child: Icon(
                                            data['tripCategory'] == 'طلبات' ? Icons.shopping_bag_rounded : Icons.local_taxi_rounded,
                                            size: 16.sp,
                                            color: _royalGreen,
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          '${data['tripCategory'] ?? 'مشوار'}', 
                                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: _primaryNavy)
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                          decoration: BoxDecoration(
                                            color: isCompleted ? const Color(0x1A4CAF50) : const Color(0x1AF44336), 
                                            borderRadius: BorderRadius.circular(8.r)
                                          ),
                                          child: Text(
                                            isCompleted ? 'مكتملة ✅' : 'ملغية ❌', 
                                            style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold, color: isCompleted ? Colors.green.shade700 : Colors.red.shade700)
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        InkWell(
                                          onTap: () => TripDialogsHelper.showDeleteTripDialog(context: context, docId: docId, isDriver: true),
                                          child: Container(
                                            padding: EdgeInsets.all(6.w),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(8.r),
                                            ),
                                            child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700, size: 20.sp),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  child: const Divider(color: Color(0xFFEEEEEE), height: 1),
                                ),
                                
                                // 2. معلومات العميل
                                Row(
                                  children: [
                                    Icon(Icons.person_outline_rounded, size: 18.sp, color: Colors.grey.shade600),
                                    SizedBox(width: 6.w),
                                    Text('العميل: $passengerName', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                SizedBox(height: 12.h),

                                // 3. مسار الرحلة تفصيلياً (انطلاق - وصول)
                                Row(
                                  children: [
                                    Column(
                                      children: [
                                        Icon(Icons.my_location_rounded, color: _royalGreen, size: 18.sp),
                                        Container(height: 20.h, width: 2.w, color: Colors.grey.shade300),
                                        Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 18.sp),
                                      ],
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(pickup, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold, color: _primaryNavy), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          SizedBox(height: 18.h),
                                          Text(destination, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold, color: _primaryNavy), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // 4. المسافة والمدة الزمنية
                                SizedBox(height: 14.h),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.route_outlined, size: 14.sp, color: Colors.blue.shade700),
                                          SizedBox(width: 4.w),
                                          Text(
                                            distance.contains('كم') ? distance : '$distance كم', 
                                            style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.blue.shade700)
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.timer_outlined, size: 14.sp, color: Colors.orange.shade700),
                                          SizedBox(width: 4.w),
                                          Text(
                                            duration.contains('دقيقة') ? duration : '$duration دقيقة', 
                                            style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.orange.shade700)
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // 5. الحاوية السفلية للمعلومات المالية والزمنية
                                Container(
                                  padding: EdgeInsets.all(12.w),
                                  margin: EdgeInsets.only(top: 16.h),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(color: Colors.grey.shade200)
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.access_time_rounded, color: Colors.grey.shade600, size: 16.sp),
                                          SizedBox(width: 6.w),
                                          Text(timeStr, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      Text('$finalPrice ج.م', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: _royalGreen)),
                                    ],
                                  ),
                                ),

                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                  
                  return const SizedBox(); 
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}