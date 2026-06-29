import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    int activeRequestsCount = 0; 

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        // 🟢 الكيبورد هترفع الشاشة بشكل طبيعي جداً دلوقتي
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
                          if (activeRequestsCount > 0) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.all(5.w),
                              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                              child: Text(
                                '$activeRequestsCount', 
                                style: TextStyle(color: Colors.white, fontSize: 11.sp, height: 1.0, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ]
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

  Widget _buildMyRequestsTab() {
    final now = DateTime.now();
    final dateStr = "${now.day}/${now.month}/${now.year}";
    String hour = now.hour > 12 ? (now.hour - 12).toString().padLeft(2, '0') : now.hour.toString().padLeft(2, '0');
    if (hour == '00') hour = '12'; 
    String amPm = now.hour >= 12 ? "م" : "ص";
    String minute = now.minute.toString().padLeft(2, '0');
    final timeStr = "$hour:$minute $amPm";

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 3, 
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), 
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              )
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
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Icon(Icons.local_taxi_rounded, color: AppColors.accentGold, size: 28.sp),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'طلب مشوار #${index + 1024}',
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.royalGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r), 
                      ),
                      child: Text(
                        'نشط',
                        style: TextStyle(fontFamily: 'Cairo', color: AppColors.royalGreen, fontWeight: FontWeight.w800, fontSize: 11.sp),
                      ),
                    )
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
                      'في انتظار قبول الكباتن...',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade500, fontSize: 12.sp, fontWeight: FontWeight.w600),
                    ),
                    InkWell(
                      onTap: () {
                        // كود المسح
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 16.sp),
                            SizedBox(width: 4.w),
                            Text(
                              'إلغاء',
                              style: TextStyle(fontFamily: 'Cairo', color: Colors.red.shade400, fontWeight: FontWeight.bold, fontSize: 12.sp),
                            )
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
}