import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverTravelBookingsList extends StatelessWidget {
  const DriverTravelBookingsList({super.key});

  @override
  Widget build(BuildContext context) {
    final String driverId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trip_bookings')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        // لو مفيش داتا أو مفيش حجوزات، مياخدش مساحة خالص في الشاشة
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                  left: 16.w, right: 16.w, top: 16.h, bottom: 8.h),
              child: Text('طلبات حجز السفر (في الانتظار)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: const Color(0xFFD4AF37))),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var booking = snapshot.data!.docs[index];
                var data = booking.data() as Map<String, dynamic>;

                return Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 12.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      side: BorderSide(
                          color:
                              const Color(0xFFD4AF37).withValues(alpha: 0.5))),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade50,
                        child: const Icon(Icons.event_seat_rounded,
                            color: Colors.orange)),
                    title: Text('طلب حجز مقاعد سفر',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14.sp)),
                    subtitle: Text('العميل يطلب: ${data['seats']} مقاعد',
                        style: TextStyle(fontSize: 13.sp)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4332),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r))),
                      onPressed: () {
                        // قبول الحجز وتحديث حالته
                        booking.reference.update({'status': 'accepted'});
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('تم قبول الحجز بنجاح!',
                                    style: TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: Colors.green));
                      },
                      child: Text('قبول',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: const Divider(thickness: 1.5),
            ),
          ],
        );
      },
    );
  }
}
