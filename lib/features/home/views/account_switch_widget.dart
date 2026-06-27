import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// تم تعديل اسم الكلاس هنا عشان يطابق الاستدعاء
class AccountSwitchWidget extends StatelessWidget {
  final String currentRole;

  const AccountSwitchWidget({
    super.key,
    required this.currentRole,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF131E31), // الكحلي الموحد الفخم
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFF3C444)),
            onPressed: () => Navigator.pop(context), // رجوع بدون تغيير
          ),
          title: Text(
            'اختر وضع الحساب',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'بأي صفة تريد استخدام التطبيق الآن؟',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 24.h),
              
              // الكروت الفخمة تحت بعضها
              _buildRoleCard(context, 'customer', 'عميل', Icons.person_rounded),
              _buildRoleCard(context, 'captain', 'كابتن', Icons.local_taxi_rounded),
              _buildRoleCard(context, 'lawyer', 'محامي', Icons.gavel_rounded),
              _buildRoleCard(context, 'doctor', 'طبيب', Icons.medical_services_rounded),
              _buildRoleCard(context, 'nurse', 'تمريض', Icons.healing_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, String roleKey, String roleName, IconData icon) {
    bool isSelected = currentRole == roleKey;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: () {
          // نقفل الصفحة ونرجع المهنة اللي اختارها للشاشة الرئيسية
          Navigator.pop(context, roleKey);
        },
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF3C444).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? const Color(0xFFF3C444) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF3C444) : Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? const Color(0xFF131E31) : Colors.white70,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Text(
                roleName,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? const Color(0xFFF3C444) : Colors.white,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: const Color(0xFFF3C444),
                  size: 28.sp,
                ),
            ],
          ),
        ),
      ),
    );
  }
}