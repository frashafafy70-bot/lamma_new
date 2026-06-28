// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 🟢 الإضافات الضرورية لربط الإشعارات بقاعدة البيانات
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../cubit/home_cubit.dart';

// 🟢 استدعاء الكروت وصفحة التبديل الفخمة الجديدة
import 'widgets/service_square_card.dart';
import 'account_switch_widget.dart'; 

// 🟢 تم تحويل الاستدعاءات لمسارات مطلقة (Absolute Paths) لحل خطأ الـ Unused import نهائياً
import 'package:lamma_new/features/trips/presentation/pages/trips_services_page.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_radar_tab.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_active_trips_tab.dart';

// 🟢 استدعاء كيوبت الرحلات النشطة للكابتن عشان نغلف بيه التاب تحت
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

  // دالة فتح صفحة تبديل الحساب (Full Page) واستلام النتيجة
  void _openAccountSwitchPage(BuildContext mainContext) async {
    final String? newSelectedRole = await Navigator.push<String>(
      mainContext,
      MaterialPageRoute(
        builder: (context) => AccountSwitchWidget(currentRole: widget.activeRole),
      ),
    );

    // نتأكد إن اليوزر اختار مهنة جديدة وإن الشاشة لسه موجودة
    if (newSelectedRole != null && newSelectedRole != widget.activeRole && mainContext.mounted) {
      mainContext.read<HomeCubit>().switchUserRole(newSelectedRole);
    }
  }

  // دالة بناء الكروت التفاعلية بناءً على وضع الحساب الحالي
  List<Widget> _buildServiceCards(BuildContext context, String role) {
    if (role == 'captain') {
      // 🚖 كروت وضع الكابتن
      return [
        ServiceSquareCard(
          title: 'لوحة تحكم الكابتن',
          subtitle: 'الرادار والرحلات النشطة لايف',
          icon: Icons.local_shipping_rounded,
          iconColor: const Color(0xFFF3C444), // ذهبي
          onTap: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const CaptainRadarPage()),
            );
          },
        ),
        ServiceSquareCard(
          title: 'رحلاتي السابقة',
          subtitle: 'سجل الرحلات والأرباح',
          icon: Icons.history_rounded,
          iconColor: Colors.green,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('قسم سجل الرحلات قيد الإنشاء', style: TextStyle(fontFamily: 'Cairo')),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ];
    } else if (role == 'lawyer') {
      // ⚖️ كروت وضع المحامي
      return [
        ServiceSquareCard(
          title: 'لوحة التحكم للمحامي',
          subtitle: 'إدارة الاستشارات والتوكيلات',
          icon: Icons.gavel_rounded,
          iconColor: const Color(0xFF131E31),
          onTap: () {},
        ),
      ];
    } else {
      // 👤 كروت وضع العميل (الافتراضي)
      return [
        // 1. كارت خدمات التوصيل والرحلات للعميل
        ServiceSquareCard(
          title: 'توصيل ورحلات', 
          subtitle: 'اطلب كابتن فوراً', 
          icon: Icons.local_taxi_rounded, 
          iconColor: const Color(0xFFF3C444), 
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const TripsServicesPage()));
          },
        ),
        
        // 2. كارت الخدمات القانونية
        ServiceSquareCard(
          title: 'خدمات قانونية', 
          subtitle: 'استشارات وتوكيلات', 
          icon: Icons.gavel_rounded, 
          iconColor: const Color(0xFF131E31), 
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('سيتم تفعيل قسم الخدمات القانونية قريباً', style: TextStyle(fontFamily: 'Cairo')),
                backgroundColor: Color(0xFF131E31),
              ),
            );
          },
        ),

        // 3. كارت المتجر والتسوق
        ServiceSquareCard(
          title: 'شوب ومتاجر', 
          subtitle: 'تسوق منتجاتك', 
          icon: Icons.storefront_rounded, 
          iconColor: Colors.green,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('قسم المتاجر تحت الإنشاء', style: TextStyle(fontFamily: 'Cairo')),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 استخراج معرف المستخدم الحالي لاستخدامه في جلب الإشعارات
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF131E31), // كحلي غامق
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: const Color(0xFFF3C444), // ذهبي
                backgroundImage: widget.profileImageUrl.isNotEmpty ? NetworkImage(widget.profileImageUrl) : null,
                child: widget.profileImageUrl.isEmpty ? const Icon(Icons.person, color: Color(0xFF131E31), size: 20) : null,
              ),
              SizedBox(width: 10.w),
              Text('مرحباً، ${widget.userName}', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            // 🟢 الحل النهائي لجرس الإشعارات الحي في الشاشة الرئيسية
            if (currentUserId.isNotEmpty)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserId)
                    .collection('notifications')
                    .where('isRead', isEqualTo: false) // تتبع الإشعارات غير المقروءة فقط
                    .snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData) {
                    unreadCount = snapshot.data!.docs.length;
                  }

                  return IconButton(
                    icon: Badge(
                      isLabelVisible: unreadCount > 0, // الدائرة الحمراء تظهر فقط لو العدد أكبر من 0
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
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بنر حالة الحساب والتبديل السريع
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(color: const Color(0xFF131E31), borderRadius: BorderRadius.circular(16.r)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('وضع الحساب الحالي', style: TextStyle(color: Colors.grey.shade400, fontSize: 12.sp, fontFamily: 'Cairo')),
                        Text(_getRoleArabicName(widget.activeRole), style: TextStyle(color: const Color(0xFFF3C444), fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3C444), foregroundColor: const Color(0xFF131E31)),
                      onPressed: () => _openAccountSwitchPage(context),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: Text('تبديل الوضع', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24.h),
              Text('الخدمات المتاحة:', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: const Color(0xFF0F172A))),
              SizedBox(height: 16.h),
              
              // شبكة الكروت
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2, 
                  crossAxisSpacing: 14.w, 
                  mainAxisSpacing: 14.h, 
                  childAspectRatio: 1.0,
                  children: [
                    ..._buildServiceCards(context, widget.activeRole),
                    
                    // كارت إدارة الحساب (متاح لجميع الأوضاع دائماً)
                    ServiceSquareCard(
                      title: 'إدارة الحساب', 
                      subtitle: 'تعديل البيانات والمهن', 
                      icon: Icons.manage_accounts_rounded, 
                      iconColor: Colors.blueAccent,
                      onTap: () => _openAccountSwitchPage(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// الصفحة الحاضنة الكاملة لتشغيل التبويبين (الرادار والرحلات النشطة)
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
    _captainTabController = TabController(length: 2, vsync: this);
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
          backgroundColor: const Color(0xFF131E31),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          bottom: TabBar(
            controller: _captainTabController,
            indicatorColor: const Color(0xFFF3C444),
            labelColor: const Color(0xFFF3C444),
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: 'رادار الرحلات', icon: Icon(Icons.radar_rounded)),
              Tab(text: 'الرحلات النشطة', icon: Icon(Icons.play_circle_fill_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _captainTabController,
          children: [
            DriverRadarTab(tabController: _captainTabController),
            // 🟢 التعديل الأهم: تغليف التاب بـ BlocProvider عشان الكيوبت يتقري صح وميضربش شاشة حمراء
            BlocProvider(
              create: (context) => DriverActiveTripsCubit(),
              child: DriverActiveTripsTab(tabController: _captainTabController),
            ),
          ],
        ),
      ),
    );
  }
}