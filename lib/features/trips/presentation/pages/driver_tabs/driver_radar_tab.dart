import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import '../../../cubit/driver/driver_radar_cubit.dart';
import '../../../cubit/driver/driver_radar_state.dart';

// 🟢 الاستدعاءات الجديدة للكارت الذكي والموديل الخاص بالرحلة
import '../../widgets/smart_trip_card.dart';
import '../../../data/models/trip_model.dart';

class DriverRadarTab extends StatelessWidget {
  final TabController tabController;
  const DriverRadarTab({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final Color royalGreen = const Color(0xFF1B4332);
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return BlocProvider(
      create: (context) => DriverRadarCubit()..startListeningToRadar(),
      child: BlocBuilder<DriverRadarCubit, DriverRadarState>(
        builder: (context, state) {
          if (state is DriverRadarLoading || state is DriverRadarInitial) {
            return Center(child: CircularProgressIndicator(color: royalGreen));
          }

          if (state is DriverRadarError) {
            return Center(
              child: Text(state.message, style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 16.sp)),
            );
          }

          if (state is DriverRadarLoaded) {
            if (state.trips.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.radar_outlined, size: 60.sp, color: Colors.grey.shade400),
                    SizedBox(height: 10.h),
                    Text('لا توجد طلبات حالياً', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.only(top: 16.h, bottom: 100.h), // مساحة عشان الاسكرول
              itemCount: state.trips.length,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemBuilder: (context, index) {
                var doc = state.trips[index];
                var data = doc.data() as Map<String, dynamic>;
                
                // 🟢 تحويل البيانات لموديل الرحلة عشان الكارت الذكي يقراها
                TripModel tripModel = TripModel.fromMap(data, doc.id);
                
                return SmartTripCard(
                  trip: tripModel,
                  isDriver: true, // 🟢 هنا بنعرف الكارت إن اللي فاتح الشاشة دي هو الكابتن
                  currentUserId: currentUserId,
                  onChatPressed: () {
                    // الانتقال لشاشة الشات (تأكد إن الراوت ده متعرف عندك)
                    // Navigator.pushNamed(context, '/trip_chat', arguments: doc.id);
                  },
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}