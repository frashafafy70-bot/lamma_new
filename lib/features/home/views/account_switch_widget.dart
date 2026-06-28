import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 🟢 استدعاء ملفات الثوابت
import 'package:lamma_new/core/constants/app_strings.dart';
import 'package:lamma_new/core/constants/firebase_constants.dart';
import 'package:lamma_new/core/theme/app_colors.dart';

class AccountSwitchWidget extends StatelessWidget {
  final String currentRole;

  const AccountSwitchWidget({
    super.key,
    required this.currentRole,
  });

  // 🟢 استخدام ثوابت النصوص والفيربيز بدل النصوص المباشرة
  List<Map<String, dynamic>> get _roles => [
    {'key': FirebaseConstants.roleCustomer, 'name': AppStrings.customerName, 'icon': Icons.person_rounded},
    {'key': FirebaseConstants.roleCaptain, 'name': AppStrings.captainName, 'icon': Icons.local_taxi_rounded},
    {'key': FirebaseConstants.roleLawyer, 'name': AppStrings.lawyerName, 'icon': Icons.gavel_rounded},
    {'key': FirebaseConstants.roleDoctor, 'name': AppStrings.doctorName, 'icon': Icons.medical_services_rounded},
    {'key': FirebaseConstants.roleNurse, 'name': AppStrings.nurseName, 'icon': Icons.healing_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final String safeCurrentRole = currentRole.trim().toLowerCase();

    final currentRoleData = _roles.firstWhere(
      (role) => role['key'] == safeCurrentRole,
      orElse: () => _roles.first, 
    );

    final otherRoles = _roles.where((role) => role['key'] != safeCurrentRole).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.primaryDark, // 🟢 استخدام الألوان من الـ Theme
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.accentGold),
            onPressed: () => Navigator.pop(context), 
          ),
          title: Text(
            AppStrings.accountSwitchTitle, 
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.currentRole,
                style: TextStyle(
                  color: AppColors.textMuted.shade400,
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              _buildCurrentRoleCard(
                roleName: currentRoleData['name'],
                icon: currentRoleData['icon'],
              ),

              SizedBox(height: 32.h), 

              Text(
                AppStrings.switchToOtherRole,
                style: TextStyle(
                  color: AppColors.textMuted.shade400,
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),

              ...otherRoles.map((role) => _buildAvailableRoleCard(
                    context: context,
                    roleKey: role['key'],
                    roleName: role['name'],
                    icon: role['icon'],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentRoleCard({required String roleName, required IconData icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.accentGold,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: const BoxDecoration(
              color: AppColors.accentGold,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primaryDark,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                roleName,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentGold,
                ),
              ),
              Text(
                AppStrings.activeNow,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.sp,
                  color: AppColors.accentGold.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.verified_rounded,
            color: AppColors.accentGold,
            size: 32.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableRoleCard({
    required BuildContext context,
    required String roleKey,
    required String roleName,
    required IconData icon,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context, roleKey);
          },
          borderRadius: BorderRadius.circular(16.r),
          splashColor: AppColors.accentGold.withValues(alpha: 0.2),
          highlightColor: AppColors.accentGold.withValues(alpha: 0.1),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white70,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Text(
                  roleName,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}