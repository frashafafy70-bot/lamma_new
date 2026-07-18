// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🟢 تم الإضافة لجلب الـ driverId
import 'package:lamma_new/l10n/app_localizations.dart'; 

import 'package:lamma_new/features/home/cubit/home_cubit.dart';
import 'package:lamma_new/features/home/cubit/home_state.dart';
import 'package:lamma_new/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:lamma_new/features/trips/presentation/pages/trips_services_page.dart';
import 'package:lamma_new/core/theme/app_theme.dart'; // 🟢 استدعاء الثيم المركزي
import 'package:lamma_new/features/trips/presentation/widgets/modern_service_card.dart'; 
import 'package:lamma_new/features/trips/presentation/widgets/wide_service_card.dart'; 
import 'package:lamma_new/features/trips/presentation/widgets/travel_service_card.dart';
import 'package:lamma_new/features/home/views/widgets/add_travel_bottom_sheet.dart'; 
import 'package:lamma_new/features/trips/presentation/widgets/fade_slide_animator.dart';
import 'package:lamma_new/features/trips/presentation/widgets/driver_radar_card.dart'; 
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_radar_page.dart'; 
import 'package:lamma_new/features/home/views/widgets/home_shimmer_loading.dart';
import 'account_switch_widget.dart'; 

class HomeMainView extends StatefulWidget {
  final String activeRole;
  final String userName;
  final String profileImageUrl;
  final int unreadCount; 
  final int activeOrdersCount; 
  final int clientRequestsBadgeCount; 
  final VoidCallback onOpenNotifications;

  const HomeMainView({
    super.key,
    required this.activeRole,
    required this.userName,
    required this.profileImageUrl,
    required this.unreadCount,
    required this.activeOrdersCount, 
    required this.clientRequestsBadgeCount, 
    required this.onOpenNotifications,
  });

  @override
  State<HomeMainView> createState() => _HomeMainViewState();
}

class _HomeMainViewState extends State<HomeMainView> {

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // 🟢 ربط بالثيم
        appBar: _buildAppBar(context),
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state.status == HomeStatus.loading) {
              return const HomeShimmerLoading();
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 10.h, bottom: 100.h), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoleHeaderCard(
                    activeRole: widget.activeRole,
                    onSwitchTap: () => _openAccountSwitchPage(context),
                  ),
                  
                  SizedBox(height: 18.h), 
                  
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
                      availableTravels: widget.clientRequestsBadgeCount, 
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final extColors = Theme.of(context).extension<AppColorsExtension>()!; // 🟢 استدعاء الألوان المخصصة
    
    return AppBar(
      backgroundColor: Colors.transparent, 
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, extColors.royalGreen], // 🟢 ربط بالثيم
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: extColors.accentGold, // 🟢 ربط بالثيم
            backgroundImage: widget.profileImageUrl.isNotEmpty ? NetworkImage(widget.profileImageUrl) : null,
            child: widget.profileImageUrl.isEmpty ? Icon(Icons.person, color: colorScheme.primary, size: 20.sp) : null,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              l10n?.welcomeUser(widget.userName) ?? 'مرحباً، ${widget.userName}', 
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
            backgroundColor: colorScheme.error, // 🟢 ربط بالثيم
            child: const Icon(Icons.notifications_none, color: Colors.white),
          ),
          onPressed: widget.onOpenNotifications,
        ),
      ],
    );
  }
}

class _RoleHeaderCard extends StatelessWidget {
  final String activeRole;
  final VoidCallback onSwitchTap;

  const _RoleHeaderCard({
    required this.activeRole,
    required this.onSwitchTap,
  });

