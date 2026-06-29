// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart'; 
import 'package:intl/intl.dart' hide TextDirection; // 🟢 مهم لتنسيق التاريخ

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/cubit/passenger/passenger_my_requests_cubit.dart';
import 'package:lamma_new/features/trips/presentation/pages/passenger_tabs/passenger_request_tab.dart';
import 'package:lamma_new/features/trips/presentation/pages/passenger_tabs/passenger_my_requests_tab.dart'; 

class TripsServicesPage extends StatefulWidget {
  const TripsServicesPage({super.key});

  @override
  State<TripsServicesPage> createState() => _TripsServicesPageState();
}

class _TripsServicesPageState extends State<TripsServicesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? ''; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false, 
        appBar: AppBar(
          backgroundColor: AppColors.royalGreen,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'خدمات التوصيل', 
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 24.sp, color: Colors.white)
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_rounded, color: AppColors.accentGold, size: 26),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            SizedBox(width: 8.w),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(70.h),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Container(
                width: double.infinity, 
                height: 50.h, 
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15), 
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false, 
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent, 
                  indicator: BoxDecoration(
                    color: AppColors.accentGold, 
                    borderRadius: BorderRadius.circular(25.r),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)) 
                    ],
                  ),
                  labelColor: AppColors.royalGreen, 
                  unselectedLabelColor: Colors.white, 
                  labelStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp),
                  labelPadding: EdgeInsets.zero, 
                  tabs: [
                    const Tab(text: 'طلب مشوار'),
                    const Tab(text: 'رحلات السفر'),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('متابعة طلباتي'),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('trips')
                                .where('userId', isEqualTo: _currentUserId) 
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                return Padding(
                                  padding: EdgeInsets.only(right: 6.w),
                                  child: Container(
                                    padding: EdgeInsets.all(5.w),
                                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                    child: Text(
                                      '${snapshot.data!.docs.length}', 
                                      style: TextStyle(color: Colors.white, fontSize: 11.sp, height: 1.0, fontWeight: FontWeight.bold)
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink(); 
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            PassengerRequestTab(tabController: _tabController),
            
            // 🟢 التابة الجديدة لرحلات السفر
            const PassengerTravelTripsTab(),
            
            BlocProvider(
              create: (context) => PassengerMyRequestsCubit(), 
              child: const PassengerMyRequestsTab(),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 🟢 واجهة رحلات السفر الخاصة بالعميل (سحب الرحلات المنشورة من الكباتن)
// ============================================================================
class PassengerTravelTripsTab extends StatelessWidget {
  const PassengerTravelTripsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryNavy = const Color(0xFF0F172A);

    return Container(
      color: Colors.grey.shade50,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .where('isDriverPost', isEqualTo: true) // 🔒 فلترة رحلات الكباتن فقط
            .where('status', isEqualTo: 'available') // 🔒 المتاحة للحجز فقط
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.royalGreen));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus_filled_outlined, size: 80.sp, color: Colors.grey.shade300),
                  SizedBox(height: 16.h),
                  Text(
                    'لا توجد رحلات سفر متاحة حالياً.', 
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.grey.shade600, fontWeight: FontWeight.bold)
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'الكباتن لسه منزلوش رحلات، جرب تدخل وقت تاني.', 
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade500)
                  ),
                ],
              ),
            );
          }

          // 🟢 الترتيب برمجياً (Dart-side) عشان نتفادى مشاكل الـ Firestore Index
          var trips = snapshot.data!.docs.toList();
          trips.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            Timestamp? timeA = dataA['createdAt'];
            Timestamp? timeB = dataB['createdAt'];
            if (timeA == null && timeB == null) return 0;
            if (timeA == null) return 1;
            if (timeB == null) return -1;
            return timeB.compareTo(timeA); 
          });

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              var tripData = trips[index].data() as Map<String, dynamic>;
              String docId = trips[index].id;

              String travelTimeStr = 'غير محدد';
              if (tripData['travelDate'] != null) {
                DateTime dt = (tripData['travelDate'] as Timestamp).toDate();
                travelTimeStr = DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(dt);
              }

              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: AppColors.accentGold.withValues(alpha: 0.3), width: 1),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // رأس الكارت (اسم الكابتن والسعر)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18.r,
                                backgroundColor: primaryNavy.withValues(alpha: 0.1),
                                child: Icon(Icons.person_pin, color: primaryNavy, size: 20.sp),
                              ),
                              SizedBox(width: 8.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tripData['driverName'] ?? 'كابتن لَمَّة',
                                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp, color: primaryNavy),
                                  ),
                                  Text(
                                    'كابتن موثوق',
                                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: Colors.green),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: AppColors.royalGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              '${tripData['price']} ج.م',
                              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp, color: AppColors.royalGreen),
                            ),
                          ),
                        ],
                      ),
                      
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: const Divider(thickness: 1),
                      ),

                      // تفاصيل المسار
                      Row(
                        children: [
                          Column(
                            children: [
                              Icon(Icons.my_location_rounded, color: Colors.blueAccent, size: 18.sp),
                              Container(width: 2.w, height: 20.h, color: Colors.grey.shade300),
                              Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 18.sp),
                            ],
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tripData['pickupLocation'] ?? '',
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.w600, color: primaryNavy),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  tripData['dropoffLocation'] ?? '',
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.w600, color: primaryNavy),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // وقت التحرك
                      Row(
                        children: [
                          Icon(Icons.access_time_filled_rounded, color: Colors.orange, size: 18.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'موعد التحرك: $travelTimeStr',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // زر الحجز
                      SizedBox(
                        width: double.infinity,
                        height: 45.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryNavy,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                          onPressed: () {
                            _showBookingDialog(context, docId, tripData['driverName'] ?? 'الكابتن');
                          },
                          child: Text(
                            'احجز مقعدك الآن',
                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp, color: AppColors.accentGold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🟢 نافذة تأكيد الحجز (عشان تربطها باللوجيك بتاعك بعدين)
  void _showBookingDialog(BuildContext context, String tripId, String driverName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text('تأكيد الحجز', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppColors.royalGreen, fontSize: 18.sp)),
        content: Text(
          'هل تريد تأكيد حجز مقعد مع $driverName؟ سيتم إرسال طلب للكابتن للموافقة.',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.royalGreen,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // 🔴 هنا اللوجيك بتاع الحجز: مثلاً تضيف الـ UID بتاع العميل في array جوا الرحلة، أو تبعت إشعار للكابتن.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('تم إرسال طلب الحجز للكابتن بنجاح!', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.royalGreen),
              );
            },
            child: const Text('تأكيد وإرسال', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}