// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

import 'package:lamma_new/features/home/cubit/home_cubit.dart';
import 'package:lamma_new/features/home/cubit/home_state.dart';

import 'package:lamma_new/features/notifications/presentation/cubit/notification_state.dart';
import 'package:lamma_new/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:lamma_new/features/profile/presentation/cubit/profile_state.dart';
import 'package:lamma_new/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:lamma_new/features/auth/cubit/auth_cubit.dart'; 
import 'package:lamma_new/features/auth/cubit/auth_state.dart'; 

import 'package:lamma_new/features/auth/presentation/pages/login_page.dart'; 
import 'package:lamma_new/features/profile/edit_profile_page.dart'; 
import 'package:lamma_new/features/auth/presentation/pages/reset_password_otp_page.dart'; 

import 'package:lamma_new/features/home/views/home_main_view.dart';
import 'package:lamma_new/features/home/views/search_view.dart';
import 'package:lamma_new/features/home/views/orders_view.dart';
import 'package:lamma_new/features/home/views/profile_view.dart';

import 'package:lamma_new/core/shared_widgets/premium_toast.dart';

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
    // 🟢 تم إزالة _homeCubit.changeTab(0); لمنع إعادة تصفير التاب عند عمل ريفريش للشاشة
    context.read<ProfileCubit>().loadUserProfile();
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

    context.read<NotificationCubit>().markAllNotificationsAsRead();

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
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpSent) {
            String phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPasswordOtpPage(
                  verificationId: state.verificationId,
                  phone: phone,
                ),
              ),
            );
          } 
          else if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message ?? 'تمت العملية بنجاح', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), 
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              )
            );
          } 
          else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message ?? 'حدث خطأ', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), 
                backgroundColor: Colors.red.shade800,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              )
            );
          }
        },
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, homeState) {
            return BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, profileState) {
                return BlocBuilder<NotificationCubit, NotificationState>(
                  builder: (context, notifState) {
                    
                    Widget bodyContent;
                    final bool isDriver = profileState.activeRole == 'driver';

                    // 🟢 قمنا بتعريف الشاشة الرئيسية مرة واحدة لتمريرها بمرونة
                    final homeMainView = HomeMainView(
                      userName: profileState.userName.isNotEmpty ? profileState.userName : 'جاري التحميل...', 
                      activeRole: profileState.activeRole, 
                      profileImageUrl: profileState.profileImageUrl, 
                      unreadCount: notifState.unreadNotificationsCount, 
                      activeOrdersCount: homeState.activeOrders.length, 
                      onOpenNotifications: () => _openNotifications(context)
                    );

                    // 🟢 التعديل الجذري: استخدام IndexedStack بدلاً من الـ Switch
                    // ده بيضمن إن شاشة الرادار والشاشات التانية تفضل محتفظة بحالتها بدون تهنيج أو إعادة تحميل
                    if (isDriver) {
                      bodyContent = IndexedStack(
                        index: homeState.bottomNavIndex,
                        children: [
                          homeMainView,
                          const DriverRadarTab(),
                          const DriverActiveTripsTab(),
                          const DriverHistoryTab(),
                        ],
                      );
                    } else {
                      bodyContent = IndexedStack(
                        index: homeState.bottomNavIndex,
                        children: [
                          homeMainView,
                          SearchView(activeRole: profileState.activeRole),
                          OrdersView(activeRole: profileState.activeRole),
                          ProfileView(
                            activeRole: profileState.activeRole,
                            isLoadingProfile: profileState.status == ProfileStatus.loading,
                            profileImageUrl: profileState.profileImageUrl,
                            userName: profileState.userName.isNotEmpty ? profileState.userName : 'جاري التحميل...',
                            userEmail: profileState.userEmail,
                            onEditProfile: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage())),
                            onPasswordReset: () {
                              String phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
                              String email = FirebaseAuth.instance.currentUser?.email ?? profileState.userEmail;
                              _confirmPasswordReset(context, phone, email);
                            },
                            onSupport: () => _showSupportDialog(context, profileState.userName, profileState.userEmail),
                            onLogout: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
                            },
                          ),
                        ],
                      );
                    }

                    return PopScope(
                      canPop: homeState.bottomNavIndex == 0,
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
                          bottom: false,
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
                                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: isDriver
                                  ? [
                                      _buildNavItem(0, Icons.home_rounded, 'الرئيسية', homeState),
                                      _buildBadgedNavItem(1, Icons.radar_rounded, 'الرادار', homeState, profileState, notifState),
                                      _buildBadgedNavItem(2, Icons.play_circle_fill_rounded, 'النشطة', homeState, profileState, notifState),
                                      _buildNavItem(3, Icons.history_rounded, 'السجل', homeState),
                                    ]
                                  : [
                                      _buildNavItem(0, Icons.home_rounded, 'الرئيسية', homeState),
                                      _buildNavItem(1, Icons.search_rounded, 'البحث', homeState),
                                      _buildBadgedNavItem(2, Icons.receipt_long_rounded, 'الطلبات', homeState, profileState, notifState), 
                                      _buildNavItem(3, Icons.person_rounded, 'الحساب', homeState),
                                    ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
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
              decoration: BoxDecoration(color: isSelected ? goldAccent : Colors.transparent, shape: BoxShape.circle),
              child: Icon(icon, color: isSelected ? primaryNavy : Colors.white.withOpacity(0.6), size: 22.sp),
            ),
            SizedBox(height: 2.h),
            Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.bold, color: isSelected ? goldAccent : Colors.white.withOpacity(0.6)), maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgedNavItem(int index, IconData icon, String label, HomeState homeState, ProfileState profileState, NotificationState notifState) {
    bool isSelected = homeState.bottomNavIndex == index;
    
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    Stream<QuerySnapshot>? badgeStream;
    int Function(QuerySnapshot) calculateCount = (snap) => 0;

    if (label == 'الرادار') {
      badgeStream = FirebaseFirestore.instance.collection('trips')
          .where('isDriverPost', isEqualTo: false)
          .snapshots();
          
      calculateCount = (snap) => snap.docs.where((doc) {
        var d = doc.data() as Map<String, dynamic>? ?? {};
        if (d['isDeletedForDriver'] == true) return false;
        
        String status = d['status'] ?? '';
        String driverId = d['driverId'] ?? '';
        String ownerId = d['userId'] ?? d['passengerId'] ?? '';
        
        bool isPending = status == 'pending';
        bool isNegotiatingWithAnother = status == 'negotiating' && driverId != currentUserId;
        
        return (isPending || isNegotiatingWithAnother) && ownerId != currentUserId;
      }).length;
    } 
    else if (label == 'النشطة') {
      badgeStream = FirebaseFirestore.instance.collection('trip_bookings')
          .where('driverId', isEqualTo: currentUserId)
          .snapshots();
          
      calculateCount = (snap) => snap.docs.where((doc) {
        var d = doc.data() as Map<String, dynamic>? ?? {};
        return d['status'] == 'pending';
      }).length;
    } 
    else if (label == 'الطلبات') {
      badgeStream = FirebaseFirestore.instance.collection('trips')
          .where('isDriverPost', isEqualTo: true)
          .snapshots();
          
      calculateCount = (snap) => snap.docs.where((doc) {
        var d = doc.data() as Map<String, dynamic>? ?? {};
        return d['status'] == 'available' && (d['driverId'] ?? '') != currentUserId;
      }).length;
    }

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
              decoration: BoxDecoration(color: isSelected ? goldAccent : Colors.transparent, shape: BoxShape.circle),
              child: badgeStream != null
                ? StreamBuilder<QuerySnapshot>(
                    stream: badgeStream,
                    builder: (context, snapshot) {
                      int count = 0;
                      if (snapshot.hasData && !snapshot.hasError) {
                        count = calculateCount(snapshot.data!);
                      }
                      if (label == 'الطلبات') count += homeState.activeOrders.length;
                      
                      bool showBadge = count > 0 || (label != 'الرادار' && notifState.hasNewNotification);

                      return Badge(
                        isLabelVisible: showBadge, 
                        label: count > 0 ? Text(count.toString(), style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp)) : null,
                        backgroundColor: Colors.redAccent,
                        child: Icon(icon, color: isSelected ? primaryNavy : Colors.white.withOpacity(0.6), size: 22.sp),
                      );
                    }
                  )
                : Icon(icon, color: isSelected ? primaryNavy : Colors.white.withOpacity(0.6), size: 22.sp),
            ),
            SizedBox(height: 2.h),
            Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.bold, color: isSelected ? goldAccent : Colors.white.withOpacity(0.6)), maxLines: 1),
          ],
        ),
      ),
    );
  }

  void _confirmPasswordReset(BuildContext pageContext, String phone, String email) {
    showDialog(
      context: pageContext, 
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)), 
        title: Row(
          textDirection: TextDirection.rtl, 
          children: [
            Icon(Icons.lock_reset_rounded, color: primaryNavy), 
            SizedBox(width: 8.w), 
            const Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18))
          ]
        ), 
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'اختر طريقة الاستعادة لإعادة تعيين كلمة المرور:', 
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14), 
              textDirection: TextDirection.rtl
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryNavy,
                side: BorderSide(color: primaryNavy),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                padding: EdgeInsets.symmetric(vertical: 10.h)
              ),
              icon: const Icon(Icons.email_outlined),
              label: const Text('إرسال رابط للبريد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                if (email.isNotEmpty) {
                  pageContext.read<AuthCubit>().sendPasswordResetEmail(email: email);
                } else {
                  ScaffoldMessenger.of(pageContext).showSnackBar(const SnackBar(content: Text('البريد الإلكتروني غير متوفر، يرجى استكمال بياناتك.', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
                }
              },
            ),
            SizedBox(height: 12.h),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: royalGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                padding: EdgeInsets.symmetric(vertical: 10.h)
              ),
              icon: const Icon(Icons.phone_android_rounded),
              label: const Text('إرسال كود للهاتف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                if (phone.isNotEmpty) {
                  String fullPhone = phone.startsWith('+20') ? phone : '+20${phone.replaceFirst(RegExp(r'^0+'), '')}';
                  pageContext.read<AuthCubit>().sendPasswordResetOtp(phone: fullPhone);
                } else {
                  ScaffoldMessenger.of(pageContext).showSnackBar(const SnackBar(content: Text('رقم الهاتف غير متوفر، يرجى استكمال بياناتك.', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
                }
              },
            ),
          ],
        ), 
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))), 
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