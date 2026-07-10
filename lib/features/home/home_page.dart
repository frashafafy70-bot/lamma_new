// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🟢 استدعاءات AutoRoute 
import 'package:auto_route/auto_route.dart';
import 'package:lamma_new/core/routes/app_router.dart';
import 'package:lamma_new/core/extensions/context_extension.dart';

import 'package:lamma_new/features/home/cubit/home_cubit.dart';
import 'package:lamma_new/features/home/cubit/home_state.dart';

import 'package:lamma_new/features/notifications/presentation/cubit/notification_state.dart' as notif;
import 'package:lamma_new/features/notifications/presentation/cubit/notification_cubit.dart';

import 'package:lamma_new/features/profile/presentation/cubit/profile_state.dart' as prof;
import 'package:lamma_new/features/profile/presentation/cubit/profile_cubit.dart';

import 'package:lamma_new/features/auth/cubit/auth_cubit.dart'; 
import 'package:lamma_new/features/auth/cubit/auth_state.dart'; 

import 'package:lamma_new/features/profile/edit_profile_page.dart'; 
import 'package:lamma_new/features/auth/presentation/pages/reset_password_otp_page.dart'; 

import 'package:lamma_new/features/home/views/home_main_view.dart';
import 'package:lamma_new/features/home/views/search_view.dart';
import 'package:lamma_new/features/home/views/orders_view.dart';
import 'package:lamma_new/features/home/views/profile_view.dart';

import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_radar_tab.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_active_trips_tab.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_history_tab.dart';

@RoutePage() 
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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      if (currentUserId.isNotEmpty) {
        _homeCubit.startListeningToBadges(currentUserId);
        context.read<NotificationCubit>().startListeningToNotifications(currentUserId);
      }
      
      _homeCubit.fetchHomeDashboardData();
      context.read<ProfileCubit>().loadUserProfile();
    });
  }

  void _openNotifications(BuildContext context) {
    context.read<NotificationCubit>().markAllNotificationsAsRead();

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (bottomSheetContext) {
        return SizedBox(
          height: bottomSheetContext.height * 0.65, 
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
                  child: BlocBuilder<NotificationCubit, notif.NotificationState>(
                    builder: (context, state) {
                      if (state.status == notif.NotificationStatus.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state.notifications.isEmpty) {
                        return Center(child: Text('لا توجد إشعارات حالياً 🔕', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp)));
                      }
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: state.notifications.length,
                        itemBuilder: (context, index) {
                          var notify = state.notifications[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: goldAccent.withOpacity(0.2), 
                              child: const Icon(Icons.notifications_active, color: Color(0xFFD4AF37))
                            ), 
                            title: Text(notify['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')), 
                            subtitle: Text(notify['body'] ?? '', style: const TextStyle(fontFamily: 'Cairo')),
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
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthCubit, AuthState>(
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
          ),
          BlocListener<ProfileCubit, prof.ProfileState>(
            listenWhen: (previous, current) => previous.actionStatus != current.actionStatus,
            listener: (context, state) {
              if (state.actionStatus == prof.ProfileActionStatus.success && state.successMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.successMessage!, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                );
              } else if (state.actionStatus == prof.ProfileActionStatus.error && state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.red.shade800,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, homeState) {
            return BlocBuilder<ProfileCubit, prof.ProfileState>(
              builder: (context, profileState) {
                return BlocBuilder<NotificationCubit, notif.NotificationState>(
                  builder: (context, notifState) {
                    
                    Widget bodyContent;
                    final bool isDriver = profileState.activeRole == 'driver';

                    final homeMainView = HomeMainView(
                      userName: profileState.userName.isNotEmpty ? profileState.userName : 'جاري التحميل...', 
                      activeRole: profileState.activeRole, 
                      profileImageUrl: profileState.profileImageUrl, 
                      unreadCount: notifState.unreadNotificationsCount, 
                      activeOrdersCount: homeState.activeOrders.length, 
                      clientRequestsBadgeCount: homeState.clientRequestsBadgeCount,
                      onOpenNotifications: () => _openNotifications(context)
                    );

                    if (isDriver) {
                      bodyContent = IndexedStack(
                        index: homeState.bottomNavIndex,
                        children: [
                          homeMainView,
                          const DriverRadarTab(showHeader: true), 
                          const DriverActiveTripsTab(showHeader: true),
                          const DriverHistoryTab(showHeader: true),
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
                            isLoadingProfile: profileState.status == prof.ProfileStatus.loading,
                            profileImageUrl: profileState.profileImageUrl,
                            userName: profileState.userName.isNotEmpty ? profileState.userName : 'جاري التحميل...',
                            userEmail: profileState.userEmail,
                            onEditProfile: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage())),
                            onPasswordReset: () {
                              String phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
                              String email = FirebaseAuth.instance.currentUser?.email ?? profileState.userEmail;
                              _confirmPasswordReset(context, phone, email);
                            },
                            onSupport: () => _showSupportDialog(context),
                            onLogout: () async {
                              await FirebaseAuth.instance.signOut();
                              // 🟢 التوجيه باستخدام AutoRoute مع const
                              context.router.replaceAll([const LoginRoute()]);
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

  Widget _buildBadgedNavItem(int index, IconData icon, String label, HomeState homeState, prof.ProfileState profileState, notif.NotificationState notifState) {
    bool isSelected = homeState.bottomNavIndex == index;
    int count = 0;

    if (label == 'الرادار') {
      count = homeState.radarBadgeCount;
    } else if (label == 'النشطة') {
      count = homeState.activeTripsBadgeCount;
    } else if (label == 'الطلبات') {
      count = homeState.clientRequestsBadgeCount + homeState.activeOrdersCount;
    }

    bool showBadge = count > 0 || (label != 'الرادار' && notifState.hasNewNotification);

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
              child: Badge(
                isLabelVisible: showBadge, 
                label: count > 0 ? Text(count.toString(), style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp)) : null,
                backgroundColor: Colors.redAccent,
                child: Icon(icon, color: isSelected ? primaryNavy : Colors.white.withOpacity(0.6), size: 22.sp),
              ),
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
                ctx.pop(); 
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
                ctx.pop(); 
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
            onPressed: () => ctx.pop(), 
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))
          ), 
        ],
      )
    );
  }

  void _showSupportDialog(BuildContext pageContext) {
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
          TextButton(onPressed: () => ctx.pop(), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))), 
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: royalGreen, foregroundColor: Colors.white), 
            onPressed: () { 
              if (complaintCtrl.text.trim().isEmpty) return; 
              ctx.pop(); 
              pageContext.read<ProfileCubit>().sendSupportTicket(message: complaintCtrl.text.trim());
            }, 
            child: const Text('إرسال الدعم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );
  }
}