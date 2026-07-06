import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';

class PassengerTravelBookingsList extends StatelessWidget {
  const PassengerTravelBookingsList({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trip_bookings')
          .where('passengerId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h, bottom: 8.h),
              child: Text('حجوزات رحلات السفر', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.royalGreen)),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var booking = snapshot.data!.docs[index];
                var data = booking.data() as Map<String, dynamic>;
                bool isAccepted = data['status'] == 'accepted';
                
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: BorderSide(color: isAccepted ? Colors.green : Colors.orange.shade300, width: 1.5)),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    leading: CircleAvatar(
                      backgroundColor: isAccepted ? Colors.green.shade50 : Colors.orange.shade50,
                      child: Icon(Icons.directions_bus_filled_rounded, color: isAccepted ? Colors.green : Colors.orange)
                    ),
                    title: Text('حجز مقاعد سفر', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
                    subtitle: Text(
                      'المقاعد: ${data['seats']} | الحالة: ${isAccepted ? 'تم القبول ✅' : 'قيد الانتظار ⏳'}', 
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: isAccepted ? Colors.green.shade700 : Colors.orange.shade800, fontWeight: FontWeight.bold)
                    ),
                    trailing: isAccepted 
                      ? IconButton(
                          icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.royalGreen),
                          tooltip: 'تواصل مع السائق',
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: data['tripId'])));
                          },
                        )
                      : const Icon(Icons.hourglass_top_rounded, color: Colors.orange),
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