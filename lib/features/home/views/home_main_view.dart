// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../cubit/home_cubit.dart';
import 'package:lamma_new/features/profile/presentation/cubit/profile_cubit.dart';

import 'package:lamma_new/features/trips/presentation/pages/trips_services_page.dart';
import 'account_switch_widget.dart'; 

import 'package:lamma_new/core/theme/app_colors.dart'; 
import 'package:lamma_new/features/trips/presentation/widgets/modern_service_card.dart'; 
import 'package:lamma_new/features/trips/presentation/widgets/wide_service_card.dart'; 
import 'package:lamma_new/features/trips/presentation/widgets/travel_service_card.dart';
import 'package:lamma_new/features/home/views/widgets/add_travel_bottom_sheet.dart'; 
import 'package:lamma_new/features/trips/presentation/widgets/fade_slide_animator.dart';
import 'package:lamma_new/features/trips/presentation/widgets/driver_radar_card.dart'; 
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_radar_page.dart'; 

class HomeMainView extends StatefulWidget {
  final String activeRole;
  final String userName;
  final String profileImageUrl;
  final int unreadCount; 
  final int activeOrdersCount; 
  final VoidCallback onOpenNotifications;

  const HomeMainView({
    super.key,
    required this.activeRole,
    required this.userName,
    required this.profileImageUrl,
    required this.unreadCount,
    required this.activeOrdersCount, 
    required this.onOpenNotifications,
  });

  @override
  State<HomeMainView> createState() => _HomeMainViewState();
}

class _HomeMainViewState extends State<HomeMainView> {
  // 🟢 تعريف الستريم هنا بيمنع إعادة إنشائه مع كل عملية Rebuild للشاشة
  late final Stream<QuerySnapshot> _availableTripsStream;

  @override
  void initState() {
    super.initState();
    _availableTripsStream = FirebaseFirestore.instance
        .collection('trips')
        .where('isDriverPost', isEqualTo: true)
        .snapshots();
  }

  void _openAccountSwitchPage(BuildContext mainContext) async {
    final String? newSelectedRole = await Navigator.push<String>(
      mainContext,
      MaterialPageRoute(
        builder: (context) => AccountSwitchWidget(currentRole: widget.activeRole),
      ),
    );

    if (newSelectedRole != null && newSelectedRole != widget.activeRole && mainContext.mounted) {
      mainContext.read<ProfileCubit>().switchUserRole(newSelectedRole);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight, 
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 10.h, bottom: 100.h), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // كارت حالة الحساب تم فصله
              _RoleHeaderCard(
                activeRole: widget.activeRole,
                onSwitchTap: () => _openAccountSwitchPage(context),
              ),
              
              SizedBox(height: 18.h), 
              
              // 🟢 استخدام Classes منفصلة لتوزيع شجرة الودجات وتقليل الـ Rebuilds
              if (widget.activeRole == 'driver')
                _DriverDashboard(
                  activeOrdersCount: widget.activeOrdersCount,
                  userName: widget.userName,
                )
              else if (widget.activeRole == 'lawyer')
                const _LawyerDashboard()
              else
                _ClientDashboard(
                  activeOrdersCount: widget.activeOrdersCount,
                  availableTripsStream: _availableTripsStream,
                ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent, 
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.royalGreen], 
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: AppColors.accentGold, 
            backgroundImage: widget.profileImageUrl.isNotEmpty ? NetworkImage(widget.profileImageUrl) : null,
            child: widget.profileImageUrl.isEmpty ? Icon(Icons.person, color: AppColors.primaryDark, size: 20.sp) : null,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'مرحباً، ${widget.userName}', 
              style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold), 
              overflow: TextOverflow.ellipsis
            )
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Badge(
            isLabelVisible: widget.unreadCount > 0, 
            label: Text(widget.unreadCount.toString(), style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.error,
            child: const Icon(Icons.notifications_none, color: Colors.white),
          ),
          onPressed: widget.onOpenNotifications,
        ),
      ],
    );
  }
}

// ==========================================
// 🟢 الأجزاء المنفصلة (Widgets Extraction)
// ==========================================

class _RoleHeaderCard extends StatelessWidget {
  final String activeRole;
  final VoidCallback onSwitchTap;

  const _RoleHeaderCard({
    required this.activeRole,
    required this.onSwitchTap,
  });

