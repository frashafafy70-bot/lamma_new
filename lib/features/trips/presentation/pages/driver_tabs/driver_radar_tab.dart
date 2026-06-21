// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../trip_chat_page.dart';

class DriverRadarTab extends StatefulWidget {
  final TabController tabController;
  const DriverRadarTab({super.key, required this.tabController});

  @override
  State<DriverRadarTab> createState() => _DriverRadarTabState();
}

class _DriverRadarTabState extends State<DriverRadarTab> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color royalGreen = const Color(0xFF1B4332);


  Future<void> _acceptTripRequest(String tripId, String agreedPrice) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'status': 'accepted', 
        'driverId': currentUserId, 
        'driverName': 'كابتن لمة',
        'finalPrice': agreedPrice
      });
      if(mounted) widget.tabController.animateTo(2); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في الاتصال')));
    }
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
            labelText: 'اكتب سعرك المقترح (جنيه)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
          ),
        ), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: royalGreen),
            onPressed: () async { 
              if (offerCtrl.text.isEmpty) return;
              await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
                'status': 'negotiating', 
                'driverId': currentUserId, 
                'negotiationPrice': offerCtrl.text,
                'lastNegotiator': 'driver'
              }); 
              if(mounted) { 
                Navigator.pop(ctx); 
                widget.tabController.animateTo(2); 
              } 
            }, 
            child: const Text('إرسال العرض', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold))
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .where('isDriverPost', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: royalGreen));
        
        var trips = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String status = data['status'] ?? 'pending';
          // عرض الطلبات الجديدة أو اللي الكابتن بيفاوض عليها هو شخصياً
          return status == 'pending' || (status == 'negotiating' && data['driverId'] == currentUserId);
        }).toList();

        if (trips.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.radar_outlined, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                const Text('لا توجد طلبات حالياً', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            var doc = trips[index];
            var data = doc.data() as Map<String, dynamic>;
            bool isErrand = data['tripCategory'] == 'طلبات';
            bool isNegotiating = data['status'] == 'negotiating';
            
            return Card(
              elevation: 4, margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                          decoration: BoxDecoration(color: isErrand ? Colors.indigo.shade50 : royalGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), 
                          child: Text(isErrand ? '🛒 شراء طلبات' : '🚕 مشوار توصيل', style: TextStyle(color: isErrand ? Colors.indigo : royalGreen, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12))
                        ),
                        if (isNegotiating)
                          const Text('جاري التفاوض..', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('العميل: ${data['passengerName'] ?? 'عميل'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(isErrand ? 'من: ${data['pickup']}\nإلى: ${data['destination']}' : '📍 من: ${data['pickup']}\n🏁 إلى: ${data['destination']}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10), 
                      decoration: BoxDecoration(color: isNegotiating ? Colors.orange.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(8)), 
                      child: Text(isNegotiating ? 'عرضك الأخير: ${data['negotiationPrice']} ج' : 'سعر العميل: ${data['suggestedPrice'] ?? '0'} ج', textAlign: TextAlign.center, style: TextStyle(color: isNegotiating ? Colors.orange.shade800 : Colors.green.shade800, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    if (!isNegotiating)
                      Row(
                        children: [
                          Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: royalGreen), onPressed: () => _acceptTripRequest(doc.id, data['suggestedPrice'].toString()), child: const Text('قبول فوراً'))),
                          const SizedBox(width: 8),
                          Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), onPressed: () => _showNegotiationDialog(doc.id), child: const Text('تفاوض'))),
                        ],
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 45)),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: doc.id))),
                        child: const Text('متابعة المحادثة')
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