// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:lamma_new/features/home/cubit/home_cubit.dart';
import 'package:lamma_new/features/home/cubit/home_state.dart';
import 'package:lamma_new/features/auth/presentation/pages/login_page.dart'; 
import 'package:lamma_new/features/profile/edit_profile_page.dart'; 
import 'package:lamma_new/features/home/views/home_main_view.dart';
import 'package:lamma_new/features/home/views/search_view.dart';
import 'package:lamma_new/features/home/views/orders_view.dart';
import 'package:lamma_new/features/home/views/profile_view.dart';
import 'package:lamma_new/features/home/role_registration_sheets.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryNavy = const Color(0xFF0F172A); 
  final Color goldAccent = const Color(0xFFD4AF37); 
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  late HomeCubit _homeCubit;
  
  // 🟢 مستمع الرحلات اللحظي لمنع ضياع إشعارات الطلبات والتفاوض
  StreamSubscription<QuerySnapshot>? _tripsSubscription;
  bool _isFirstTripsLoad = true;

  @override
  void initState() {
    super.initState();
    _homeCubit = HomeCubit()..loadUserProfile();
    _setupNotificationsWithSound();
    _startLiveTripsNotificationListener(); 
  }

  @override
  void dispose() {
    _tripsSubscription?.cancel(); 
    _homeCubit.close();
    super.dispose();
  }

  Future<void> _setupNotificationsWithSound() async {
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true, provisional: false);
    
    const AndroidNotificationChannel finalSoundChannel = AndroidNotificationChannel(
      'lamma_final_sound', 
      'تنبيهات لمة الفورية', 
      description: 'قناة الرحلات العاجلة', 
      importance: Importance.max, 
      playSound: true,
    );
    
    final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(finalSoundChannel);
    }
    
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'), 
      iOS: DarwinInitializationSettings(requestSoundPermission: true, requestBadgePermission: true, requestAlertPermission: true),
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("✅ تم الضغط على الإشعار: ${response.payload}");
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        _triggerPopupWithSound(notification.title ?? '', notification.body ?? '');
      }
    });
  }

  void _triggerPopupWithSound(String title, String body) {
    flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF, 
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'lamma_final_sound',
          'تنبيهات لمة الفورية',
          channelDescription: 'قناة الرحلات العاجلة',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ============================================================================
  // 🟢 المستمع الذكي للطلبات اللحظية (تم حل مشكلة الأخطاء الحمراء نهائياً هنا)
  // ============================================================================
  void _startLiveTripsNotificationListener() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _tripsSubscription = FirebaseFirestore.instance
        .collection('trips')
        .snapshots()
        .listen((snapshot) {
      
      if (_isFirstTripsLoad) {
        _isFirstTripsLoad = false;
        return;
      }

      for (var change in snapshot.docChanges) {
        // 🟢 السطر الذكي للحماية من الأخطاء والتحذيرات
        var rawData = change.doc.data();
        if (rawData is! Map<String, dynamic>) continue; 

        String status = rawData['status'] ?? 'pending';
        String category = rawData['tripCategory'] ?? 'مشوار';

        // 👤 إشعارات الراكب (العميل)
        if (change.type == DocumentChangeType.modified && rawData['passengerId'] == userId) {
          if (status == 'accepted') {
            _triggerPopupWithSound('تم قبول طلبك! 🚖', 'وافق الكابتن على طلب الـ $category وهو في طريقه إليك الآن.');
          } else if (status == 'negotiating') {
            _triggerPopupWithSound('عرض سعر جديد! 💰', 'قدم الكابتن عرض سعر قيمته ${rawData['driverOfferedPrice'] ?? rawData['price']} ج.م لطلبك.');
          } else if (status == 'arrived') {
            _triggerPopupWithSound('وصل الكابتن! 📍', 'الكابتن منتظرك الآن في نقطة الانطلاق المتفق عليها.');
          } else if (status == 'completed') {
            _triggerPopupWithSound('وصلت بالسلامة ✅', 'تم إنهاء رحلتك بنجاح. شكراً لاستخدامك لمة!');
          }
        }
        
        // 🚖 إشعارات الكابتن
        if (change.type == DocumentChangeType.added && status == 'pending' && rawData['passengerId'] != userId) {
          if (_homeCubit.state.activeRole == 'captain') {
            _triggerPopupWithSound('طلب مشوار جديد متاح! 🗺️', 'يوجد طلب $category جديد قيد الانتظار على الرادار الآن.');
          }
        }
      }
    });
  }

  void _openNotifications(BuildContext context) {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('جاري تحميل بياناتك، يرجى المحاولة بعد قليل...', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bottomSheetContext) {
        return SizedBox(
          height: MediaQuery.of(bottomSheetContext).size.height * 0.65, 
          child: Padding(
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
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('لا توجد إشعارات حالياً 🔕', style: TextStyle(fontFamily: 'Cairo', fontSize: 16)));
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var notif = snapshot.data!.docs[index];
                          if (notif['isRead'] == false) notif.reference.update({'isRead': true});
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: goldAccent.withValues(alpha: 0.2), child: Icon(Icons.notifications_active, color: goldAccent)), 
                            title: Text(notif['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')), 
                            subtitle: Text(notif['body'] ?? '', style: const TextStyle(fontFamily: 'Cairo')),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeCubit,
      child: BlocListener<HomeCubit, HomeState>(
        listenWhen: (previous, current) => previous.actionStatus != current.actionStatus,
        listener: (context, state) {
          if (state.actionStatus == HomeActionStatus.success && state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.successMessage!, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
            context.read<HomeCubit>().clearActionStatus(); 
          }
          else if (state.actionStatus == HomeActionStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
            context.read<HomeCubit>().clearActionStatus(); 
          }
          else if (state.actionStatus == HomeActionStatus.registrationRequired) {
            final role = state.pendingRegistrationRole;
            final fullName = state.userName;
            final cubit = context.read<HomeCubit>();
            cubit.clearActionStatus(); 

            if (role == 'captain') RoleRegistrationSheets.showCaptain(context, cubit, fullName);
            else if (role == 'lawyer') RoleRegistrationSheets.showLawyer(context, cubit, fullName);
            else if (role == 'doctor') RoleRegistrationSheets.showDoctor(context, cubit, fullName);
            else if (role == 'nurse') RoleRegistrationSheets.showNurse(context, cubit, fullName);
          }
        },
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            Widget bodyContent;
            switch (state.bottomNavIndex) {
              case 0: 
                bodyContent = HomeMainView(
                  userName: state.userName, 
                  activeRole: state.activeRole, 
                  profileImageUrl: state.profileImageUrl,
                  onOpenNotifications: () => _openNotifications(context) 
                ); 
                break;
              case 1: bodyContent = SearchView(activeRole: state.activeRole); break;
              case 2: bodyContent = OrdersView(activeRole: state.activeRole); break;
              case 3: 
                bodyContent = ProfileView(
                  activeRole: state.activeRole,
                  isLoadingProfile: state.status == HomeStatus.loading,
                  profileImageUrl: state.profileImageUrl,
                  userName: state.userName,
                  userEmail: state.userEmail,
                  onEditProfile: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage())),
                  onPasswordReset: () => _confirmPasswordReset(context),
                  onSupport: () => _showSupportDialog(context, state.userName, state.userEmail),
                  onLogout: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
                  },
                ); 
                break;
              default: 
                bodyContent = HomeMainView(
                  userName: state.userName, 
                  activeRole: state.activeRole, 
                  profileImageUrl: state.profileImageUrl,
                  onOpenNotifications: () => _openNotifications(context)
                );
            }

            return Stack(
              children: [
                Scaffold(
                  key: _scaffoldKey,
                  backgroundColor: Colors.grey.shade50,
                  body: Directionality(textDirection: TextDirection.rtl, child: bodyContent),
                  bottomNavigationBar: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Container(
                      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, -5))]),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                        child: BottomNavigationBar(
                          currentIndex: state.bottomNavIndex, 
                          onTap: (index) => context.read<HomeCubit>().changeTab(index), 
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
                ),
                
                if (state.actionStatus == HomeActionStatus.loading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.7), 
                    child: Center(
                      child: CircularProgressIndicator(color: goldAccent),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _confirmPasswordReset(BuildContext pageContext) {
    showDialog(context: pageContext, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
      title: Row(textDirection: TextDirection.rtl, children: [Icon(Icons.lock_reset_rounded, color: primaryNavy), const SizedBox(width: 8), const Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))]), 
      content: const Text('هل تريد إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14), textDirection: TextDirection.rtl), 
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))), 
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, foregroundColor: Colors.white), onPressed: () { Navigator.pop(ctx); pageContext.read<HomeCubit>().sendPasswordResetEmail(); }, child: const Text('إرسال الرابط', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
      ],
    ));
  }

  void _showSupportDialog(BuildContext pageContext, String currentUserName, String currentUserEmail) {
    final TextEditingController complaintCtrl = TextEditingController();
    showDialog(context: pageContext, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
      title: Row(textDirection: TextDirection.rtl, children: [const Icon(Icons.support_agent_rounded, color: Colors.orange), const SizedBox(width: 8), const Text('الدعم الفني والشكاوى', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16))]), 
      content: TextField(
        controller: complaintCtrl, maxLines: 4, textDirection: TextDirection.rtl, 
        decoration: InputDecoration(hintText: 'اكتب شكوتك، مشكلتك، أو مقترحك هنا...', hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryNavy, width: 2))),
      ), 
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))), 
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, foregroundColor: Colors.white), 
          onPressed: () async { 
            if (complaintCtrl.text.trim().isEmpty) return; 
            Navigator.pop(ctx); 
            try { 
              User? user = FirebaseAuth.instance.currentUser; 
              await FirebaseFirestore.instance.collection('support_tickets').add({'uid': user?.uid, 'name': currentUserName, 'email': currentUserEmail, 'message': complaintCtrl.text.trim(), 'status': 'open', 'timestamp': FieldValue.serverTimestamp()}); 
              ScaffoldMessenger.of(pageContext).showSnackBar(const SnackBar(content: Text('تم إرسال رسالتك للدعم الفني بنجاح ✅', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green)); 
            } catch(e) { 
              ScaffoldMessenger.of(pageContext).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الإرسال ❌', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red)); 
            } 
          }, 
          child: const Text('إرسال الدعم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }
}