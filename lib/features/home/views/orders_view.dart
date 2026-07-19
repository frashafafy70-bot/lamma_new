import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// 🟢 استدعاء الترجمة
import 'package:lamma_new/l10n/app_localizations.dart';
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/theme/app_colors.dart';

class OrdersView extends StatefulWidget {
  final String activeRole;

  const OrdersView({super.key, required this.activeRole});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  late final Stream<List<DocumentSnapshot>> _activeOrdersStream;

  @override
  void initState() {
    super.initState();
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    _activeOrdersStream = FirebaseFirestore.instance
        .collection('trips')
        .where('passengerId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      var allDocs = snapshot.docs;

      var activeOrders = allDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final status = data['status'] ?? '';
        return status != 'completed' &&
            status != 'cancelled' &&
            status != 'canceled';
      }).toList();

      activeOrders.sort((a, b) {
        var dataA = a.data() as Map<String, dynamic>;
        var dataB = b.data() as Map<String, dynamic>;
        Timestamp? timeA = dataA['createdAt'];
        Timestamp? timeB = dataB['createdAt'];
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA);
      });

      return activeOrders;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: AppColors.backgroundLight,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: 60.h, bottom: 20.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryNavy, AppColors.royalGreen],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.r),
                  bottomRight: Radius.circular(30.r)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D1B4332),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                )
              ],
            ),
            child: Center(
              child: Text(
                l10n.activeOrdersTitle,
                style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: _activeOrdersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accentGold));
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text(l10n.errorLoadingOrders,
                          style: TextStyle(
                              color: AppColors.error, fontSize: 16.sp)));
                }

                var activeOrders = snapshot.data ?? [];

                if (activeOrders.isEmpty) {
                  return _buildEmptyState(l10n);
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                      left: 20.w, right: 20.w, top: 20.h, bottom: 100.h),
                  itemCount: activeOrders.length,
                  itemBuilder: (context, index) {
                    var orderData =
                        activeOrders[index].data() as Map<String, dynamic>? ??
                            {};
                    return _buildOrderCard(orderData, l10n);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(30.w),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x1AD4AF37),
            ),
            child: Icon(Icons.receipt_long_rounded,
                size: 80.sp, color: AppColors.accentGold),
          ),
          SizedBox(height: 24.h),
          Text(
            l10n.noActiveOrdersCurrent,
            style: TextStyle(
                fontSize: 18.sp,
                color: AppColors.textDark,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.requestCaptainNowSub,
            style: TextStyle(fontSize: 14.sp, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
      Map<String, dynamic> orderData, AppLocalizations l10n) {
    String status = orderData['status'] ?? 'pending';
    String category = orderData['tripCategory'] ?? l10n.tripWord;
    String price = orderData['price']?.toString() ?? l10n.determinedLater;

    String statusText = l10n.statusPending;
    Color statusColor = AppColors.warning;
    Color statusBgColor = const Color(0x1AFFA000);

    switch (status) {
      case 'accepted':
        statusText = l10n.statusAccepted;
        statusColor = AppColors.info;
        statusBgColor = const Color(0x1A29B6F6);
        break;
      case 'negotiating':
        statusText = l10n.statusNegotiating;
        statusColor = Colors.purple;
        statusBgColor = const Color(0x1A9C27B0);
        break;
      case 'arrived':
        statusText = l10n.statusArrived;
        statusColor = AppColors.success;
        statusBgColor = const Color(0x1A4CAF50);
        break;
      case 'in_progress':
        statusText = l10n.statusInProgress;
        statusColor = AppColors.accentGold;
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
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 15, offset: Offset(0, 5))
        ],
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
                      backgroundColor: const Color(0x1A0F172A),
                      child: Icon(Icons.local_taxi_rounded,
                          size: 20.sp, color: AppColors.primaryNavy),
                    ),
                    SizedBox(width: 10.w),
                    Text(category,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: AppColors.textDark)),
                  ],
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20.r)),
                  child: Text(statusText,
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: statusColor)),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(Icons.my_location_rounded,
                    size: 18.sp, color: AppColors.info),
                SizedBox(width: 8.w),
                Expanded(
                    child: Text(
                        orderData['pickupAddress'] ??
                            l10n.pickupLocationPlaceholder,
                        style: TextStyle(
                            fontSize: 13.sp, color: AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 18.sp, color: AppColors.error),
                SizedBox(width: 8.w),
                Expanded(
                    child: Text(
                        orderData['dropoffAddress'] ??
                            l10n.dropoffLocationPlaceholder,
                        style: TextStyle(
                            fontSize: 13.sp, color: AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: const Divider(height: 1, color: AppColors.dividerColor),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 16.sp, color: AppColors.textMuted),
                    SizedBox(width: 6.w),
                    Text(formattedTime,
                        style: TextStyle(
                            fontSize: 12.sp, color: AppColors.textMuted)),
                  ],
                ),
                // 🟢 معالجة عرض السعر باستخدام متغيرات اللغة
                Text(
                    price == l10n.determinedLater
                        ? price
                        : l10n.priceWithCurrency(price),
                    style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
