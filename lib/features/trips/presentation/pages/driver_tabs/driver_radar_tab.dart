// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverRadarTab extends StatefulWidget {
  final TabController tabController;
  const DriverRadarTab({super.key, required this.tabController});

  @override
  State<DriverRadarTab> createState() => _DriverRadarTabState();
}

class _DriverRadarTabState extends State<DriverRadarTab> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color royalGreen = const Color(0xFF1B4332);

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'الآن';
    DateTime dt = timestamp.toDate();
    String amPm = dt.hour >= 12 ? 'م' : 'ص';
    int hour12 = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    String minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}/${dt.month}/${dt.day} - $hour12:$minute $amPm';
  }

  Future<void> _acceptTripRequest(String tripId, String agreedPrice) async {
    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
      'status': 'accepted', 
      'driverId': currentUserId, 
      'driverName': 'كابتن', 
      'finalPrice': agreedPrice
    });
    if(mounted) widget.tabController.animateTo(2); 
  }

  void _showNegotiationDialog(String tripId) {
    TextEditingController offerCtrl = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('التفاوض على الأجرة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), 
        content: TextField(
          controller: offerCtrl, 
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'اكتب سعرك المقترح',
            suffixText: 'جنيه',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
          ),
        ), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: royalGreen),
            onPressed: () async { 
              if (offerCtrl.text.isEmpty) return;
              await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
                'status': 'negotiating', 
                'driverId': currentUserId, 
                'driverName': 'كابتن لمة', 
                'negotiationPrice': offerCtrl.text,
                'lastNegotiator': 'driver'
              }); 
              if(mounted) { 
                Navigator.pop(ctx); 
                widget.tabController.animateTo(2); 
              } 
            }, 
            child: const Text('إرسال', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold))
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trips').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('حدث خطأ في الاتصال', style: TextStyle(fontFamily: 'Cairo', color: Colors.red)));
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: royalGreen));
        
        var trips = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return data['isDriverPost'] != true;
        }).toList();

        trips.sort((a, b) {
          var timeA = (a.data() as Map)['createdAt'] as Timestamp?;
          var timeB = (b.data() as Map)['createdAt'] as Timestamp?;
          if (timeA == null) return 1; if (timeB == null) return -1;
          return timeB.compareTo(timeA);
        });

        if (trips.isEmpty) return Center(child: Text('رادار الطلبات شغال.. لا يوجد طلبات حاليا', style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Cairo')));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            var doc = trips[index];
            var data = doc.data() as Map<String, dynamic>;
            bool isErrand = data['tripCategory'] == 'طلبات';

            return Card(
              elevation: 4, margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isErrand ? Colors.indigo.shade50 : royalGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(isErrand ? 'طلب شراء أوردر' : 'مشوار توصيل', style: TextStyle(color: isErrand ? Colors.indigo : royalGreen, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12))), // تم التعديل هنا
                        Text(_formatDateTime(data['createdAt']), style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(isErrand ? 'العميل: ${data['passengerName']}' : 'المركبة: ${data['vehicleType']} - العميل: ${data['passengerName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo', color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(isErrand ? 'من (مكان الشراء): ${data['pickup']}\nإلى (مكان التسليم): ${data['destination']}' : 'من: ${data['pickup']}\nإلى: ${data['destination']}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)), child: Text(isErrand ? 'أجرة التوصيل المقترحة: ${data['suggestedPrice']} جنيه' : 'سعر العميل المقترح: ${data['suggestedPrice']} جنيه', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: royalGreen), onPressed: () => _acceptTripRequest(doc.id, data['suggestedPrice']), child: const Text('قبول بالأجرة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)))),
                        const SizedBox(width: 8),
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), onPressed: () => _showNegotiationDialog(doc.id), child: const Text('عرض أجرة آخرى', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 11)))),
                      ],
                    )
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