  static String _getRoleName(BuildContext context, String role) {
    final l10n = AppLocalizations.of(context);
    switch (role) {
      case 'client': return l10n?.clientRoleName ?? 'عميل'; 
      case 'driver': return l10n?.captainRoleName ?? 'كابتن'; 
      case 'lawyer': return l10n?.lawyerRoleName ?? 'محامي';
      case 'doctor': return l10n?.doctorRoleName ?? 'طبيب';
      case 'nurse': return l10n?.nurseRoleName ?? 'تمريض';
      default: return l10n?.serviceProviderRoleName ?? 'مقدم خدمة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final extColors = Theme.of(context).extension<AppColorsExtension>()!;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w), 
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, extColors.royalGreen], // 🟢 ربط بالثيم
          begin: Alignment.topRight, 
          end: Alignment.bottomLeft
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.w),
        boxShadow: [
          BoxShadow(color: extColors.royalGreenLight, blurRadius: 20, offset: const Offset(0, 10)) // 🟢 ربط بالثيم
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.currentAccountMode ?? 'وضع الحساب الحالي', 
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12.sp, fontFamily: 'Cairo')
              ),
              SizedBox(height: 2.h),
              Text(
                _getRoleName(context, activeRole), 
                style: TextStyle(color: extColors.accentGold, fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')
              ),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: extColors.accentGold, // 🟢 ربط بالثيم
              foregroundColor: colorScheme.primary, // 🟢 ربط بالثيم
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))
            ),
            onPressed: onSwitchTap,
            icon: Icon(Icons.swap_horiz_rounded, size: 18.sp),
            label: Text(
              l10n?.switchBtn ?? 'تبديل', 
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)
            ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // 🟢 ربط بالثيم
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => AddTravelBottomSheet(
        userName: uName,
        // 🟢 تمرير الـ driverId المطلوب لحل الـ Error القاتل
        driverId: FirebaseAuth.instance.currentUser?.uid ?? '', 
      ),
    );
  }
}

class _ClientDashboard extends StatelessWidget {
  final int activeOrdersCount;
  final int availableTravels; 

  const _ClientDashboard({
    required this.activeOrdersCount,
    required this.availableTravels,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final extColors = Theme.of(context).extension<AppColorsExtension>()!;
    int totalAlerts = activeOrdersCount + availableTravels;

    return Column(
      children: [
        FadeSlideAnimator(
          delayMs: 100,
          child: WideServiceCard(
            title: l10n?.deliveryAndTrips ?? 'توصيل ورحلات', 
            subtitle: l10n?.requestCaptainNow ?? 'اطلب كابتن فوراً لرحلتك', 
            imagePath: 'assets/images/taxi_3d.png', 
            fallbackIcon: Icons.local_taxi_rounded, 
            fallbackColor: extColors.accentGold, // 🟢 ربط بالثيم
            badgeCount: totalAlerts, 
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TripsServicesPage()));
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
                  title: l10n?.medicalServices ?? 'خدمات طبية', 
                  subtitle: l10n?.doctorsAndClinics ?? 'أطباء وعيادات', 
                  imagePath: 'assets/images/medical_3d.png', 
                  fallbackIcon: Icons.health_and_safety_rounded, 
                  fallbackColor: extColors.medicalTeal, // 🟢 ربط بالثيم
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n?.medicalSectionComingSoon ?? 'سيتم تفعيل القسم الطبي قريباً', style: const TextStyle(fontFamily: 'Cairo')), 
                        backgroundColor: extColors.medicalTeal
                      )
                    );
                  }
                ),
              ),
              SizedBox(width: 16.w), 
              Expanded(
                child: ModernServiceCard(
                  title: l10n?.legalServices ?? 'خدمات قانونية', 
                  subtitle: l10n?.consultationsAndPowerOfAttorney ?? 'استشارات وتوكيلات', 
                  imagePath: 'assets/images/law_3d.png', 
                  fallbackIcon: Icons.gavel_rounded, 
                  fallbackColor: colorScheme.primary, // 🟢 ربط بالثيم
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n?.legalSectionComingSoon ?? 'سيتم تفعيل قسم الخدمات القانونية قريباً', style: const TextStyle(fontFamily: 'Cairo')), 
                        backgroundColor: colorScheme.primary
                      )
                    );
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
            title: l10n?.shopAndStores ?? 'شوب ومتاجر', 
            subtitle: l10n?.shopBestProductsEasily ?? 'تسوق أفضل المنتجات بسهولة', 
            imagePath: 'assets/images/shop_3d.png', 
            fallbackIcon: Icons.storefront_rounded, 
            fallbackColor: extColors.royalGreen, // 🟢 ربط بالثيم
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n?.storesSectionUnderConstruction ?? 'قسم المتاجر تحت الإنشاء', style: const TextStyle(fontFamily: 'Cairo')), 
                  backgroundColor: extColors.royalGreen
                )
              );
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
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    return FadeSlideAnimator(
      delayMs: 100,
      child: ModernServiceCard(
        title: l10n?.dashboardTitle ?? 'لوحة التحكم', 
        subtitle: l10n?.consultationsAndAgencies ?? 'الاستشارات والتوكيلات', 
        imagePath: 'assets/images/law_3d.png', 
        fallbackIcon: Icons.gavel_rounded, 
        fallbackColor: colorScheme.primary, // 🟢 ربط بالثيم
        onTap: () {
          // TODO: تفعيل لوحة تحكم المحامي لاحقاً 
        }
      ),
    );
  }
}