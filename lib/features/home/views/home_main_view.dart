// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../cubit/home_cubit.dart';
import 'widgets/service_square_card.dart';
import 'account_switch_widget.dart'; 

import 'package:lamma_new/features/trips/presentation/pages/trips_services_page.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_radar_tab.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_active_trips_tab.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_history_tab.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';

class HomeMainView extends StatefulWidget {
  final String activeRole;
  final String userName;
  final String profileImageUrl;
  final VoidCallback onOpenNotifications;

  const HomeMainView({
    super.key,
    required this.activeRole,
    required this.userName,
    required this.profileImageUrl,
    required this.onOpenNotifications,
  });

  @override
  State<HomeMainView> createState() => _HomeMainViewState();
}

class _HomeMainViewState extends State<HomeMainView> {
  
  final Color royalGreen = const Color(0xFF1B4332);
  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);

  String _getRoleArabicName(String role) {
    switch (role) {
      case 'customer': return 'عميل';
      case 'captain': return 'كابتن';
      case 'lawyer': return 'محامي';
      case 'doctor': return 'طبيب';
      case 'nurse': return 'تمريض';
      default: return 'مقدم خدمة';
    }
  }

  void _openAccountSwitchPage(BuildContext mainContext) async {
    final String? newSelectedRole = await Navigator.push<String>(
      mainContext,
      MaterialPageRoute(
        builder: (context) => AccountSwitchWidget(currentRole: widget.activeRole),
      ),
    );

    if (newSelectedRole != null && newSelectedRole != widget.activeRole && mainContext.mounted) {
      mainContext.read<HomeCubit>().switchUserRole(newSelectedRole);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        appBar: AppBar(
          backgroundColor: primaryNavy,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: goldAccent, 
                backgroundImage: widget.profileImageUrl.isNotEmpty ? NetworkImage(widget.profileImageUrl) : null,
                child: widget.profileImageUrl.isEmpty ? Icon(Icons.person, color: primaryNavy, size: 20.sp) : null,
              ),
              SizedBox(width: 10.w),
              Expanded(child: Text('مرحباً، ${widget.userName}', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
          actions: [
            if (currentUserId.isNotEmpty)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserId)
                    .collection('notifications')
                    .where('isRead', isEqualTo: false) 
                    .snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData) {
                    unreadCount = snapshot.data!.docs.length;
                  }

                  return IconButton(
                    icon: Badge(
                      isLabelVisible: unreadCount > 0, 
                      label: Text(unreadCount.toString(), style: const TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: Colors.redAccent,
                      child: const Icon(Icons.notifications_none, color: Colors.white),
                    ),
                    onPressed: widget.onOpenNotifications,
                  );
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white), 
                onPressed: widget.onOpenNotifications,
              ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h, bottom: 100.h), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryNavy, royalGreen],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [BoxShadow(color: royalGreen.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('وضع الحساب الحالي', style: TextStyle(color: Colors.white70, fontSize: 13.sp, fontFamily: 'Cairo')),
                        SizedBox(height: 4.h),
                        Text(_getRoleArabicName(widget.activeRole), style: TextStyle(color: goldAccent, fontSize: 22.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: goldAccent, 
                        foregroundColor: primaryNavy,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))
                      ),
                      onPressed: () => _openAccountSwitchPage(context),
                      icon: Icon(Icons.swap_horiz_rounded, size: 20.sp),
                      label: Text('تبديل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 30.h),
              Text('الخدمات المتاحة', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: primaryNavy)),
              SizedBox(height: 16.h),
              
              if (widget.activeRole == 'captain') ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: primaryNavy,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [BoxShadow(color: primaryNavy.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))],
                    border: Border.all(color: goldAccent.withValues(alpha: 0.3), width: 1.w),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12.w, height: 12.w,
                                decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 8)]),
                              ),
                              SizedBox(width: 8.w),
                              Text('متصل وجاهز للطلبات', style: TextStyle(fontFamily: 'Cairo', color: Colors.greenAccent, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Icon(Icons.directions_car_rounded, color: goldAccent, size: 28.sp),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      Text('جاهز لاستقبال مشاوير جديدة؟', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6.h),
                      Text('ادخل على الرادار لمتابعة الطلبات المتاحة في محيطك الآن.', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade400, fontSize: 13.sp)),
                      SizedBox(height: 20.h),
                      SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const CaptainRadarPage()));
                          },
                          child: Text('افتح الرادار الآن 📡', style: TextStyle(fontFamily: 'Cairo', color: primaryNavy, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (widget.activeRole == 'lawyer') ...[
                GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 16.w, mainAxisSpacing: 16.h, childAspectRatio: 0.95,
                  children: [
                    ServiceSquareCard(title: 'لوحة التحكم', subtitle: 'الاستشارات والتوكيلات', icon: Icons.gavel_rounded, iconColor: primaryNavy, onTap: () {}),
                  ],
                ),
              ] else ...[
                GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 16.w, mainAxisSpacing: 16.h, childAspectRatio: 0.95,
                  children: [
                    ServiceSquareCard(title: 'توصيل ورحلات', subtitle: 'اطلب كابتن فوراً', icon: Icons.local_taxi_rounded, iconColor: goldAccent, onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TripsServicesPage()));
                    }),
                    ServiceSquareCard(title: 'خدمات قانونية', subtitle: 'استشارات وتوكيلات', icon: Icons.gavel_rounded, iconColor: primaryNavy, onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('سيتم تفعيل قسم الخدمات القانونية قريباً', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: primaryNavy));
                    }),
                    ServiceSquareCard(title: 'شوب ومتاجر', subtitle: 'تسوق منتجاتك', icon: Icons.storefront_rounded, iconColor: royalGreen, onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('قسم المتاجر تحت الإنشاء', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: royalGreen));
                    }),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CaptainRadarPage extends StatefulWidget {
  const CaptainRadarPage({super.key});

  @override
  State<CaptainRadarPage> createState() => _CaptainRadarPageState();
}

class _CaptainRadarPageState extends State<CaptainRadarPage> with SingleTickerProviderStateMixin {
  late TabController _captainTabController;

  @override
  void initState() {
    super.initState();
    _captainTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _captainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة تحكم الكابتن', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: const Color(0xFF0F172A),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          bottom: TabBar(
            controller: _captainTabController,
            indicatorColor: const Color(0xFFD4AF37),
            labelColor: const Color(0xFFD4AF37),
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'الرادار', icon: Icon(Icons.radar_rounded)),
              Tab(text: 'النشطة', icon: Icon(Icons.play_circle_fill_rounded)),
              Tab(text: 'السجل', icon: Icon(Icons.history_rounded)), 
            ],
          ),
        ),
        body: TabBarView(
          controller: _captainTabController,
          children: [
            DriverRadarTab(tabController: _captainTabController),
            
            BlocProvider(
              create: (context) => DriverActiveTripsCubit(),
              child: const DriverActiveTripsTab(), 
            ),
            
            const DriverHistoryTab(),
          ],
        ),
      ),
    );
  }
}