import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// استدعاء المكون المشترك
import '../widgets/service_square_card.dart';

// مسارات الصفحات
import '../../legal/presentation/pages/legal_services_page.dart';
import '../../medical/medical_services_page.dart';
import '../../trips/presentation/pages/trips_services_page.dart';

class HomeMainView extends StatelessWidget {
  final String userName;
  final String activeRole;
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenNotifications;

  const HomeMainView({
    super.key,
    required this.userName,
    required this.activeRole,
    required this.onOpenDrawer,
    required this.onOpenNotifications,
  });

  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryNavy, const Color(0xFF1E293B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
            border: Border(bottom: BorderSide(color: goldAccent, width: 4.5)),
            boxShadow: [BoxShadow(color: goldAccent.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 5))],
          ),
          child: Stack(
            children: [
              Positioned(right: -30, top: -20, child: Icon(Icons.mosque_rounded, size: 180, color: Colors.white.withValues(alpha: 0.03))),
              Positioned(left: -40, bottom: -30, child: Icon(Icons.brightness_high_rounded, size: 150, color: Colors.white.withValues(alpha: 0.03))),
              
              Padding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 35, left: 20, right: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                          onPressed: onOpenDrawer,
                        ),
                        Row(
                          children: [
                            const Text('منصة لَمَّة الشاملة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                            const SizedBox(width: 8),
                            Icon(Icons.grid_view_rounded, color: goldAccent, size: 24),
                          ],
                        ),
                        
                        // 🔔 نظام الإشعارات (الجرس)
                        userId == null 
                        ? IconButton(icon: const Icon(Icons.notifications_active_rounded, color: Colors.white), onPressed: onOpenNotifications)
                        : StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .collection('notifications')
                                .where('isRead', isEqualTo: false)
                                .snapshots(),
                            builder: (context, snapshot) {
                              // لو مفيش بيانات أو فيه خطأ، يفضل الجرس عادي بدون بادج
                              int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                              
                              return IconButton(
                                icon: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 26),
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: -2, top: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                          child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                        ),
                                      )
                                  ],
                                ),
                                onPressed: onOpenNotifications, 
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Text('مرحباً بك يا $userName،', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    Text(
                      activeRole == 'customer' ? 'كل خدماتك في مكان واحد 🚀' : 'لوحة تحكم المحترفين جاهزة 💼', 
                      textAlign: TextAlign.center, 
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(20),
            crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85, 
            children: [
              ServiceSquareCard(title: 'الاستشارات القانونية', subtitle: 'محامون معتمدون', icon: Icons.gavel_rounded, iconColor: goldAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LegalServicesPage(isLawyer: activeRole == 'lawyer')))),
              ServiceSquareCard(title: 'الخدمات الطبية', subtitle: 'رعاية صحية', icon: Icons.medical_services_rounded, iconColor: Colors.green.shade600, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicalServicesPage(medicalRole: (activeRole == 'doctor' || activeRole == 'nurse') ? 'provider' : 'patient')))),
              ServiceSquareCard(title: 'التوصيل الذكي', subtitle: 'رحلات وطلبات', icon: Icons.local_taxi_rounded, iconColor: Colors.blue.shade600, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripsServicesPage(isDriver: activeRole == 'captain')))),
              ServiceSquareCard(title: 'الخدمات العامة', subtitle: 'خدمات منوعة', icon: Icons.dashboard_customize_rounded, iconColor: Colors.purple.shade500, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قريباً 🛠️', style: TextStyle(fontFamily: 'Cairo')))))
            ],
          ),
        ),
      ],
    );
  }
}