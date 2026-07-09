import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lamma_new/features/home/cubit/home_cubit.dart';
import 'package:lamma_new/features/home/cubit/home_state.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';

import 'driver_radar_tab.dart';
import 'driver_active_trips_tab.dart';
import 'driver_history_tab.dart';

class DriverRadarPage extends StatefulWidget {
  const DriverRadarPage({super.key});

  @override
  State<DriverRadarPage> createState() => _DriverRadarPageState();
}

class _DriverRadarPageState extends State<DriverRadarPage> with SingleTickerProviderStateMixin {
  late TabController _driverTabController;

  @override
  void initState() {
    super.initState();
    _driverTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _driverTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Column(
              children: [
                // 👑 البار العلوي الموحد الفخم (Custom Header)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(top: 50.h, bottom: 8.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1B4332)], 
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B4332).withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // العنوان وزر الرجوع
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 28),
                            ),
                            Text(
                              'لوحة تحكم السائق',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 28), // لضبط المنتصف والتوازن
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // الـ TabBar المدمج
                      TabBar(
                        controller: _driverTabController,
                        indicatorColor: const Color(0xFFD4AF37),
                        labelColor: const Color(0xFFD4AF37),
                        unselectedLabelColor: Colors.white70,
                        labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                        indicatorWeight: 3,
                        dividerColor: Colors.transparent, // إخفاء الخط السفلي الافتراضي
                        tabs: [
                          Tab(
                            text: 'الرادار', 
                            icon: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collection('trips').where('status', isEqualTo: 'pending').snapshots(),
                              builder: (context, snapshot) {
                                int radarCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                return Badge(
                                  isLabelVisible: radarCount > 0,
                                  label: Text(radarCount.toString(), style: const TextStyle(fontFamily: 'Cairo')),
                                  backgroundColor: Colors.redAccent,
                                  child: const Icon(Icons.radar_rounded),
                                );
                              },
                            ),
                          ),
                          Tab(
                            text: 'النشطة', 
                            icon: Badge(
                              isLabelVisible: state.activeOrdersCount > 0,
                              label: Text(state.activeOrdersCount.toString(), style: const TextStyle(fontFamily: 'Cairo')),
                              backgroundColor: Colors.redAccent,
                              child: const Icon(Icons.play_circle_fill_rounded),
                            ),
                          ),
                          const Tab(text: 'السجل', icon: Icon(Icons.history_rounded)), 
                        ],
                      ),
                    ],
                  ),
                ),
                
                // محتوى التابات الداخلي
                Expanded(
                  child: TabBarView(
                    controller: _driverTabController,
                    children: [
                      DriverRadarTab(),
                      BlocProvider(create: (context) => DriverActiveTripsCubit(), child: const DriverActiveTripsTab()),
                      const DriverHistoryTab(),
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
}