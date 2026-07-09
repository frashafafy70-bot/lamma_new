import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:lamma_new/theme/app_colors.dart';

class OrdersView extends StatefulWidget {
  final String activeRole;

  const OrdersView({super.key, required this.activeRole});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  // 🟢 فصل الستريم عن دالة البناء لعدم إعادة إنشائه
  late final Stream<List<DocumentSnapshot>> _activeOrdersStream;

  @override
  void initState() {
    super.initState();
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // 🟢 عملت الفلترة والترتيب جوا الستريم نفسه عشان نخفف الحمل عن واجهة المستخدم (UI)
    _activeOrdersStream = FirebaseFirestore.instance
        .collection('trips')
        .where('passengerId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      var allDocs = snapshot.docs;
      // الفلترة
      var activeOrders = allDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final status = data['status'] ?? '';
        return status != 'completed' && status != 'cancelled' && status != 'canceled';
      }).toList();

      // الترتيب
      activeOrders.sort((a, b) {
        var dataA = a.data() as Map<String, dynamic>;
        var dataB = b.data() as Map<String, dynamic>;
        Timestamp? timeA = dataA['createdAt'];
        Timestamp? timeB = dataB['createdAt'];
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA); // الأحدث فوق
      });

      return activeOrders;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LammaColors.backgroundLight,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: 60.h, bottom: 20.h),
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
              boxShadow: const [ // 🟢 استخدام Const للظل لتحسين الأداء
                BoxShadow(
                  color: Color(0x4D1B4332), // Hex لـ royalGreen withOpacity(0.3)
                  blurRadius: 15,
                  offset: Offset(0, 5),
                )
              ],
            ),
            child: Center(
              child: Text(
                'متابعة طلباتي النشطة', 
                style: TextStyle(fontFamily: 'Cairo', fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: _activeOrdersStream, // 🟢 الستريم المفلتر والجاهز
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: LammaColors.accentGold));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('حدث خطأ في تحميل الطلبات', style: TextStyle(fontFamily: 'Cairo', color: LammaColors.error, fontSize: 16.sp))
                  );
                }

                var activeOrders = snapshot.data ?? [];

                if (activeOrders.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 20.h, bottom: 100.h),
                  itemCount: activeOrders.length,
                  itemBuilder: (context, index) {
                    var orderData = activeOrders[index].data() as Map<String, dynamic>? ?? {};
                    return _buildOrderCard(orderData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(30.w),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x1AD4AF37), // Hex لـ accentGold withOpacity(0.1)
            ),
            child: Icon(Icons.receipt_long_rounded, size: 80.sp, color: LammaColors.accentGold),
          ),
          SizedBox(height: 24.h),
          Text(
            'ليس لديك أي طلبات نشطة حالية', 
            style: TextStyle(fontFamily: 'Cairo', fontSize: 18.sp, color: LammaColors.textDark, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            'اطلب كابتن الآن وستظهر رحلتك هنا', 
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: LammaColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> orderData) {
    String status = orderData['status'] ?? 'pending';
    String category = orderData['tripCategory'] ?? 'رحلة';
    String price = orderData['price']?.toString() ?? 'يحدد لاحقاً';
    
    String statusText = 'قيد الانتظار';
    Color statusColor = LammaColors.warning;
    Color statusBgColor = const Color(0x1AFFA000); // Default Warning bg

    switch (status) {
      case 'accepted': 
        statusText = 'تم القبول'; 
        statusColor = LammaColors.info; 
        statusBgColor = const Color(0x1A29B6F6); 
        break;
      case 'negotiating': 
        statusText = 'جاري التفاوض'; 
        statusColor = Colors.purple; 
        statusBgColor = const Color(0x1A9C27B0); 
        break;
      case 'arrived': 
        statusText = 'السائق بالخارج'; 
        statusColor = LammaColors.success; 
        statusBgColor = const Color(0x1A4CAF50); 
        break;
      case 'in_progress': 
        statusText = 'الرحلة مستمرة'; 
        statusColor = LammaColors.accentGold; 
        statusBgColor = const Color(0x1AD4AF37); 
        break;
    }

    String formattedTime = '';
    if (orderData['createdAt'] != null) {
      DateTime date = (orderData['createdAt'] as Timestamp).toDate();
      formattedTime = DateFormat('hh:mm a').format(date);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: LammaColors.cardWhite,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: LammaColors.dividerColor),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 15, offset: Offset(0, 5))],
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
                      radius: 18.r,
                      backgroundColor: const Color(0x1A0F172A), // LammaColors.primaryNavy withOpacity(0.1)
                      child: Icon(Icons.local_taxi_rounded, size: 20.sp, color: LammaColors.primaryNavy),
                    ),
                    SizedBox(width: 10.w),
                    Text(category, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: LammaColors.textDark)),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(20.r)),
                  child: Text(statusText, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold, color: statusColor)),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(Icons.my_location_rounded, size: 18.sp, color: LammaColors.info),
                SizedBox(width: 8.w),
                Expanded(child: Text(orderData['pickupAddress'] ?? 'موقع الانطلاق', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: LammaColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 18.sp, color: LammaColors.error),
                SizedBox(width: 8.w),
                Expanded(child: Text(orderData['dropoffAddress'] ?? 'وجهة الوصول', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: LammaColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: const Divider(height: 1, color: LammaColors.dividerColor),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 16.sp, color: LammaColors.textMuted),
                    SizedBox(width: 6.w),
                    Text(formattedTime, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: LammaColors.textMuted)),
                  ],
                ),
                Text('$price ج.م', style: TextStyle(fontFamily: 'Cairo', fontSize: 18.sp, fontWeight: FontWeight.bold, color: LammaColors.success)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}