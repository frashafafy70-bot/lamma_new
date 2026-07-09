import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import '../../family/presentation/pages/family_page.dart';

import '../../trips/cubit/passenger/passenger_my_requests_cubit.dart';
import '../../profile/presentation/cubit/profile_cubit.dart';

import 'package:lamma_new/theme/app_colors.dart';

import 'saved_addresses_page.dart';

class ProfileView extends StatelessWidget {
  final String activeRole; 
  final bool isLoadingProfile;
  final String profileImageUrl;
  final String userName;
  final String userEmail;
  final VoidCallback onEditProfile;
  final VoidCallback onPasswordReset;
  final VoidCallback onSupport;
  final VoidCallback onLogout;

  const ProfileView({
    super.key,
    required this.activeRole, 
    required this.isLoadingProfile,
    required this.profileImageUrl,
    required this.userName,
    required this.userEmail,
    required this.onEditProfile,
    required this.onPasswordReset,
    required this.onSupport,
    required this.onLogout,
  });

  Widget _buildListTile({required IconData icon, required Color color, required String title, required VoidCallback onTap}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: LammaColors.cardWhite, 
        borderRadius: BorderRadius.circular(15.r), 
        border: Border.all(color: LammaColors.dividerColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: Container(
          padding: EdgeInsets.all(8.w), 
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), 
            borderRadius: BorderRadius.circular(10.r),
          ), 
          child: Icon(icon, color: color, size: 24.sp),
        ),
        title: Text(title, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15.sp, color: LammaColors.textDark)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16.sp, color: LammaColors.textMuted),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingProfile) {
      return const Center(child: CircularProgressIndicator(color: LammaColors.accentGold));
    }

    String displayRole = 'عميل';
    if (activeRole.toLowerCase() == 'driver' || activeRole == 'كابتن') {
      displayRole = 'كابتن';
    }

    return Container(
      color: LammaColors.backgroundLight,
      child: Column(
        children: [
          // الهيدر
          Container(
            width: double.infinity, 
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 15.h, 
              bottom: 20.h, 
              left: 20.w, 
              right: 20.w
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [LammaColors.primaryNavy, LammaColors.royalGreen],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30.r), 
                bottomRight: Radius.circular(30.r)
              ),
              boxShadow: [
                BoxShadow(
                  color: LammaColors.royalGreen.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w), 
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, 
                        border: Border.all(color: LammaColors.accentGold, width: 2)
                      ), 
                      child: CircleAvatar(
                        radius: 35.r, 
                        backgroundColor: Colors.white, 
                        backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                        child: profileImageUrl.isEmpty ? Icon(Icons.person, size: 35.sp, color: Colors.grey) : null,
                      ),
                    ),
                    InkWell(
                      onTap: onEditProfile,
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: LammaColors.accentGold, 
                          shape: BoxShape.circle, 
                          border: Border.all(color: Colors.white, width: 2)
                        ),
                        child: Icon(Icons.edit_rounded, size: 14.sp, color: Colors.white),
                      ),
                    )
                  ],
                ),
                
                SizedBox(width: 16.w), 
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'أهلاً بك 👋', 
                        style: TextStyle(color: LammaColors.accentGold, fontSize: 12.sp, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        userName.isNotEmpty ? userName : 'مستخدم لَمَّة', 
                        style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        userEmail.isNotEmpty ? userEmail : 'جاري تحميل البيانات...', 
                        style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontFamily: 'Cairo'),
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: LammaColors.accentGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(color: LammaColors.accentGold.withOpacity(0.5), width: 1),
                        ),
                        child: Text(
                          displayRole, 
                          style: TextStyle(color: LammaColors.accentGold, fontSize: 11.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(50.r),
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24.sp),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(top: 20.h, left: 20.w, right: 20.w, bottom: 120.h),
              children: [
                _buildListTile(icon: Icons.person_outline_rounded, color: LammaColors.primaryNavy, title: 'تعديل البيانات الشخصية', onTap: onEditProfile),
                
                // 🟢 تم حذف زر إضافة الرقم من هنا 🚀

                _buildListTile(icon: Icons.lock_outline_rounded, color: LammaColors.info, title: 'تغيير كلمة المرور', onTap: onPasswordReset),
                
                _buildListTile(
                  icon: Icons.location_on_outlined, 
                  color: LammaColors.success, 
                  title: 'العناوين المحفوظة', 
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SavedAddressesPage()),
                    );
                  },
                ),
                
                _buildListTile(
                  icon: Icons.family_restroom_outlined, 
                  color: Colors.purpleAccent, 
                  title: 'الاشتراك العائلي (تتبع الأبناء)', 
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FamilyPage(),
                      ),
                    );
                  },
                ),
                _buildListTile(icon: Icons.support_agent_rounded, color: LammaColors.warning, title: 'الدعم الفني والشكاوى', onTap: onSupport),
                
                SizedBox(height: 24.h), 
                ElevatedButton.icon(
                  onPressed: () {
                    try {
                      context.read<PassengerMyRequestsCubit>().resetCubit();
                    } catch (e) {
                      debugPrint("PassengerMyRequestsCubit not found, skipping reset.");
                    }

                    try {
                      context.read<ProfileCubit>().resetProfile();
                    } catch (e) {
                      debugPrint("ProfileCubit not found, skipping reset.");
                    }

                    onLogout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LammaColors.error.withOpacity(0.1), 
                    foregroundColor: LammaColors.error, 
                    padding: EdgeInsets.symmetric(vertical: 14.h), 
                    elevation: 0, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  icon: Icon(Icons.logout_rounded, size: 24.sp), 
                  label: Text('تسجيل الخروج من المنصة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, fontFamily: 'Cairo')),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}