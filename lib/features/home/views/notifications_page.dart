import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_route/auto_route.dart';
import 'package:lamma_new/l10n/app_localizations.dart';

import 'package:lamma_new/features/notifications/presentation/cubit/notification_state.dart'
    as notif;
import 'package:lamma_new/features/notifications/presentation/cubit/notification_cubit.dart';

@RoutePage()
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: primaryNavy,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(l10n.notificationsTitle,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp)),
        ),
        body: BlocBuilder<NotificationCubit, notif.NotificationState>(
          builder: (context, state) {
            if (state.status == notif.NotificationStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_rounded,
                        size: 60.sp, color: Colors.grey.shade400),
                    SizedBox(height: 16.h),
                    Text(l10n.noNotifications,
                        style: TextStyle(
                            fontSize: 16.sp, color: Colors.grey.shade600)),
                  ],
                ),
              );
            }
            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              itemCount: state.notifications.length,
              itemBuilder: (context, index) {
                var notify = state.notifications[index];
                return Card(
                  elevation: 1,
                  margin: EdgeInsets.only(bottom: 12.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    leading: CircleAvatar(
                        backgroundColor: goldAccent.withOpacity(0.2),
                        child: Icon(Icons.notifications_active,
                            color: goldAccent)),
                    title: Text(notify.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    subtitle: Text(notify.body,
                        style: const TextStyle(fontFamily: 'Cairo')),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
