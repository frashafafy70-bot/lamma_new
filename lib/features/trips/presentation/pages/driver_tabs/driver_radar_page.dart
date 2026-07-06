import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
            appBar: AppBar(
              title: const Text('لوحة تحكم السائق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: const Color(0xFF0F172A),
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
              bottom: TabBar(
                controller: _driverTabController,
                indicatorColor: const Color(0xFFD4AF37),
                labelColor: const Color(0xFFD4AF37),
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
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
            ),
            body: TabBarView(
              controller: _driverTabController,
              children: [
                DriverRadarTab(),
                BlocProvider(create: (context) => DriverActiveTripsCubit(), child: const DriverActiveTripsTab()),
                const DriverHistoryTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}