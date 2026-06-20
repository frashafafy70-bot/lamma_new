// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../trip_chat_page.dart';

class DriverActiveTripsTab extends StatefulWidget {
  const DriverActiveTripsTab({super.key});

  @override
  State<DriverActiveTripsTab> createState() => _DriverActiveTripsTabState();
}

class _DriverActiveTripsTabState extends State<DriverActiveTripsTab> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color royalGreen = const Color(0xFF1B4332);
  final Map<String, bool> _cancellationTimers = {};

  Future<void> _deleteTripForUser(String tripId) async {
    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
      'isDeletedForDriver': true
    });
  }

  Future<void> _cancelTrip(String tripId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الرحلة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('هل أنت متأكد من إلغاء هذه الرحلة؟ سيتم إبلاغ الطرف الآخر.', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('نعم، إلغاء', style: TextStyle(color: Colors.white, fontFamily: 'Cairo'))),
        ],
      )
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'status': 'canceled',
        'canceledBy': 'driver' 
      });
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الرحلة بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.orange));
      }
    }
  }

  Future<void> _acceptOffer(String tripId, String acceptedPrice) async {
    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
      'status': 'accepted',
      'finalPrice': acceptedPrice
    });
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
                'negotiationPrice': offerCtrl.text,
                'lastNegotiator': 'driver'
              }); 
              if(mounted) Navigator.pop(ctx); 
            }, 
            child: const Text('إرسال', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold))
          )
        ]
      )
    );
  }

  void _showRatingDialog(String tripId) {
    int stars = 5; 

    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                const Text('تم إنهاء الرحلة!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) => IconButton(icon: Icon(index < stars ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 35), onPressed: () => setDialogState(() => stars = index + 1)))),
                
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: royalGreen, minimumSize: const Size(double.infinity, 45)), 
                  onPressed: () async { 
                    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
                      'driverRatingForPassenger': stars, 
                      'status': 'completed'
                    }); 
                    if(mounted) Navigator.pop(ctx); 
                  }, 
                  child: const Text('إرسال التقييم', style: TextStyle(color: Colors.white, fontFamily: 'Cairo'))
                )
              ],
            ),
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trips').where('driverId', isEqualTo: currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var trips = snapshot.data!.docs.where((doc) {
           var data = doc.data() as Map<String, dynamic>;
           bool isNotDeleted = data['isDeletedForDriver'] != true;
           bool isValidStatus = data['status'] == 'negotiating' || data['status'] == 'accepted' || data['status'] == 'canceled';
           return isNotDeleted && isValidStatus;
        }).toList();
        
        if (trips.isEmpty) return const Center(child: Text('لا توجد رحلات/طلبات نشطة حاليا.', style: TextStyle(fontFamily: 'Cairo')));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            var data = trips[index].data() as Map<String, dynamic>;
            bool isNegotiating = data['status'] == 'negotiating';
            bool isCanceled = data['status'] == 'canceled';
            bool isErrand = data['tripCategory'] == 'طلبات';

            if (isCanceled && !_cancellationTimers.containsKey(trips[index].id)) {
              _cancellationTimers[trips[index].id] = true;
              Future.delayed(const Duration(seconds: 10), () {
                if (mounted) _deleteTripForUser(trips[index].id);
              });
            }

            return Card(
              elevation: 3, margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(isErrand ? 'تنفيذ طلب أوردر للعميل' : 'توصيل عميل (${data['vehicleType']})', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14)),
                    const SizedBox(height: 12),
                    
                    if (isCanceled)
                      Column(
                        children: [
                          Container(
                            width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: royalGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), // تم التعديل هنا
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('تم إلغاء هذه الرحلة', textAlign: TextAlign.center, style: TextStyle(color: royalGreen, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                const Spacer(),
                                IconButton(
                                  icon: Icon(Icons.close, color: royalGreen),
                                  onPressed: () => _deleteTripForUser(trips[index].id),
                                )
                              ],
                            )
                          )
                        ],
                      )
                    else if (isNegotiating)
                      Column(
                        children: [
                          if (data['lastNegotiator'] == 'driver')
                            Text('في انتظار رد العميل على عرضك (${data['negotiationPrice']} ج)', style: const TextStyle(color: Colors.orange, fontFamily: 'Cairo', fontWeight: FontWeight.bold))
                          else
                            Column(
                              children: [
                                Text('العميل يعرض عليك أجرة: ${data['negotiationPrice']} ج', style: const TextStyle(color: Colors.blue, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: royalGreen, padding: const EdgeInsets.symmetric(horizontal: 4)), onPressed: () => _acceptOffer(trips[index].id, data['negotiationPrice']), child: const Text('موافق', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 12)))),
                                    const SizedBox(width: 4),
                                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 4)), onPressed: () => _showNegotiationDialog(trips[index].id), child: const Text('تفاوض', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 12)))),
                                    const SizedBox(width: 4),
                                    Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)), onPressed: () => _cancelTrip(trips[index].id), child: const Text('رفض', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 12)))),
                                  ],
                                )
                              ],
                            )
                        ],
                      )
                    else
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: trips[index].id))), icon: const Icon(Icons.chat, color: Colors.white, size: 18), label: const Text('محادثة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 12)))),
                              const SizedBox(width: 4),
                              Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: royalGreen), onPressed: () => _showRatingDialog(trips[index].id), icon: const Icon(Icons.done_all, color: Colors.white, size: 18), label: const Text('إنهاء وتقييم', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 12)))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(onPressed: () => _cancelTrip(trips[index].id), icon: const Icon(Icons.cancel, color: Colors.red, size: 18), label: const Text('إلغاء واعتذار', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 12)))
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