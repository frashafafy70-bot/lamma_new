// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; 
import 'package:intl/intl.dart' hide TextDirection;

import 'package:lamma_new/core/di/injection_container.dart'; // 🟢
import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart'; 
import 'package:lamma_new/features/trips/cubit/driver/driver_history_cubit.dart'; 
import 'package:lamma_new/features/trips/cubit/driver/driver_history_state.dart'; 
import 'package:lamma_new/features/trips/data/repositories/trip_repository_impl.dart'; 
import 'package:lamma_new/features/trips/presentation/widgets/premium_tab_header.dart';
// 🟢
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_state.dart';

class DriverHistoryTab extends StatefulWidget {
  final bool showHeader;
  const DriverHistoryTab({super.key, this.showHeader = false});

  @override
  State<DriverHistoryTab> createState() => _DriverHistoryTabState();
}

class _DriverHistoryTabState extends State<DriverHistoryTab> with AutomaticKeepAliveClientMixin {
  
  static const Color _primaryNavy = Color(0xFF0F172A);
  static const Color _royalGreen = Color(0xFF1B4332);
  
  final ScrollController _scrollController = ScrollController(); 

  @override
  bool get wantKeepAlive => true; 

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= (maxScroll - 200)) {
      context.read<DriverHistoryCubit>().fetchMoreHistoryTrips();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => DriverHistoryCubit(TripRepositoryImpl())..startListeningToHistoryTrips()),
        BlocProvider(create: (context) => sl<TripActionsCubit>()), // 🟢
      ],
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Column(
          children: [
            if (widget.showHeader)
              const PremiumTabHeader(title: 'سجل الرحلات'),
            
            Expanded(
              // 🟢 الاستماع للأكشنز (حذف الطلب مثلاً)
              child: BlocListener<TripActionsCubit, TripActionsState>(
                listener: (context, state) {
                  if (state is TripActionsLoading) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator(color: _royalGreen)),
                    );
                  } else if (state is TripActionsSuccess) {
                    Navigator.of(context).pop(); 
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
                  } else if (state is TripActionsError) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
                  }
                },
                child: Builder( 
                  builder: (context) {
                    return RefreshIndicator(
                      color: _royalGreen,
                      onRefresh: () async {
                        await context.read<DriverHistoryCubit>().fetchInitialHistoryTrips();
                      },
                      child: BlocBuilder<DriverHistoryCubit, DriverHistoryState>(
                        builder: (context, state) {
                          
                          if (state is DriverHistoryInitial || state is DriverHistoryLoading) {
                            return const Center(child: CircularProgressIndicator(color: _royalGreen));
                          }

                          if (state is DriverHistoryError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(state.message, style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.red)),
                                  SizedBox(height: 16.h),
                                  ElevatedButton(
                                    onPressed: () => context.read<DriverHistoryCubit>().startListeningToHistoryTrips(),
                                    child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                                  )
                                ],
                              ),
                            );
                          }

                          if (state is DriverHistoryLoaded) {
                            if (state.trips.isEmpty) {
                              return ListView( 
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                                  Center(
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
                                  ),
                                ],
                              );
                            }

                            return ListView.builder(
                              controller: _scrollController, 
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.all(16.w),
                              itemCount: state.trips.length + (state.isFetchingMore ? 1 : 0), 
                              itemBuilder: (context, index) {
                                
                                if (index >= state.trips.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(child: CircularProgressIndicator(color: _royalGreen)),
                                  );
                                }

                                var trip = state.trips[index];
                                String docId = trip.id ?? '';
                                
                                bool isCompleted = trip.status == 'completed';
                                
                                String pickup = trip.pickup ?? 'موقع الانطلاق';
                                String destination = trip.destination ?? 'وجهة الوصول';
                                String finalPrice = trip.finalPrice ?? trip.price ?? '0';
                                String passengerName = trip.passengerName ?? 'عميل (غير محدد)';
                                
                                String distance = 'غير محدد'; 
                                String duration = 'غير محدد';
                                
                                String timeStr = 'غير معروف';
                                if (trip.createdAt != null) {
                                  timeStr = DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(trip.createdAt!);
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
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 14.r,
                                                  backgroundColor: _royalGreen.withOpacity(0.1),
                                                  child: Icon(
                                                    trip.tripCategory == 'طلبات' ? Icons.shopping_bag_rounded : Icons.local_taxi_rounded,
                                                    size: 16.sp,
                                                    color: _royalGreen,
                                                  ),
                                                ),
                                                SizedBox(width: 8.w),
                                                Text(
                                                  trip.tripCategory ?? 'مشوار', 
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
                                                  // 🟢 استخدام الهيلبر النظيف ومسح الرحلة عبر الكيوبت إذا وافق المستخدم
                                                  onTap: () async {
                                                    final confirm = await TripDialogsHelper.showDeleteTripDialog(context: context);
                                                    if (confirm) {
                                                      // قم باستدعاء الدالة الخاصة بمسح الرحلة من السجل في الكيوبت هنا
                                                      // context.read<TripActionsCubit>().deleteTripFromHistory(tripId: docId);
                                                    }
                                                  },
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
                                        
                                        Row(
                                          children: [
                                            Icon(Icons.person_outline_rounded, size: 18.sp, color: Colors.grey.shade600),
                                            SizedBox(width: 6.w),
                                            Text('العميل: $passengerName', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                        SizedBox(height: 12.h),

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
                    );
                  }
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}