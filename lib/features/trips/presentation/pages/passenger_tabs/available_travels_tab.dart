// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../trip_chat_page.dart'; // تأكد إن مسار الشات صحيح بالنسبة لملفات مشروعك

class AvailableTravelsTab extends StatefulWidget {
  const AvailableTravelsTab({super.key});

  @override
  State<AvailableTravelsTab> createState() => _AvailableTravelsTabState();
}

class _AvailableTravelsTabState extends State<AvailableTravelsTab> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color royalGreen = const Color(0xFF1B4332);

  Future<void> _bookDriverPost(String tripId, String driverId) async {
    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
      'status': 'accepted', 
      'passengerId': currentUserId
    });
    if(mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: tripId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trips').where('isDriverPost', isEqualTo: true).where('status', isEqualTo: 'available').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var trips = snapshot.data!.docs;
        if (trips.isEmpty) return const Center(child: Text('لا توجد رحلات سفر مطروحة حاليا', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            var data = trips[index].data() as Map<String, dynamic>;
            return Card(
              elevation: 2, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الكابتن: ${data['driverName']}', style: TextStyle(fontWeight: FontWeight.bold, color: royalGreen, fontFamily: 'Cairo')),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)), child: Text('سعر: ${data['price']} ج', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const Divider(),
                    Text('من: ${data['fromCity']} الى: ${data['toCity']}', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('المركبة: ${data['vehicleType'] ?? 'سيارة'} | المقاعد المتاحة: ${data['availableSeats']}', style: TextStyle(color: Colors.grey.shade700, fontFamily: 'Cairo')),
                    const SizedBox(height: 4),
                    Text('الموعد: ${data['time']}', style: TextStyle(color: Colors.grey.shade700, fontFamily: 'Cairo')),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: royalGreen, foregroundColor: Colors.white), onPressed: () => _bookDriverPost(trips[index].id, data['driverId']), icon: const Icon(Icons.event_seat_rounded, size: 18), label: const Text('حجز مقعد والتواصل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))))
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}