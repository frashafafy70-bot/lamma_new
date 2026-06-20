// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../home/home_page.dart';

// استدعاءات ملفات الكابتن 
import 'driver_tabs/driver_radar_tab.dart';
import 'driver_tabs/driver_post_trip_tab.dart';
import 'driver_tabs/driver_active_trips_tab.dart';

// استدعاءات ملفات العميل 
import 'passenger_tabs/passenger_request_tab.dart';
import 'passenger_tabs/available_travels_tab.dart';
import 'passenger_tabs/passenger_my_requests_tab.dart';

class TripsServicesPage extends StatefulWidget {
  final bool isDriver;
  const TripsServicesPage({super.key, required this.isDriver});

  @override
  State<TripsServicesPage> createState() => _TripsServicesPageState();
}

class _TripsServicesPageState extends State<TripsServicesPage> with SingleTickerProviderStateMixin {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color royalGreen = const Color(0xFF1B4332);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupPushNotifications();
  }

  // --- تهيئة إشعارات الكابتن ---
  void _setupPushNotifications() async {
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    await _saveDeviceToken();
    
    if (widget.isDriver) {
      await FirebaseMessaging.instance.subscribeToTopic('drivers_radar');
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic('drivers_radar');
    }
  }

  Future<void> _saveDeviceToken() async {
    if (currentUserId.isEmpty) return;
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUserId).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error saving token: $e");
    }
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
        title: Text(widget.isDriver ? 'لوحة الكابتن' : 'خدمات', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        backgroundColor: royalGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()))
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15), // تم التعديل هنا
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              labelColor: royalGreen,
              unselectedLabelColor: Colors.white,
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
              tabs: widget.isDriver
                  ? const [Tab(text: 'رادار الطلبات'), Tab(text: 'إضافة رحلة'), Tab(text: 'طلباتي النشطة')]
                  : const [Tab(text: 'طلب مشوار'), Tab(text: 'رحلات السفر'), Tab(text: 'متابعة طلباتي')],
            ),
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(), 
          children: widget.isDriver
              ? [
                  DriverRadarTab(tabController: _tabController), 
                  DriverPostTripTab(tabController: _tabController), 
                  const DriverActiveTripsTab(),
                ]
              : [
                  PassengerRequestTab(tabController: _tabController),
                  const AvailableTravelsTab(),
                  const PassengerMyRequestsTab(),
                ],
        ),
      ),
    );
  }
}