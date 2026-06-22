// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

import '../auth/presentation/pages/login_page.dart'; 
import '../profile/edit_profile_page.dart'; 

// 💡 استخدام الـ prefixes لحل مشكلة الـ Ambiguous Import وتداخل الأسماء نهائياً
import 'views/home_main_view.dart' as home_v;
import 'views/search_view.dart' as search_v;
import 'views/orders_view.dart' as orders_v;
import 'views/profile_view.dart' as profile_v;

// 🟢 استدعاء الملفات الجيران في نفس المجلد
import 'notification_service.dart'; 
import 'role_registration_sheets.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // المفتاح العام للتحكم في الـ Scaffold وفتح الـ Drawer بأمان من أي مكان
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Color primaryNavy = const Color(0xFF0F172A); 
  final Color goldAccent = const Color(0xFFD4AF37); 

  int _bottomNavIndex = 0;

  String _userName = 'جاري التحميل...';
  String _userEmail = '';
  String _profileImageUrl = '';
  String _activeRole = 'customer'; 
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    // تشغيل الإشعارات الصوتية
    NotificationService.setupNotificationsWithSound();
  }

  Future<void> _loadUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userEmail = user.email ?? '';
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _userName = data['name'] ?? 'مستخدم لَمَّة';
              _profileImageUrl = data.containsKey('profileImage') ? data['profileImage'] : '';
              _activeRole = data.containsKey('activeRole') ? data['activeRole'] : 'customer';
              _isLoadingProfile = false;
            });
          }
        } else { 
          if (mounted) setState(() => _isLoadingProfile = false);
        }
      } catch (e) { 
        if (mounted) setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
  }

  void _openNotifications() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    showModalBottomSheet(
      context: context, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              Text('الإشعارات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy, fontFamily: 'Cairo')),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: goldAccent));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('لا توجد إشعارات حالياً 🔕', style: TextStyle(fontFamily: 'Cairo')));
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var notif = snapshot.data!.docs[index];
                        var data = notif.data() as Map<String, dynamic>;
                        bool isRead = data.containsKey('isRead') ? data['isRead'] : false;

                        if (!isRead) {
                          Future.microtask(() => notif.reference.update({'isRead': true}));
                        }

                        return Dismissible(
                          key: Key(notif.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.delete_rounded, color: Colors.white),
                          ),
                          onDismissed: (direction) async {
                            await notif.reference.delete();
                          },
                          child: Card(
                            elevation: isRead ? 0 : 2,
                            color: isRead ? Colors.transparent : Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), 
                              side: isRead ? BorderSide.none : BorderSide(color: goldAccent.withValues(alpha: 0.3))
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isRead ? Colors.grey.shade200 : goldAccent.withValues(alpha: 0.2), 
                                child: Icon(isRead ? Icons.notifications_rounded : Icons.notifications_active_rounded, color: isRead ? Colors.grey : goldAccent),
                              ), 
                              title: Text(data['title'] ?? 'إشعار', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontFamily: 'Cairo', fontSize: 14)), 
                              subtitle: Text(data['body'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey.shade700)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () async {
                                  await notif.reference.delete();
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: CircularProgressIndicator(color: goldAccent)));
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (!mounted) return; 
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال رابط تغيير كلمة المرور 📧', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
      } catch (e) {
        if (!mounted) return; 
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
      }
    }
  }

  void _confirmPasswordReset() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
      title: Row(
        textDirection: TextDirection.rtl, 
        children: [
          Icon(Icons.lock_reset_rounded, color: primaryNavy), 
          const SizedBox(width: 8), 
          const Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        ],
      ), 
      content: const Text('هل تريد إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14), textDirection: TextDirection.rtl), 
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))), 
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, foregroundColor: Colors.white), 
          onPressed: () async { 
            Navigator.pop(ctx); 
            _sendPasswordResetEmail(); 
          }, 
          child: const Text('إرسال الرابط', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  void _showSupportDialog() {
    final TextEditingController complaintCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
      title: Row(
        textDirection: TextDirection.rtl, 
        children: [
          const Icon(Icons.support_agent_rounded, color: Colors.orange), 
          const SizedBox(width: 8), 
          const Text('الدعم الفني والشكاوى', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ), 
      content: TextField(
        controller: complaintCtrl, 
        maxLines: 4, 
        textDirection: TextDirection.rtl, 
        decoration: InputDecoration(
          hintText: 'اكتب شكوتك، مشكلتك، أو مقترحك هنا...', 
          hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13), 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryNavy, width: 2)),
        ),
      ), 
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))), 
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, foregroundColor: Colors.white), 
          onPressed: () async { 
            if (complaintCtrl.text.trim().isEmpty) return; 
            Navigator.pop(ctx); 
            showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: CircularProgressIndicator(color: goldAccent))); 
            try { 
              User? user = FirebaseAuth.instance.currentUser; 
              await FirebaseFirestore.instance.collection('support_tickets').add({
                'uid': user?.uid, 
                'name': _userName, 
                'email': _userEmail, 
                'message': complaintCtrl.text.trim(), 
                'status': 'open', 
                'timestamp': FieldValue.serverTimestamp(),
              }); 
              if (!mounted) return; 
              Navigator.pop(context); 
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال رسالتك للدعم الفني بنجاح ✅', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green)); 
            } catch(e) { 
              if (!mounted) return; 
              Navigator.pop(context); 
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الإرسال ❌', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red)); 
            } 
          }, 
          child: const Text('إرسال الدعم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  Future<void> _switchUserRole(String newRole) async {
    Navigator.pop(context); 

    if (_activeRole == newRole) {
      return; 
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (_) => Center(child: CircularProgressIndicator(color: goldAccent))
    );

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      var userData = userDoc.data() as Map<String, dynamic>? ?? {};
      String fullName = userData['name'] ?? 'مستخدم';
      bool hasProfile = userData.containsKey('profiles') && (userData['profiles'] as Map).containsKey(newRole);

      if (!hasProfile && newRole != 'customer') {
        if (mounted) { 
          Navigator.pop(context); 
          
          if (newRole == 'captain') {
            RoleRegistrationSheets.showCaptainRegistration(context, user.uid, fullName, (role) => setState(() => _activeRole = role));
          } else if (newRole == 'lawyer') {
            RoleRegistrationSheets.showLawyerRegistration(context, user.uid, fullName, (role) => setState(() => _activeRole = role));
          } else if (newRole == 'doctor') {
            RoleRegistrationSheets.showDoctorRegistration(context, user.uid, fullName, (role) => setState(() => _activeRole = role));
          } else if (newRole == 'nurse') {
            RoleRegistrationSheets.showNurseRegistration(context, user.uid, fullName, (role) => setState(() => _activeRole = role));
          }
        }
        return; 
      }
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'activeRole': newRole}, 
        SetOptions(merge: true)
      );

      if (!mounted) return; 
      Navigator.pop(context); 

      setState(() { 
        _activeRole = newRole; 
      });

      String roleNameAr = newRole == 'customer' ? 'العميل' : 
                          newRole == 'captain' ? 'الكابتن' : 
                          newRole == 'lawyer' ? 'المحامي' : 
                          newRole == 'doctor' ? 'الطبيب' : 'التمريض';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم التحويل لوضع: $roleNameAr بنجاح ✅', style: const TextStyle(fontFamily: 'Cairo')), 
          backgroundColor: Colors.green
        )
      );
    } catch (e) { 
      if (mounted) { 
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التحويل: $e', style: const TextStyle(fontFamily: 'Cairo')))
        ); 
      } 
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    switch (_bottomNavIndex) {
      case 0: 
        bodyContent = home_v.HomeMainView(
          userName: _userName, 
          activeRole: _activeRole, 
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(), 
          onOpenNotifications: _openNotifications
        ); 
        break;
      case 1: 
        bodyContent = search_v.SearchView() as Widget; 
        break;
      case 2: 
        bodyContent = orders_v.OrdersView(activeRole: _activeRole); 
        break;
      case 3: 
        bodyContent = profile_v.ProfileView(
          isLoadingProfile: _isLoadingProfile, profileImageUrl: _profileImageUrl, userName: _userName, userEmail: _userEmail,
          onEditProfile: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())); _loadUserProfile(); },
          onPasswordReset: _confirmPasswordReset, onSupport: _showSupportDialog, onLogout: _logout,
        ); 
        break;
      default: 
        bodyContent = home_v.HomeMainView(
          userName: _userName, 
          activeRole: _activeRole, 
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(), 
          onOpenNotifications: _openNotifications
        );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      drawer: Directionality(
        textDirection: TextDirection.rtl,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: primaryNavy), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Icon(Icons.account_circle, size: 60, color: goldAccent), 
                    const SizedBox(height: 10), 
                    const Text('تبديل وضع الحساب', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')), 
                    Text('الوضع الحالي: ${_activeRole == 'customer' ? 'عميل' : _activeRole == 'lawyer' ? 'محامي' : _activeRole == 'captain' ? 'كابتن' : 'مقدم خدمة'}', style: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontFamily: 'Cairo'))
                  ],
                ),
              ),
              ListTile(leading: const Icon(Icons.person_rounded, color: Colors.grey), title: const Text('التحويل لوضع العميل 👤', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), onTap: () => _switchUserRole('customer')),
              ListTile(leading: const Icon(Icons.local_taxi_rounded, color: Colors.blueAccent), title: const Text('التحويل لوضع الكابتن 🚖', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), onTap: () => _switchUserRole('captain')),
              ListTile(leading: Icon(Icons.gavel_rounded, color: goldAccent), title: const Text('التحويل لوضع المحامي ⚖️', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), onTap: () => _switchUserRole('lawyer')),
              ListTile(leading: const Icon(Icons.medical_services_rounded, color: Colors.green), title: const Text('التحويل لوضع الطبيب 👨‍⚕️', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), onTap: () => _switchUserRole('doctor')),
              ListTile(leading: const Icon(Icons.health_and_safety_rounded, color: Colors.blue), title: const Text('التحويل لوضع التمريض 🩺', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), onTap: () => _switchUserRole('nurse')),
            ],
          ),
        ),
      ),
      body: Directionality(textDirection: TextDirection.rtl, child: bodyContent),
      bottomNavigationBar: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, -5))]),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            child: BottomNavigationBar(
              currentIndex: _bottomNavIndex, 
              onTap: (index) { setState(() { _bottomNavIndex = index; }); }, 
              type: BottomNavigationBarType.fixed, 
              backgroundColor: Colors.white, 
              selectedItemColor: goldAccent, 
              unselectedItemColor: Colors.grey.shade400, 
              selectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12), 
              unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'), 
                BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'البحث'), 
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'الطلبات'), 
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'الحساب')
              ],
            ),
          ),
        ),
      ),
    );
  }
}