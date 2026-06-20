// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../home/home_page.dart';
import 'trip_chat_page.dart'; // تأكد من مسار صفحة الشات

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

  void _setupPushNotifications() async {
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    await _saveDeviceToken();
    
    if (widget.isDriver) {
      await FirebaseMessaging.instance.subscribeToTopic('drivers_radar');
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic('drivers_radar');
    }

    // التوجيه الذكي عند الضغط على الإشعار والتطبيق مفتوح في الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['type'] == 'chat' && message.data['tripId'] != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: message.data['tripId'])));
      } else if (message.data['type'] == 'new_request' && widget.isDriver) {
        _tabController.animateTo(0); // يروح للرادار
      }
    });
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

  // دالة لرسم التاب مع نقطة حمراء (Badge) لو فيه داتا
  Widget _buildBadgeTab(String text, Stream<QuerySnapshot> stream) {
    return Tab(
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          bool hasItems = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(text, style: const TextStyle(fontSize: 12)),
              if (hasItems) ...[
                const SizedBox(width: 4),
                Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                )
              ]
            ],
          );
        },
      ),
    );
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
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              labelColor: royalGreen,
              unselectedLabelColor: Colors.white,
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              tabs: widget.isDriver
                  ? [
                      _buildBadgeTab('رادار الطلبات', FirebaseFirestore.instance.collection('trips').where('status', isEqualTo: 'pending').where('isDriverPost', isEqualTo: false).snapshots()),
                      const Tab(text: 'إضافة رحلة'),
                      _buildBadgeTab('طلباتي النشطة', FirebaseFirestore.instance.collection('trips').where('driverId', isEqualTo: currentUserId).where('status', whereIn: ['negotiating', 'accepted']).snapshots()),
                    ]
                  : [
                      const Tab(text: 'طلب مشوار'),
                      const Tab(text: 'رحلات السفر'),
                      _buildBadgeTab('متابعة طلباتي', FirebaseFirestore.instance.collection('trips').where('passengerId', isEqualTo: currentUserId).where('status', whereIn: ['negotiating', 'accepted']).snapshots()),
                    ],
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