  static String _getRoleArabicName(String role) {
    switch (role) {
      case 'client': return 'عميل'; 
      case 'driver': return 'كابتن'; 
      case 'lawyer': return 'محامي';
      case 'doctor': return 'طبيب';
      case 'nurse': return 'تمريض';
      default: return 'مقدم خدمة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w), 
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.royalGreen], begin: Alignment.topRight, end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(20.r),
        // تم استبدال withOpacity بلون Hex ثابت لتحقيق الـ const
        border: Border.all(color: const Color(0x26FFFFFF), width: 1.w),
        // 🔴 تم إزالة const من الـ list وتمريرها للـ Offset فقط
        boxShadow: [BoxShadow(color: AppColors.royalGreenLight, blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('وضع الحساب الحالي', style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontFamily: 'Cairo')),
              SizedBox(height: 2.h),
              Text(_getRoleArabicName(activeRole), style: TextStyle(color: AppColors.accentGold, fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold, 
              foregroundColor: AppColors.primaryDark,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))
            ),
            onPressed: onSwitchTap,
            icon: Icon(Icons.swap_horiz_rounded, size: 18.sp),
            label: const Text('تبديل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _DriverDashboard extends StatelessWidget {
  final int activeOrdersCount;
  final String userName;

  const _DriverDashboard({
    required this.activeOrdersCount,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FadeSlideAnimator(
          delayMs: 100,
          child: DriverRadarCard(
            activeOrdersCount: activeOrdersCount,
            onRadarTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (newContext) => BlocProvider.value(
                    value: context.read<HomeCubit>(),
                    child: const DriverRadarPage(),
                  )
                )
              );
            },
          ),
        ),
        SizedBox(height: 18.h), 
        FadeSlideAnimator(
          delayMs: 300,
          child: TravelServiceCard(
            onAddTravelTap: () => _showAddTravelBottomSheet(context, userName)
          ),
        ),
      ],
    );
  }

  void _showAddTravelBottomSheet(BuildContext context, String uName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      useSafeArea: true, 
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => AddTravelBottomSheet(userName: uName),
    );
  }
}

class _ClientDashboard extends StatelessWidget {
  final int activeOrdersCount;
  final Stream<QuerySnapshot> availableTripsStream;

  const _ClientDashboard({
    required this.activeOrdersCount,
    required this.availableTripsStream,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FadeSlideAnimator(
          delayMs: 100,
          child: StreamBuilder<QuerySnapshot>(
            stream: availableTripsStream,
            builder: (context, snapshot) {
              int availableTravels = 0;
              if (snapshot.hasData && !snapshot.hasError) {
                String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                availableTravels = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>? ?? {};
                  String status = data['status'] ?? '';
                  String ownerId = data['userId'] ?? data['driverId'] ?? data['uid'] ?? '';
                  return status == 'available' && ownerId != currentUserId;
                }).length;
              }
              int totalAlerts = activeOrdersCount + availableTravels;

              return WideServiceCard(
                title: 'توصيل ورحلات', 
                subtitle: 'اطلب كابتن فوراً لرحلتك', 
                imagePath: 'assets/images/taxi_3d.png', 
                fallbackIcon: Icons.local_taxi_rounded, 
                fallbackColor: AppColors.accentGold,
                badgeCount: totalAlerts,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TripsServicesPage()));
                }
              );
            }
          ),
        ),
        
        SizedBox(height: 18.h), 

        FadeSlideAnimator(
          delayMs: 300,
          child: Row(
            children: [
              Expanded(
                child: ModernServiceCard(
                  title: 'خدمات طبية', 
                  subtitle: 'أطباء وعيادات', 
                  imagePath: 'assets/images/medical_3d.png', 
                  fallbackIcon: Icons.health_and_safety_rounded, 
                  fallbackColor: AppColors.medicalTeal, 
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سيتم تفعيل القسم الطبي قريباً', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.medicalTeal));
                  }
                ),
              ),
              SizedBox(width: 16.w), 
              Expanded(
                child: ModernServiceCard(
                  title: 'خدمات قانونية', 
                  subtitle: 'استشارات وتوكيلات', 
                  imagePath: 'assets/images/law_3d.png', 
                  fallbackIcon: Icons.gavel_rounded, 
                  fallbackColor: AppColors.primaryDark, 
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سيتم تفعيل قسم الخدمات القانونية قريباً', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.primaryDark));
                  }
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 18.h), 

        FadeSlideAnimator(
          delayMs: 500,
          child: WideServiceCard(
            title: 'شوب ومتاجر', 
            subtitle: 'تسوق أفضل المنتجات بسهولة', 
            imagePath: 'assets/images/shop_3d.png', 
            fallbackIcon: Icons.storefront_rounded, 
            fallbackColor: AppColors.royalGreen,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قسم المتاجر تحت الإنشاء', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.royalGreen));
            }
          ),
        ),
      ],
    );
  }
}

class _LawyerDashboard extends StatelessWidget {
  const _LawyerDashboard();

  @override
  Widget build(BuildContext context) {
    return FadeSlideAnimator(
      delayMs: 100,
      child: ModernServiceCard(
        title: 'لوحة التحكم', 
        subtitle: 'الاستشارات والتوكيلات', 
        imagePath: 'assets/images/law_3d.png', 
        fallbackIcon: Icons.gavel_rounded, 
        fallbackColor: AppColors.primaryDark, 
        onTap: () {}
      ),
    );
  }
}