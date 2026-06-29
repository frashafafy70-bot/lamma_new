// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 🟢 تم إضافة الـ Bloc

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart'; 
// تأكد من مسار الكيوبت عندك لو مختلف
import 'package:lamma_new/features/trips/cubit/driver/driver_history_cubit.dart'; 

class DriverHistoryTab extends StatefulWidget {
  const DriverHistoryTab({super.key});

  @override
  State<DriverHistoryTab> createState() => _DriverHistoryTabState();
}

class _DriverHistoryTabState extends State<DriverHistoryTab> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; 

  @override
  Widget build(BuildContext context) {
    super.build(context); 
    
    final Color primaryNavy = const Color(0xFF0F172A);

    // 🟢 استخدام BlocProvider لتشغيل الكيوبت بشكل مستقل داخل التاب لمنع الرمشة
    return BlocProvider(
      create: (context) => DriverHistoryCubit()..startListeningToHistoryTrips(),
      child: Container(
        color: Colors.grey.shade50,
        child: BlocBuilder<DriverHistoryCubit, DriverHistoryState>(
          builder: (context, state) {
            
            // 1. حالة التحميل
            if (state is DriverHistoryInitial || state is DriverHistoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. حالة الخطأ
            if (state is DriverHistoryError) {
              return Center(
                child: Text(
                  state.message, 
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.red)
                ),
              );
            }

            // 3. حالة النجاح (Loaded)
            if (state is DriverHistoryLoaded) {
              // لو السجل فاضي
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

              // لو فيه رحلات
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                itemCount: state.trips.length,
                itemBuilder: (context, index) {
                  var data = state.trips[index].data() as Map<String, dynamic>;
                  String docId = state.trips[index].id;
                  
                  // الكيوبت بيجيب الاثنين (canceled و completed) فنتأكد هنا
                  bool isCompleted = data['status'] == 'completed';
                  
                  String timeStr = 'غير معروف';
                  if (data['createdAt'] != null) {
                    DateTime dt = (data['createdAt'] as Timestamp).toDate();
                    timeStr = DateFormat('yyyy/MM/dd - hh:mm a').format(dt);
                  }

                  return Card(
                    elevation: 2, 
                    margin: EdgeInsets.only(bottom: 12.h), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '🚗 ${data['tripCategory'] ?? 'مشوار'}', 
                                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: primaryNavy)
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1), 
                                      borderRadius: BorderRadius.circular(8.r)
                                    ),
                                    child: Text(
                                      isCompleted ? 'مكتملة ✅' : 'ملغية ❌', 
                                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold, color: isCompleted ? Colors.green : Colors.red)
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  InkWell(
                                    onTap: () => TripDialogsHelper.showDeleteTripDialog(context: context, docId: docId, isDriver: true),
                                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                timeStr, 
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade600)
                              ),
                              Text(
                                '${data['price'] ?? '0'} ج.م', 
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1B4332))
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
            
            return const SizedBox(); // Fallback
          },
        ),
      ),
    );
  }
}