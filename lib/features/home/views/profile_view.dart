import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 

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

  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);

  Widget _buildListTile({required IconData icon, required Color color, required String title, required VoidCallback onTap}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15.r), 
        border: Border.all(color: Colors.grey.shade100),
      ),
      // 🟢 تم حذف إشارة (= ListTile) الزيادة اللي كانت مسببة الأزمة
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w), 
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), 
            borderRadius: BorderRadius.circular(10.r),
          ), 
          child: Icon(icon, color: color, size: 24.sp),
        ),
        title: Text(title, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15.sp)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16.sp, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingProfile) {
      return Center(child: CircularProgressIndicator(color: primaryNavy));
    }

    return Column(
      children: [
        Container(
          width: double.infinity, 
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 30.h, bottom: 35.h, left: 20.w, right: 20.w),
          decoration: BoxDecoration(
            color: primaryNavy, 
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40.r)),
            boxShadow: [BoxShadow(color: primaryNavy.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))]
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: EdgeInsets.all(4.w), 
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: goldAccent, width: 2)), 
                    child: CircleAvatar(
                      radius: 50.r, 
                      backgroundColor: Colors.white, 
                      backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                      child: profileImageUrl.isEmpty ? Icon(Icons.person, size: 50.sp, color: Colors.grey) : null,
                    ),
                  ),
                  InkWell(
                    onTap: onEditProfile,
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(color: goldAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: Icon(Icons.edit_rounded, size: 18.sp, color: Colors.white),
                    ),
                  )
                ],
              ),
              SizedBox(height: 16.h),
              Text(userName, style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              SizedBox(height: 4.h),
              Text(userEmail, style: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp, fontFamily: 'Cairo')),
              SizedBox(height: 10.h),
              
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: goldAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: goldAccent.withValues(alpha: 0.5), width: 1),
                ),
                child: Text(
                  activeRole,
                  style: TextStyle(color: goldAccent, fontSize: 12.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(20.w),
            children: [
              Text('إعدادات الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, fontFamily: 'Cairo')),
              SizedBox(height: 16.h),
              
              _buildListTile(icon: Icons.person_outline_rounded, color: primaryNavy, title: 'تعديل البيانات الشخصية', onTap: onEditProfile),
              _buildListTile(icon: Icons.lock_outline_rounded, color: Colors.blueAccent, title: 'تغيير كلمة المرور', onTap: onPasswordReset),
              _buildListTile(icon: Icons.location_on_outlined, color: Colors.green, title: 'العناوين المحفوظة', onTap: () {}),
              
              SizedBox(height: 24.h),
              Text('المساعدة والدعم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, fontFamily: 'Cairo')),
              SizedBox(height: 16.h),
              
              _buildListTile(icon: Icons.support_agent_rounded, color: Colors.orange, title: 'الدعم الفني والشكاوى', onTap: onSupport),
              
              SizedBox(height: 30.h),
              ElevatedButton.icon(
                onPressed: onLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50, 
                  foregroundColor: Colors.red, 
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
    );
  }
}