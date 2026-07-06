import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lamma_new/core/constants/app_strings.dart';
import 'package:lamma_new/core/constants/firebase_constants.dart';
import 'package:lamma_new/core/theme/app_colors.dart';

class AccountSwitchWidget extends StatelessWidget {
  final String currentRole;

  const AccountSwitchWidget({
    super.key,
    required this.currentRole,
  });

  // 🟢 توحيد المسمى في الواجهة ليكون (driver) برمجياً و(كابتن) للمستخدم
  List<Map<String, dynamic>> get _roles => [
    {'key': 'client', 'name': 'عميل', 'icon': Icons.person_rounded},
    {'key': 'driver', 'name': 'كابتن', 'icon': Icons.local_taxi_rounded}, 
    {'key': 'lawyer', 'name': 'محامي', 'icon': Icons.gavel_rounded},
    {'key': 'doctor', 'name': 'طبيب', 'icon': Icons.medical_services_rounded},
    {'key': 'nurse', 'name': 'تمريض', 'icon': Icons.healing_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    // 🟢 معالجة الاسم اللي جاي عشان يتطابق صح ويظلل الكارت المضبوط
    String safeCurrentRole = currentRole.trim().toLowerCase();
    if (safeCurrentRole == 'customer') safeCurrentRole = 'client';
    if (safeCurrentRole == 'captain') safeCurrentRole = 'driver';

    final currentRoleData = _roles.firstWhere(
      (role) => role['key'] == safeCurrentRole,
      orElse: () => _roles.first, 
    );

    final otherRoles = _roles.where((role) => role['key'] != safeCurrentRole).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
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

              ...List.generate(otherRoles.length, (index) {
                final role = otherRoles[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (index * 150)), 
                  curve: Curves.easeOutQuart,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildAvailableRoleCard(
                    context: context,
                    roleKey: role['key'],
                    roleName: role['name'],
                    icon: role['icon'],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentRoleCard({required String roleName, required IconData icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h), 
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentGold.withValues(alpha: 0.15),
            AppColors.accentGold.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ]
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.accentGold,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            ),
            child: Icon(
              icon,
              color: AppColors.primaryDark,
              size: 26.sp,
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
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentGold,
                ),
              ),
              Text(
                AppStrings.activeNow,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.verified_rounded,
            color: AppColors.accentGold,
            size: 36.sp,
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
      padding: EdgeInsets.only(bottom: 14.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context, roleKey);
          },
          borderRadius: BorderRadius.circular(16.r),
          splashColor: AppColors.accentGold.withValues(alpha: 0.15),
          highlightColor: AppColors.accentGold.withValues(alpha: 0.05),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white, 
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
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.accentGold.withValues(alpha: 0.8), 
                    size: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}