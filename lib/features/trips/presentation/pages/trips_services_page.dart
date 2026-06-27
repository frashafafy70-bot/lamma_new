// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 🟢 استدعاء BlocProvider

// استدعاء التاب الأول
import 'passenger_tabs/passenger_request_tab.dart'; 
// استدعاء التاب الثالث
import 'package:lamma_new/features/trips/presentation/pages/passenger_tabs/passenger_my_requests_tab.dart'; 
// 🟢 استدعاء الكيوبت عشان نزوده في الشجرة
import 'package:lamma_new/features/trips/cubit/passenger/passenger_my_requests_cubit.dart';

class TripsServicesPage extends StatefulWidget {
  const TripsServicesPage({super.key});

  @override
  State<TripsServicesPage> createState() => _TripsServicesPageState();
}

class _TripsServicesPageState extends State<TripsServicesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color primaryGreen = const Color(0xFF1A3B2A);
  final Color accentGold = const Color(0xFFD4AF37);
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  int _requestTabNotifications = 0;   
  int _travelTabNotifications = 0;    

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          if (_tabController.index == 0) _requestTabNotifications = 0;
          if (_tabController.index == 1) _travelTabNotifications = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: Text('خدمات التوصيل', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.sp)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: accentGold, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.home_filled, color: accentGold, size: 22.sp),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentGold,
          indicatorWeight: 3.h,
          labelColor: accentGold,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp),
          unselectedLabelStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 13.sp),
          tabs: [
            Tab(child: Badge(isLabelVisible: _requestTabNotifications > 0, label: Text('$_requestTabNotifications'), backgroundColor: Colors.redAccent, child: const Text('طلب مشوار'))),
            Tab(child: Badge(isLabelVisible: _travelTabNotifications > 0, label: Text('$_travelTabNotifications'), backgroundColor: Colors.redAccent, child: const Text('رحلات السفر'))),
            
            Tab(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('trips')
                    .where('passengerId', isEqualTo: currentUserId)
                    .where('status', whereIn: ['pending', 'negotiating', 'accepted', 'arrived', 'picked_up'])
                    .snapshots(),
                builder: (context, snapshot) {
                  int activeCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return Badge(
                    isLabelVisible: activeCount > 0,
                    label: Text(activeCount.toString()),
                    backgroundColor: Colors.redAccent,
                    child: const Text('متابعة طلباتي'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: TabBarView(
          controller: _tabController,
          children: [
            PassengerRequestTab(tabController: _tabController),
            Center(child: Text('شاشة رحلات السفر المتاحة 🗺️', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: primaryGreen, fontWeight: FontWeight.bold))),
            
            // 🟢 التعديل هنا: تغليف التاب بـ BlocProvider عشان الشاشة تقرأ الكيوبت وماتضربش
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