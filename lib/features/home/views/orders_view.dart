import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrdersView extends StatelessWidget {
  final String activeRole;

  const OrdersView({super.key, required this.activeRole});

  @override
  Widget build(BuildContext context) {
    final Color primaryNavy = const Color(0xFF0F172A);
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Column(
      children: [
        // 🟢 الهيدر الفخم
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: 60.h, bottom: 20.h),
          decoration: BoxDecoration(
            color: primaryNavy,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30.r), bottomRight: Radius.circular(30.r)),
          ),
          child: Center(
            child: Text('متابعة طلباتي النشطة 🚀', style: TextStyle(fontFamily: 'Cairo', fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),

        // 🟢 المحتوى الحي (Live Stream) من فايربيز
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // تم إزالة orderBy لتجنب خطأ الـ Composite Index في فايربيز
            stream: FirebaseFirestore.instance
                .collection('trips')
                .where('passengerId', isEqualTo: currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('حدث خطأ في تحميل الطلبات', style: TextStyle(fontFamily: 'Cairo', color: Colors.red.shade700)));
              }

              // جلب كل الطلبات
              var allDocs = snapshot.data?.docs ?? [];

              // تصفية الطلبات النشطة فقط 
              var activeOrders = allDocs.where((doc) {
                final status = doc['status'] ?? '';
                // التأكد من الحالتين تحسباً لأي خطأ إملائي في الحفظ
                return status != 'completed' && status != 'cancelled' && status != 'canceled';
              }).toList();

              // 🟢 الترتيب البرمجي (Sorting in memory) الأحدث أولاً
              activeOrders.sort((a, b) {
                var dataA = a.data() as Map<String, dynamic>;
                var dataB = b.data() as Map<String, dynamic>;
                Timestamp? timeA = dataA['createdAt'];
                Timestamp? timeB = dataB['createdAt'];
                if (timeA == null && timeB == null) return 0;
                if (timeA == null) return 1;
                if (timeB == null) return -1;
                return timeB.compareTo(timeA); // تنازلي
              });

              if (activeOrders.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 20.h, bottom: 100.h),
                itemCount: activeOrders.length,
                itemBuilder: (context, index) {
                  var orderData = activeOrders[index].data() as Map<String, dynamic>;
                  return _buildOrderCard(orderData);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 🟢 حالة "لا توجد طلبات" متطابقة تماماً مع التصميم
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 100.sp, color: Colors.grey.shade300),
          SizedBox(height: 20.h),
          Text('ليس لديك أي طلبات نشطة حالية.', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // 🟢 تصميم كارت الطلب الفخم 
  Widget _buildOrderCard(Map<String, dynamic> orderData) {
    String status = orderData['status'] ?? 'pending';
    String category = orderData['tripCategory'] ?? 'رحلة';
    String price = orderData['price']?.toString() ?? 'يحدد لاحقاً';
    
    // تحويل حالة الطلب للغة العربية
    String statusText = 'قيد الانتظار';
    Color statusColor = Colors.orange;
    
    switch (status) {
      case 'accepted': statusText = 'تم القبول'; statusColor = Colors.blue; break;
      case 'negotiating': statusText = 'جاري التفاوض'; statusColor = Colors.purple; break;
      case 'arrived': statusText = 'السائق بالخارج'; statusColor = Colors.green; break;
      case 'in_progress': statusText = 'الرحلة مستمرة'; statusColor = const Color(0xFFD4AF37); break;
    }

    // جلب الوقت والتاريخ
    String formattedTime = '';
    if (orderData['createdAt'] != null) {
      DateTime date = (orderData['createdAt'] as Timestamp).toDate();
      formattedTime = DateFormat('hh:mm a').format(date);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16.r,
                      backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.1),
                      child: Icon(Icons.local_taxi_rounded, size: 18.sp, color: const Color(0xFF0F172A)),
                    ),
                    SizedBox(width: 10.w),
                    Text(category, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20.r)),
                  child: Text(statusText, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold, color: statusColor)),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(Icons.my_location_rounded, size: 16.sp, color: Colors.grey.shade500),
                SizedBox(width: 8.w),
                Expanded(child: Text(orderData['pickupAddress'] ?? 'موقع الانطلاق', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 16.sp, color: Colors.redAccent),
                SizedBox(width: 8.w),
                Expanded(child: Text(orderData['dropoffAddress'] ?? 'وجهة الوصول', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الوقت: $formattedTime', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade500)),
                Text('$price ج.م', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1B4332))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}