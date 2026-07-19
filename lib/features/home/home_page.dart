// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_route/auto_route.dart';
import 'package:lamma_new/l10n/app_localizations.dart';
import 'package:lamma_new/core/di/injection_container.dart';

import 'package:lamma_new/core/routes/app_router.dart';
import 'package:lamma_new/core/extensions/context_extension.dart';

// 🟢 استدعاء ملف الألوان الموحد
import 'package:lamma_new/core/theme/app_colors.dart'; // تأكد من مسار ملف الألوان عندك

import 'package:lamma_new/features/home/cubit/home_cubit.dart';
import 'package:lamma_new/features/home/cubit/home_state.dart';

import 'package:lamma_new/features/notifications/presentation/cubit/notification_state.dart'
    as notif;
import 'package:lamma_new/features/notifications/presentation/cubit/notification_cubit.dart';

import 'package:lamma_new/features/profile/presentation/cubit/profile_state.dart'
    as prof;
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late HomeCubit _homeCubit;

  @override
  void initState() {
    super.initState();
    _homeCubit = sl<HomeCubit>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (currentUserId.isNotEmpty) {
        _homeCubit.startListeningToBadges(currentUserId);
        context
            .read<NotificationCubit>()
            .startListeningToNotifications(currentUserId);
      }

      _homeCubit.fetchHomeDashboardData();
      context.read<ProfileCubit>().loadUserProfile();
    });
  }

  void _openNotifications(BuildContext context) {
    context.read<NotificationCubit>().markAllNotificationsAsRead();
    context.router
        .push(const NotificationsRoute()); // 🟢 تم التعديل وإضافة const
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) => _homeCubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthOtpSent) {
                String phone =
                    FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResetPasswordOtpPage(
                      verificationId: state.verificationId,
                      phone: phone,
                    ),
                  ),
                );
              } else if (state is AuthSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.message ?? l10n.operationSuccess,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                ));
              } else if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.message ?? l10n.errorOccurred,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.red.shade800,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                ));
              }
            },
          ),
          BlocListener<ProfileCubit, prof.ProfileState>(
            listenWhen: (previous, current) =>
                previous.actionStatus != current.actionStatus,
            listener: (context, state) {
              if (state.actionStatus == prof.ProfileActionStatus.success &&
                  state.successMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.successMessage!,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r)),
                  ),
                );
              } else if (state.actionStatus == prof.ProfileActionStatus.error &&
                  state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.red.shade800,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r)),
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
                        userName: profileState.userName.isNotEmpty
                            ? profileState.userName
                            : l10n.loading,
                        activeRole: profileState.activeRole,
                        profileImageUrl: profileState.profileImageUrl,
                        unreadCount: notifState.unreadNotificationsCount,
                        activeOrdersCount: homeState.activeOrders.length,
                        clientRequestsBadgeCount:
                            homeState.clientRequestsBadgeCount,
                        onOpenNotifications: () => _openNotifications(context));

                    if (isDriver) {
                      bodyContent = IndexedStack(
                        index: homeState.bottomNavIndex,
                        children: [
                          homeMainView,
                          DriverRadarTab(showHeader: true),
                          DriverActiveTripsTab(showHeader: true),
                          DriverHistoryTab(showHeader: true),
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
                            isLoadingProfile: profileState.status ==
                                prof.ProfileStatus.loading,
                            profileImageUrl: profileState.profileImageUrl,
                            userName: profileState.userName.isNotEmpty
                                ? profileState.userName
                                : l10n.loading,
                            userEmail: profileState.userEmail,
                            onEditProfile: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const EditProfilePage())),
                            onPasswordReset: () {
                              String phone = FirebaseAuth
                                      .instance.currentUser?.phoneNumber ??
                                  '';
                              String email =
                                  FirebaseAuth.instance.currentUser?.email ??
                                      profileState.userEmail;
                              _confirmPasswordReset(context, phone, email);
                            },
                            onSupport: () => _showSupportDialog(context),
                            onLogout: () async {
                              await FirebaseAuth.instance.signOut();
                              context.router.replaceAll([
                                const LoginRoute()
                              ]); // 🟢 تم التعديل وإضافة const
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
                        backgroundColor: AppColors.backgroundLight,
                        resizeToAvoidBottomInset: true,
                        extendBody: true,

                        // هنا بنشيل الـ AppBar الافتراضي من الـ Scaffold عشان إحنا حطيناه بشكل مخصص جوه كل شاشة
                        body: Directionality(
                            textDirection: TextDirection.rtl,
                            child: bodyContent),

                        // ==========================================
                        // تصميم البار السفلي المطابق للصورة تماماً
                        // ==========================================
                        bottomNavigationBar: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: 16.w, right: 16.w, bottom: 16.h),
                            child: Container(
                              height: 65.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(35.r),
                                // 🟢 تطبيق التدرج اللوني هنا أيضاً
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primaryNavy,
                                    AppColors.royalGreen
                                  ],
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5))
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: isDriver
                                    ? [
                                        _buildNavItem(0, Icons.home_rounded,
                                            l10n.navHome, homeState),
                                        _buildBadgedNavItem(
                                            1,
                                            Icons.radar_rounded,
                                            l10n.navRadar,
                                            homeState,
                                            badgeCount:
                                                homeState.radarBadgeCount,
                                            showGeneralIndicator: false),
                                        _buildBadgedNavItem(
                                            2,
                                            Icons.play_circle_fill_rounded,
                                            l10n.navActive,
                                            homeState,
                                            badgeCount:
                                                homeState.activeTripsBadgeCount,
                                            showGeneralIndicator:
                                                notifState.hasNewNotification),
                                        _buildNavItem(3, Icons.history_rounded,
                                            l10n.navHistory, homeState),
                                      ]
                                    : [
                                        _buildNavItem(0, Icons.home_rounded,
                                            l10n.navHome, homeState),
                                        _buildNavItem(1, Icons.search_rounded,
                                            l10n.navSearch, homeState),
                                        _buildBadgedNavItem(
                                            2,
                                            Icons.receipt_long_rounded,
                                            l10n.navOrders,
                                            homeState,
                                            badgeCount: homeState
                                                    .clientRequestsBadgeCount +
                                                homeState.activeOrdersCount,
                                            showGeneralIndicator:
                                                notifState.hasNewNotification),
                                        _buildNavItem(3, Icons.person_rounded,
                                            l10n.navAccount, homeState),
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

  Widget _buildNavItem(
      int index, IconData icon, String label, HomeState state) {
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
              // 🟡 الخلفية الذهبية للأيقونة المحددة
              decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentGold : Colors.transparent,
                  shape: BoxShape.circle),
              child: Icon(icon,
                  color: isSelected
                      ? AppColors.primaryNavy
                      : Colors.white.withOpacity(0.6),
                  size: 22.sp),
            ),
            SizedBox(height: 2.h),
            Text(label,
                style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppColors.accentGold
                        : Colors.white.withOpacity(0.6)),
                maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgedNavItem(
      int index, IconData icon, String label, HomeState homeState,
      {required int badgeCount, required bool showGeneralIndicator}) {
    bool isSelected = homeState.bottomNavIndex == index;
    bool showBadge = badgeCount > 0 || showGeneralIndicator;

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
                  color: isSelected ? AppColors.accentGold : Colors.transparent,
                  shape: BoxShape.circle),
              child: Badge(
                isLabelVisible: showBadge,
                label: badgeCount > 0
                    ? Text(badgeCount.toString(),
                        style: TextStyle(fontSize: 9.sp, color: Colors.white))
                    : null,
                backgroundColor: Colors.redAccent,
                child: Icon(icon,
                    color: isSelected
                        ? AppColors.primaryNavy
                        : Colors.white.withOpacity(0.6),
                    size: 22.sp),
              ),
            ),
            SizedBox(height: 2.h),
            Text(label,
                style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppColors.accentGold
                        : Colors.white.withOpacity(0.6)),
                maxLines: 1),
          ],
        ),
      ),
    );
  }

  void _confirmPasswordReset(
      BuildContext pageContext, String phone, String email) {
    final l10n = AppLocalizations.of(pageContext)!;
    showDialog(
        context: pageContext,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.r)),
              title: Row(textDirection: TextDirection.rtl, children: [
                const Icon(Icons.lock_reset_rounded,
                    color: AppColors.primaryNavy),
                SizedBox(width: 8.w),
                Text(l10n.changePasswordTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18))
              ]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.chooseRecoveryMethod,
                      style: const TextStyle(fontSize: 14),
                      textDirection: TextDirection.rtl),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryNavy,
                        side: const BorderSide(color: AppColors.primaryNavy),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(vertical: 10.h)),
                    icon: const Icon(Icons.email_outlined),
                    label: Text(l10n.sendEmailLink,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ctx.pop();
                      if (email.isNotEmpty) {
                        pageContext
                            .read<AuthCubit>()
                            .sendPasswordResetEmail(email: email);
                      } else {
                        ScaffoldMessenger.of(pageContext).showSnackBar(SnackBar(
                            content: Text(l10n.emailNotAvailable,
                                style: const TextStyle(fontFamily: 'Cairo')),
                            backgroundColor: Colors.red));
                      }
                    },
                  ),
                  SizedBox(height: 12.h),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(vertical: 10.h)),
                    icon: const Icon(Icons.phone_android_rounded),
                    label: Text(l10n.sendPhoneCode,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ctx.pop();
                      if (phone.isNotEmpty) {
                        String fullPhone = phone.startsWith('+20')
                            ? phone
                            : '+20${phone.replaceFirst(RegExp(r'^0+'), '')}';
                        pageContext
                            .read<AuthCubit>()
                            .sendPasswordResetOtp(phone: fullPhone);
                      } else {
                        ScaffoldMessenger.of(pageContext).showSnackBar(SnackBar(
                            content: Text(l10n.phoneNotAvailable,
                                style: const TextStyle(fontFamily: 'Cairo')),
                            backgroundColor: Colors.red));
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => ctx.pop(),
                    child: Text(l10n.cancel,
                        style: const TextStyle(color: Colors.grey))),
              ],
            ));
  }

  void _showSupportDialog(BuildContext pageContext) {
    final l10n = AppLocalizations.of(pageContext)!;
    final TextEditingController complaintCtrl = TextEditingController();

    showDialog(
        context: pageContext,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.r)),
              title: Row(textDirection: TextDirection.rtl, children: [
                const Icon(Icons.support_agent_rounded, color: Colors.orange),
                SizedBox(width: 8.w),
                Text(l10n.supportTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16))
              ]),
              content: TextField(
                controller: complaintCtrl,
                maxLines: 4,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                    hintText: l10n.supportHint,
                    hintStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                            color: AppColors.royalGreen, width: 2))),
              ),
              actions: [
                TextButton(
                    onPressed: () => ctx.pop(),
                    child: Text(l10n.cancel,
                        style: const TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalGreen,
                      foregroundColor: Colors.white),
                  onPressed: () {
                    if (complaintCtrl.text.trim().isEmpty) return;
                    ctx.pop();
                    pageContext
                        .read<ProfileCubit>()
                        .sendSupportTicket(message: complaintCtrl.text.trim());
                  },
                  child: Text(l10n.sendSupport,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ));
  }
}
