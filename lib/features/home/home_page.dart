// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

import 'package:lamma_new/features/home/cubit/home_cubit.dart';
import 'package:lamma_new/features/home/cubit/home_state.dart';
import 'package:lamma_new/features/auth/presentation/pages/login_page.dart'; 
import 'package:lamma_new/features/profile/edit_profile_page.dart'; 

import 'package:lamma_new/features/home/views/home_main_view.dart';
import 'package:lamma_new/features/home/views/search_view.dart';
import 'package:lamma_new/features/home/views/orders_view.dart';
import 'package:lamma_new/features/home/views/profile_view.dart';
import 'package:lamma_new/features/home/role_registration_sheets.dart'; 

import 'package:lamma_new/core/shared_widgets/premium_toast.dart';

// 🟢 استيرادات شاشات الكابتن الحقيقية
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_radar_tab.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_active_trips_tab.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_history_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryNavy = const Color(0xFF0F172A); 
  final Color royalGreen = const Color(0xFF1B4332); 
  final Color goldAccent = const Color(0xFFD4AF37); 
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late HomeCubit _homeCubit;

  @override
  void initState() {
    super.initState();
    _homeCubit = context.read<HomeCubit>();
  }

  @override
  void dispose() {
    super.dispose();
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

    _homeCubit.markAllNotificationsAsRead();

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (bottomSheetContext) {
        return SizedBox(
          height: MediaQuery.of(bottomSheetContext).size.height * 0.65, 
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Container(
                  width: 40.w, 
                  height: 5.h, 
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10.r))
                ),
                SizedBox(height: 16.h),
                Text('الإشعارات', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: primaryNavy, fontFamily: 'Cairo')),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').orderBy('timestamp', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('لا توجد إشعارات حالياً 🔕', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp)));
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var notif = snapshot.data!.docs[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: goldAccent.withOpacity(0.2), 
                              child: Icon(Icons.notifications_active, color: goldAccent)
                            ), 
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
            PremiumToast.show(context, state.successMessage!); 
            _homeCubit.clearActionStatus(); 
          }
          else if (state.actionStatus == HomeActionStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
            _homeCubit.clearActionStatus(); 
          }
          else if (state.actionStatus == HomeActionStatus.registrationRequired) {
            final role = state.pendingRegistrationRole;
            final fullName = state.userName;
            final cubit = BlocProvider.of<HomeCubit>(context);
            cubit.clearActionStatus(); 

            if (role == 'driver') RoleRegistrationSheets.showDriver(context, cubit, fullName);
            else if (role == 'lawyer') RoleRegistrationSheets.showLawyer(context, cubit, fullName);
            else if (role == 'doctor') RoleRegistrationSheets.showDoctor(context, cubit, fullName);
            else if (role == 'nurse') RoleRegistrationSheets.showNurse(context, cubit, fullName);
          }
        },
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            Widget bodyContent;
            
            final bool isDriver = state.activeRole == 'driver';

            if (isDriver) {
              switch (state.bottomNavIndex) {
                case 0: 
                  bodyContent = HomeMainView(userName: state.userName, activeRole: state.activeRole, profileImageUrl: state.profileImageUrl, unreadCount: state.unreadNotificationsCount, activeOrdersCount: state.activeOrdersCount, onOpenNotifications: () => _openNotifications(context)); 
                  break;
                case 1: 
                  // 🟢 تم ربط الرادار
                  bodyContent = const DriverRadarTab(); 
                  break;
                case 2: 
                  // 🟢 تم ربط الرحلات النشطة
                  bodyContent = const DriverActiveTripsTab(); 
                  break;
                case 3: 
                  // 🟢 تم ربط السجل
                  bodyContent = const DriverHistoryTab(); 
                  break;
                default: 
                  bodyContent = HomeMainView(userName: state.userName, activeRole: state.activeRole, profileImageUrl: state.profileImageUrl, unreadCount: state.unreadNotificationsCount, activeOrdersCount: state.activeOrdersCount, onOpenNotifications: () => _openNotifications(context));
              }
            } else {
              switch (state.bottomNavIndex) {
                case 0: 
                  bodyContent = HomeMainView(userName: state.userName, activeRole: state.activeRole, profileImageUrl: state.profileImageUrl, unreadCount: state.unreadNotificationsCount, activeOrdersCount: state.activeOrdersCount, onOpenNotifications: () => _openNotifications(context)); 
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
                  bodyContent = HomeMainView(userName: state.userName, activeRole: state.activeRole, profileImageUrl: state.profileImageUrl, unreadCount: state.unreadNotificationsCount, activeOrdersCount: state.activeOrdersCount, onOpenNotifications: () => _openNotifications(context));
              }
            }

            return PopScope(
              canPop: state.bottomNavIndex == 0,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                _homeCubit.changeTab(0);
              },
              child: Scaffold(
                key: _scaffoldKey,
                backgroundColor: const Color(0xFFF8FAFC), 
                resizeToAvoidBottomInset: true, 
                extendBody: true, 

                body: Directionality(
                  textDirection: TextDirection.rtl, 
                  child: bodyContent
                ),
                
                bottomNavigationBar: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h),
                    child: Container(
                      height: 65.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35.r), 
                        gradient: LinearGradient(
                          colors: [primaryNavy, royalGreen],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: isDriver
                          ? [
                              _buildNavItem(0, Icons.home_rounded, 'الرئيسية', state),
                              _buildBadgedNavItem(1, Icons.radar_rounded, 'الرادار', state),
                              _buildNavItem(2, Icons.play_circle_fill_rounded, 'النشطة', state),
                              _buildNavItem(3, Icons.history_rounded, 'السجل', state),
                            ]
                          : [
                              _buildNavItem(0, Icons.home_rounded, 'الرئيسية', state),
                              _buildNavItem(1, Icons.search_rounded, 'البحث', state),
                              _buildBadgedNavItem(2, Icons.receipt_long_rounded, 'الطلبات', state), 
                              _buildNavItem(3, Icons.person_rounded, 'الحساب', state),
                            ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, HomeState state) {
    bool isSelected = state.bottomNavIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact(); 
        _homeCubit.changeTab(index); 
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65.w, 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              transform: Matrix4.translationValues(0, isSelected ? -2.h : 0, 0),
              padding: EdgeInsets.all(6.w), 
              decoration: BoxDecoration(
                color: isSelected ? goldAccent : Colors.transparent, 
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryNavy : Colors.white.withOpacity(0.6), 
                size: 22.sp,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: isSelected ? goldAccent : Colors.white.withOpacity(0.6),
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgedNavItem(int index, IconData icon, String label, HomeState state) {
    bool isSelected = state.bottomNavIndex == index;

    Widget iconWidget = Icon(
      icon,
      color: isSelected ? primaryNavy : Colors.white.withOpacity(0.6),
      size: 22.sp,
    );

    Widget badgedIcon = state.activeRole == 'driver'
        ? StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('trips').where('status', isEqualTo: 'pending').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return iconWidget;
              
              int radarCount = 0;
              if (snapshot.hasData) {
                String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                radarCount = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>? ?? {};
                  String ownerId = data['userId'] ?? data['driverId'] ?? data['uid'] ?? '';
                  return ownerId != currentUserId;
                }).length;
              }
              
              int totalDriverAlerts = state.activeOrdersCount + radarCount;
              return Badge(
                isLabelVisible: totalDriverAlerts > 0 || state.hasNewNotification, 
                label: totalDriverAlerts > 0 ? Text(totalDriverAlerts.toString(), style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp)) : null,
                backgroundColor: Colors.redAccent,
                child: iconWidget,
              );
            }
          )
        : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('trips').where('isDriverPost', isEqualTo: true).where('status', isEqualTo: 'available').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return iconWidget;
              
              int availableTravels = 0;
              if (snapshot.hasData) {
                String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                availableTravels = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>? ?? {};
                  String ownerId = data['userId'] ?? data['driverId'] ?? data['uid'] ?? '';
                  return ownerId != currentUserId;
                }).length;
              }

              int totalCustomerAlerts = state.activeOrdersCount + availableTravels;
              return Badge(
                isLabelVisible: totalCustomerAlerts > 0 || state.hasNewNotification, 
                label: totalCustomerAlerts > 0 ? Text(totalCustomerAlerts.toString(), style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp)) : null,
                backgroundColor: Colors.redAccent,
                child: iconWidget,
              );
            }
          );

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact(); 
        _homeCubit.changeTab(index); 
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              transform: Matrix4.translationValues(0, isSelected ? -2.h : 0, 0),
              padding: EdgeInsets.all(6.w), 
              decoration: BoxDecoration(
                color: isSelected ? goldAccent : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: badgedIcon, 
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: isSelected ? goldAccent : Colors.white.withOpacity(0.6),
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPasswordReset(BuildContext pageContext) {
    showDialog(
      context: pageContext, 
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)), 
        title: Row(
          textDirection: TextDirection.rtl, 
          children: [
            Icon(Icons.lock_reset_rounded, color: primaryNavy), 
            SizedBox(width: 8.w), 
            const Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))
          ]
        ), 
        content: const Text(
          'هل تريد إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني؟', 
          style: TextStyle(fontFamily: 'Cairo', fontSize: 14), 
          textDirection: TextDirection.rtl
        ), 
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))
          ), 
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: royalGreen, foregroundColor: Colors.white), 
            onPressed: () { 
              Navigator.pop(ctx); 
              _homeCubit.sendPasswordResetEmail(); 
            }, 
            child: const Text('إرسال الرابط', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))
          ),
        ],
      )
    );
  }

  void _showSupportDialog(BuildContext pageContext, String currentUserName, String currentUserEmail) {
    final TextEditingController complaintCtrl = TextEditingController();
    showDialog(
      context: pageContext, 
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)), 
        title: Row(
          textDirection: TextDirection.rtl, 
          children: [
            const Icon(Icons.support_agent_rounded, color: Colors.orange), 
            SizedBox(width: 8.w), 
            const Text('الدعم الفني والشكاوى', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16))
          ]
        ), 
        content: TextField(
          controller: complaintCtrl, 
          maxLines: 4, 
          textDirection: TextDirection.rtl, 
          decoration: InputDecoration(
            hintText: 'اكتب شكوتك، مشكلتك، أو مقترحك هنا...', 
            hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13), 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)), 
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: royalGreen, width: 2))
          ),
        ), 
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))
          ), 
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: royalGreen, foregroundColor: Colors.white), 
            onPressed: () async { 
              if (complaintCtrl.text.trim().isEmpty) return; 
              Navigator.pop(ctx); 
              try { 
                User? user = FirebaseAuth.instance.currentUser; 
                await FirebaseFirestore.instance.collection('support_tickets').add({
                  'uid': user?.uid, 
                  'name': currentUserName, 
                  'email': currentUserEmail, 
                  'message': complaintCtrl.text.trim(), 
                  'status': 'open', 
                  'timestamp': FieldValue.serverTimestamp()
                }); 
                ScaffoldMessenger.of(pageContext).showSnackBar(const SnackBar(content: Text('تم إرسال رسالتك للدعم الفني بنجاح ✅', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green)); 
              } catch(e) { 
                ScaffoldMessenger.of(pageContext).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الإرسال ❌', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red)); 
              } 
            }, 
            child: const Text('إرسال الدعم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );
  }
}