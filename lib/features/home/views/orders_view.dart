import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersView extends StatelessWidget {
  final String activeRole;

  const OrdersView({super.key, required this.activeRole});

  final Color primaryNavy = const Color(0xFF0F172A);

  Future<void> _deleteOrder(BuildContext context, String docId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          textDirection: TextDirection.rtl,
          children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Text('حذف الطلب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))],
        ),
        content: const Text('هل أنت متأكد من حذف هذا الطلب نهائياً؟ لا يمكن التراجع عن هذا الإجراء.', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );

    if (confirm == true) {
      String collection = activeRole == 'lawyer' ? 'legal_requests' : 'trips';
      await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الطلب بنجاح 🗑️', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    
    Stream<QuerySnapshot> ordersStream;
    if (activeRole == 'lawyer') {
      ordersStream = FirebaseFirestore.instance.collection('legal_requests').orderBy('timestamp', descending: true).snapshots();
    } else {
      ordersStream = FirebaseFirestore.instance.collection('trips')
        .where('passengerId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'negotiating', 'accepted'])
        .snapshots();
    }

    return Column(
      children: [
        Container(
          width: double.infinity, padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 20),
          decoration: BoxDecoration(color: primaryNavy, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25))),
          child: Text(
            activeRole == 'lawyer' ? 'طلبات العملاء الواردة ⚖️' : 'متابعة طلباتي النشطة 🚀', 
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ordersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('ليس لديك أي طلبات نشطة حالية.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    ],
                  ),
                );
              }
              
              var docs = snapshot.data!.docs;
              
              if (activeRole != 'lawyer') {
                docs.sort((a, b) => (b['createdAt'] as Timestamp?)?.compareTo(a['createdAt'] as Timestamp? ?? Timestamp.now()) ?? 0);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var doc = docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  
                  String type = data.containsKey('tripCategory') ? '🚗 ${data['tripCategory']}' : (data['serviceType'] ?? 'طلب خدمة');
                  String status = data['status'] ?? 'pending';
                  String details = data.containsKey('destination') ? 'إلى: ${data['destination']}' : (data['details'] ?? '');
                  String clientName = data['clientName'] ?? 'عميل غير معروف';
                  
                  return Card(
                    elevation: 2, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(type, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryNavy, fontFamily: 'Cairo'))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: status == 'accepted' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text(status == 'accepted' ? 'تم القبول' : 'قيد الانتظار/التفاوض', style: TextStyle(color: status == 'accepted' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                              ),
                              // 🗑️ زر مسح الطلب الجديد
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                tooltip: 'مسح الطلب',
                                onPressed: () => _deleteOrder(context, doc.id),
                              )
                            ],
                          ),
                          if (activeRole == 'lawyer') ...[
                            const SizedBox(height: 4),
                            Text('مُقدم الطلب: $clientName', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Cairo')),
                          ],
                          const Divider(),
                          Text(details, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700, fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}