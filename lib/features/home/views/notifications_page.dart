import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 🟢 تم إضافة hide TextDirection لحل مشكلة التضارب
import 'package:intl/intl.dart' hide TextDirection; 

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryNavy = const Color(0xFF0F172A);
    final Color royalGreen = const Color(0xFF1B4332);
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: primaryNavy,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'الإشعارات',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: currentUserId.isEmpty
            ? Center(
                child: Text(
                  'يرجى تسجيل الدخول لعرض الإشعارات',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: primaryNavy),
                ),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserId)
                    .collection('notifications')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: royalGreen));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'حدث خطأ في تحميل الإشعارات',
                        style: TextStyle(fontFamily: 'Cairo', color: Colors.red.shade700, fontSize: 16.sp),
                      ),
                    );
                  }

                  final notifications = snapshot.data?.docs ?? [];

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_rounded, size: 100.sp, color: Colors.grey.shade300),
                          SizedBox(height: 20.h),
                          Text(
                            'لا توجد إشعارات حالياً',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      var data = notifications[index].data() as Map<String, dynamic>;
                      String docId = notifications[index].id;
                      bool isRead = data['isRead'] ?? false;
                      String title = data['title'] ?? 'إشعار جديد';
                      String body = data['body'] ?? '';
                      
                      String formattedTime = '';
                      if (data['createdAt'] != null) {
                        DateTime date = (data['createdAt'] as Timestamp).toDate();
                        formattedTime = DateFormat('yyyy/MM/dd hh:mm a').format(date);
                      }

                      return GestureDetector(
                        onTap: () {
                          if (!isRead) {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUserId)
                                .collection('notifications')
                                .doc(docId)
                                .update({'isRead': true});
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.white : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(16.r),
                            // 🟢 تم استبدال withOpacity بـ withValues
                            border: Border.all(
                              color: isRead ? Colors.grey.shade200 : royalGreen.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20.r,
                                backgroundColor: isRead ? primaryNavy.withValues(alpha: 0.1) : royalGreen.withValues(alpha: 0.1),
                                child: Icon(
                                  isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                                  color: isRead ? primaryNavy : royalGreen,
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                              fontSize: 15.sp,
                                              color: primaryNavy,
                                            ),
                                          ),
                                        ),
                                        if (!isRead)
                                          Container(
                                            width: 8.w,
                                            height: 8.w,
                                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      body,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 13.sp,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      formattedTime,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11.sp,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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