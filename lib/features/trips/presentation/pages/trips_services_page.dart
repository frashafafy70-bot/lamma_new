import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/presentation/pages/passenger_tabs/passenger_request_tab.dart';

class TripsServicesPage extends StatefulWidget {
  const TripsServicesPage({super.key});

  @override
  State<TripsServicesPage> createState() => _TripsServicesPageState();
}

class _TripsServicesPageState extends State<TripsServicesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
                          // 🟢 العداد الأحمر الحي المربوط بفايربيز
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('trips')
                                // .where('userId', isEqualTo: currentUserId) // مهم تفعل دي مستقبلاً
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
                              return const SizedBox.shrink(); // لو مفيش طلبات يخفي العداد
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
            const Center(child: Text('رحلات السفر - قريباً', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            _buildMyRequestsTab(),
          ],
        ),
      ),
    );
  }

  // 🟢 ويدجت متابعة طلباتي (مربوطة بـ Firebase)
  Widget _buildMyRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          // .where('userId', isEqualTo: currentUserId) 
          .orderBy('createdAt', descending: true) 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentGold));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, size: 70.sp, color: Colors.grey.shade300),
                SizedBox(height: 16.h),
                Text('لا توجد طلبات نشطة حالياً', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: requests.length, 
          itemBuilder: (context, index) {
            var requestData = requests[index].data() as Map<String, dynamic>;
            String docId = requests[index].id; 
            
            Timestamp? timestamp = requestData['createdAt'];
            DateTime date = timestamp != null ? timestamp.toDate() : DateTime.now();
            final dateStr = "${date.day}/${date.month}/${date.year}";
            String hour = date.hour > 12 ? (date.hour - 12).toString().padLeft(2, '0') : date.hour.toString().padLeft(2, '0');
            if (hour == '00') hour = '12'; 
            String amPm = date.hour >= 12 ? "م" : "ص";
            String minute = date.minute.toString().padLeft(2, '0');
            final timeStr = "$hour:$minute $amPm";

            String status = requestData['status'] ?? 'في انتظار قبول الكباتن...';
            String category = requestData['tripCategory'] ?? 'توصيل';

            return Container(
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4))
                ],
                border: Border.all(color: AppColors.royalGreen.withValues(alpha: 0.08)), 
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(color: AppColors.accentGold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16.r)),
                          child: Icon(category == 'طلبات' ? Icons.shopping_bag_rounded : Icons.local_taxi_rounded, color: AppColors.accentGold, size: 28.sp),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'طلب $category',
                                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 15.sp, color: AppColors.royalGreen),
                              ),
                              SizedBox(height: 6.h),
                              Row(
                                children: [
                                  Icon(Icons.calendar_month_rounded, size: 14.sp, color: Colors.grey.shade400),
                                  SizedBox(width: 4.w),
                                  Text(dateStr, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                  SizedBox(width: 12.w),
                                  Icon(Icons.access_time_rounded, size: 14.sp, color: Colors.grey.shade400),
                                  SizedBox(width: 4.w),
                                  Text(timeStr, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          status,
                          style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade500, fontSize: 12.sp, fontWeight: FontWeight.w600),
                        ),
                        InkWell(
                          onTap: () async {
                            try {
                              await FirebaseFirestore.instance.collection('trips').doc(docId).delete();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم إلغاء الطلب بنجاح!', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
                                    backgroundColor: Colors.red.shade400,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                  )
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('حدث خطأ أثناء الإلغاء', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red)
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12.r)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 16.sp),
                                SizedBox(width: 4.w),
                                Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.red.shade400, fontWeight: FontWeight.bold, fontSize: 12.sp))
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      }
    );
  }
}