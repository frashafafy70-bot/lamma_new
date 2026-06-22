import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade100)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
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
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 30, bottom: 40, left: 20, right: 20),
          decoration: BoxDecoration(
            color: primaryNavy, 
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
            boxShadow: [BoxShadow(color: primaryNavy.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))]
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: goldAccent, width: 2)), 
                    child: CircleAvatar(
                      radius: 50, backgroundColor: Colors.white, 
                      backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                      child: profileImageUrl.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                    )
                  ),
                  InkWell(
                    onTap: onEditProfile,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: goldAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Text(userName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              const SizedBox(height: 4),
              Text(userEmail, style: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontFamily: 'Cairo')),
            ],
          ),
        ),
        
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('إعدادات الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo')),
              const SizedBox(height: 16),
              
              _buildListTile(icon: Icons.person_outline_rounded, color: primaryNavy, title: 'تعديل البيانات الشخصية', onTap: onEditProfile),
              _buildListTile(icon: Icons.lock_outline_rounded, color: Colors.blueAccent, title: 'تغيير كلمة المرور', onTap: onPasswordReset),
              _buildListTile(icon: Icons.location_on_outlined, color: Colors.green, title: 'العناوين المحفوظة', onTap: () {}),
              
              const SizedBox(height: 24),
              const Text('المساعدة والدعم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo')),
              const SizedBox(height: 16),
              
              _buildListTile(icon: Icons.support_agent_rounded, color: Colors.orange, title: 'الدعم الفني والشكاوى', onTap: onSupport),
              
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: onLogout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.logout_rounded), label: const Text('تسجيل الخروج من المنصة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
              )
            ],
          ),
        )
      ],
    );
  }
}