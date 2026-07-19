import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:lamma_new/features/notifications/presentation/cubit/notification_state.dart'
    as notif;
import 'package:lamma_new/features/auth/cubit/auth_cubit.dart';
import 'package:lamma_new/features/profile/presentation/cubit/profile_cubit.dart';

class HomeDialogsHelper {
  // 1. بوتوم شيت الإشعارات
  static void showNotificationsBottomSheet(BuildContext context) {
    context.read<NotificationCubit>().markAllNotificationsAsRead();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
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
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10.r))),
                SizedBox(height: 16.h),
                Text('الإشعارات',
                    style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                        fontFamily: 'Cairo')),
                const Divider(),
                Expanded(
                  child:
                      BlocBuilder<NotificationCubit, notif.NotificationState>(
                    builder: (context, state) {
                      if (state.status == notif.NotificationStatus.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state.notifications.isEmpty) {
                        return Center(
                            child: Text('لا توجد إشعارات حالياً 🔕',
                                style: TextStyle(fontSize: 16.sp)));
                      }
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: state.notifications.length,
                        itemBuilder: (context, index) {
                          var notifItem = state.notifications[index];
                          return ListTile(
                            leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.accentGold.withOpacity(0.2),
                                child: const Icon(Icons.notifications_active,
                                    color: AppColors.accentGold)),
                            title: Text(notifItem['title'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo')),
                            subtitle: Text(notifItem['body'] ?? '',
                                style: const TextStyle(fontFamily: 'Cairo')),
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

  // 2. ديالوج إعادة تعيين كلمة المرور
  static void showPasswordResetDialog(
      BuildContext pageContext, String phone, String email) {
    showDialog(
        context: pageContext,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.r)),
              title: Row(textDirection: TextDirection.rtl, children: [
                const Icon(Icons.lock_reset_rounded,
                    color: AppColors.primaryDark),
                SizedBox(width: 8.w),
                const Text('تغيير كلمة المرور',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
              ]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('اختر طريقة الاستعادة لإعادة تعيين كلمة المرور:',
                      style: TextStyle(fontSize: 14),
                      textDirection: TextDirection.rtl),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        side: const BorderSide(color: AppColors.primaryDark),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(vertical: 10.h)),
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('إرسال رابط للبريد',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (email.isNotEmpty) {
                        pageContext
                            .read<AuthCubit>()
                            .sendPasswordResetEmail(email: email);
                      } else {
                        ScaffoldMessenger.of(pageContext).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'البريد الإلكتروني غير متوفر، يرجى استكمال بياناتك.',
                                    style: TextStyle(fontFamily: 'Cairo')),
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
                    label: const Text('إرسال كود للهاتف',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (phone.isNotEmpty) {
                        String fullPhone = phone.startsWith('+20')
                            ? phone
                            : '+20${phone.replaceFirst(RegExp(r'^0+'), '')}';
                        pageContext
                            .read<AuthCubit>()
                            .sendPasswordResetOtp(phone: fullPhone);
                      } else {
                        ScaffoldMessenger.of(pageContext).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'رقم الهاتف غير متوفر، يرجى استكمال بياناتك.',
                                    style: TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: Colors.red));
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إلغاء',
                        style: TextStyle(color: Colors.grey))),
              ],
            ));
  }

  // 3. ديالوج الدعم الفني
  static void showSupportDialog(BuildContext pageContext) {
    final TextEditingController complaintCtrl = TextEditingController();
    showDialog(
        context: pageContext,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.r)),
              title: Row(textDirection: TextDirection.rtl, children: [
                const Icon(Icons.support_agent_rounded, color: Colors.orange),
                SizedBox(width: 8.w),
                const Text('الدعم الفني والشكاوى',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
              ]),
              content: TextField(
                controller: complaintCtrl,
                maxLines: 4,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                    hintText: 'اكتب شكوتك، مشكلتك، أو مقترحك هنا...',
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
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إلغاء',
                        style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalGreen,
                      foregroundColor: Colors.white),
                  onPressed: () {
                    if (complaintCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    pageContext
                        .read<ProfileCubit>()
                        .sendSupportTicket(message: complaintCtrl.text.trim());
                  },
                  child: const Text('إرسال الدعم',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ));
  }
}
