// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../trip_chat_page.dart'; 

class PassengerMyRequestsTab extends StatefulWidget {
  const PassengerMyRequestsTab({super.key});

  @override
  State<PassengerMyRequestsTab> createState() => _PassengerMyRequestsTabState();
}

class _PassengerMyRequestsTabState extends State<PassengerMyRequestsTab> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color royalGreen = const Color(0xFF1B4332);
  
  // 🟢 خريطة عامة لحفظ متحكمات الخرائط لكل طلب، لضمان تحريك الكاميرا بدون أي (Dead Code)
  final Map<String, GoogleMapController> _mapControllers = {};
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.grey;
      case 'negotiating': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'completed': return Colors.green;
      case 'canceled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'في انتظار كابتن';
      case 'negotiating': return 'جاري التفاوض';
      case 'accepted': return 'تم القبول';
      case 'completed': return 'مكتملة';
      case 'canceled': return 'ملغية';
      default: return status;
    }
  }

  Future<void> _confirmDeleteRequest(String docId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا الطلب نهائياً من القائمة؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('trips').doc(docId).delete();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الطلب بنجاح ✅', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الحذف', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _acceptOffer(String tripId, String acceptedPrice) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'status': 'accepted', 
        'finalPrice': acceptedPrice
      });
    } catch (e) {
      debugPrint('خطأ: $e');
    }
  }

  Future<void> _rejectTrip(String tripId) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'status': 'canceled', 
        'canceledBy': 'passenger'
      });
    } catch (e) {
      debugPrint('خطأ: $e');
    }
  }

  void _showNegotiationDialog(String tripId) {
    TextEditingController offerCtrl = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('التفاوض مع الكابتن', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), 
        content: TextField(
          controller: offerCtrl, 
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.black, fontFamily: 'Cairo'),
          decoration: InputDecoration(
            labelText: 'سعر العرض الجديد', 
            suffixText: 'جنيه', 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
          )
        ), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: royalGreen),
            onPressed: () async { 
              if (offerCtrl.text.trim().isEmpty) return;
              try {
                await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
                  'status': 'negotiating', 
                  'negotiationPrice': offerCtrl.text.trim(), 
                  'lastNegotiator': 'passenger'
                }); 
                if(mounted) Navigator.pop(ctx); 
              } catch (e) {
                debugPrint('خطأ: $e');
              }
            }, 
            child: const Text('إرسال العرض', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold))
          )
        ]
      )
    );
  }

  @override
  void dispose() {
    _mapControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .where('passengerId', isEqualTo: currentUserId)
          .where('isDriverPost', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: royalGreen));
        
        var docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('لم تقم بطلب أي مشاوير أو طلبات حتى الآن', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var docId = docs[index].id;
            var data = docs[index].data() as Map<String, dynamic>;
            String status = data['status'] ?? 'pending';
            String category = data['tripCategory'] ?? 'داخلي';
            bool isErrand = category == 'طلبات';
            bool isNegotiating = status == 'negotiating';

            Set<Marker> trackingMarkers = {};

            if (status == 'accepted' && data.containsKey('driverLocation') && data['driverLocation'] is GeoPoint) {
              GeoPoint drLoc = data['driverLocation'];
              LatLng driverLatLng = LatLng(drLoc.latitude, drLoc.longitude);
              
              trackingMarkers.add(Marker(
                markerId: const MarkerId('live_driver'),
                position: driverLatLng,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                infoWindow: const InfoWindow(title: 'موقع الكابتن المباشر 🚖'),
              ));
              
              // 🟢 تحريك الكاميرا باستخدام الـ Controller المحفوظ في الـ Map العامة
              if (_mapControllers.containsKey(docId)) {
                _mapControllers[docId]?.animateCamera(CameraUpdate.newLatLng(driverLatLng));
              }
            }

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: royalGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  Icon(isErrand ? Icons.shopping_bag_rounded : Icons.local_taxi_rounded, color: royalGreen, size: 16),
                                  const SizedBox(width: 6),
                                  Text(category, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: royalGreen, fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: _getStatusColor(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(_getStatusLabel(status), style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12)),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => _confirmDeleteRequest(docId),
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    
                    if (isErrand) ...[
                      Text('الطلبات: ${data['errandDetails'] ?? ''}', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text('التكلفة التقريبية للطلبات: ${data['errandCost'] ?? '0'} ج', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade700, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('مكان الشراء: ${data['pickup'] ?? ''}', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade700, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('مكان التسليم: ${data['destination'] ?? ''}', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade700, fontSize: 13)),
                    ] else ...[
                      Text('من: ${data['pickup'] ?? ''}', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('إلى: ${data['destination'] ?? ''}', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text('نوع المركبة: ${data['vehicleType'] ?? 'سيارة'}', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade700, fontSize: 13)),
                    ],
                    const SizedBox(height: 16),

                    if (status == 'accepted' && data.containsKey('driverLocation') && data['driverLocation'] is GeoPoint) ...[
                      const Text('تتبع السائق مباشرة على الخريطة 📍', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng((data['driverLocation'] as GeoPoint).latitude, (data['driverLocation'] as GeoPoint).longitude),
                              zoom: 16.0,
                            ),
                            markers: trackingMarkers,
                            myLocationEnabled: false,
                            zoomControlsEnabled: false,
                            onMapCreated: (controller) {
                              _mapControllers[docId] = controller;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (isNegotiating)
                      if (data['lastNegotiator'] == 'passenger')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.orange, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text('في انتظار رد الكابتن على عرضك (${data['negotiationPrice']} ج)', style: const TextStyle(color: Colors.orange, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13))),
                            ],
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Text('عرض الكابتن: ${data['negotiationPrice']} ج', style: const TextStyle(color: Colors.blue, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: royalGreen, padding: EdgeInsets.zero), onPressed: () => _acceptOffer(docId, data['negotiationPrice']), child: const Text('موافق', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 13)))),
                                const SizedBox(width: 8),
                                Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: EdgeInsets.zero), onPressed: () => _showNegotiationDialog(docId), child: const Text('تفاوض', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 13)))),
                                const SizedBox(width: 8),
                                Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, side: const BorderSide(color: Colors.red)), onPressed: () => _rejectTrip(docId), child: const Text('رفض', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 13)))),
                              ],
                            )
                          ],
                        )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isErrand ? 'سعرك المقترح: ${data['suggestedPrice']} ج' : 'السعر المقترح: ${data['suggestedPrice']} ج',
                            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
                          ),
                          if (status == 'accepted')
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: royalGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: docId))),
                              icon: const Icon(Icons.chat_rounded, size: 16),
                              label: const Text('المحادثة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                        ],
                      ),
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