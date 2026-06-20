// ignore_for_file: use_build_context_synchronously

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
  final Map<String, bool> _cancellationTimers = {}; 

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'الآن';
    DateTime dt = timestamp.toDate();
    String amPm = dt.hour >= 12 ? 'م' : 'ص';
    int hour12 = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    String minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}/${dt.month}/${dt.day} - $hour12:$minute $amPm';
  }

  Future<void> _deleteTripForUser(String tripId, String role) async {
    String deleteField = role == 'driver' ? 'isDeletedForDriver' : 'isDeletedForPassenger';
    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({deleteField: true});
  }

  Future<void> _cancelTrip(String tripId, String canceledByRole) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الرحلة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('هل أنت متأكد من إلغاء هذه الرحلة؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('إلغاء', style: TextStyle(color: Colors.white, fontFamily: 'Cairo'))),
        ],
      )
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({'status': 'canceled', 'canceledBy': canceledByRole});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الرحلة بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.orange));
    }
  }

  Future<void> _acceptOffer(String tripId, String acceptedPrice) async {
    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({'status': 'accepted', 'finalPrice': acceptedPrice});
  }

  void _showNegotiationDialog(String tripId) {
    TextEditingController offerCtrl = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('التفاوض على الأجرة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), 
        content: TextField(controller: offerCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'اكتب سعرك المقترح', suffixText: 'جنيه', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: royalGreen),
            onPressed: () async { 
              if (offerCtrl.text.isEmpty) return;
              await FirebaseFirestore.instance.collection('trips').doc(tripId).update({'status': 'negotiating', 'negotiationPrice': offerCtrl.text, 'lastNegotiator': 'passenger'}); 
              if(mounted) Navigator.pop(ctx); 
            }, 
            child: const Text('إرسال', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold))
          )
        ]
      )
    );
  }

  // 🚗 نافذة التتبع الحي للكابتن على الخريطة
  void _showTrackingMap(String tripId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('trips').doc(tripId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data == null || data['driverLocation'] == null) {
                return const Center(child: Text('جاري انتظار بث موقع الكابتن...', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)));
              }

              GeoPoint driverLoc = data['driverLocation'];
              double heading = (data['driverHeading'] ?? 0.0).toDouble();

              Set<Marker> markers = {
                Marker(
                  markerId: const MarkerId('driver'),
                  position: LatLng(driverLoc.latitude, driverLoc.longitude),
                  rotation: heading,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // تقدر تبدلها بصورة سيارة لاحقاً
                  infoWindow: const InfoWindow(title: 'الكابتن'),
                )
              };

              return ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(target: LatLng(driverLoc.latitude, driverLoc.longitude), zoom: 18.5),
                      markers: markers,
                      myLocationButtonEnabled: false,
                    ),
                    Positioned(
                      top: 16, right: 16,
                      child: FloatingActionButton(mini: true, backgroundColor: Colors.white, onPressed: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.black)),
                    )
                  ],
                ),
              );
            },
          ),
        );
      }
    );
  }

  void _showRatingDialog(String tripId, {String? targetId, String? targetName}) {
    int stars = 5; 
    bool saveToFavorites = false;

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
                if (targetId != null)
                  Column(
                    children: [
                      const Divider(),
                      CheckboxListTile(title: const Text('حفظ الكابتن في المفضلة', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)), value: saveToFavorites, activeColor: Colors.amber, onChanged: (val) => setDialogState(() => saveToFavorites = val ?? false), controlAffinity: ListTileControlAffinity.leading)
                    ],
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: royalGreen, minimumSize: const Size(double.infinity, 45)), 
                  onPressed: () async { 
                    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({'passengerRating': stars}); 
                    if (saveToFavorites && targetId != null) {
                      await FirebaseFirestore.instance.collection('users').doc(currentUserId).set({'favoriteDrivers': FieldValue.arrayUnion([{'id': targetId, 'name': targetName ?? 'كابتن لمة'}])}, SetOptions(merge: true));
                    }
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

  void _showFavoriteDriversBottomSheet() {
    showModalBottomSheet(
      context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              const Text('كباتني المفضلين', style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    var data = snapshot.data!.data() as Map<String, dynamic>?;
                    List favs = data?['favoriteDrivers'] ?? [];
                    if (favs.isEmpty) return const Center(child: Text('لسه مفيش كباتن في المفضلة عندك', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)));
                    return ListView.builder(
                      itemCount: favs.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.star, color: Colors.white)),
                          title: Text(favs[index]['name'], style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                          trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async { await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({'favoriteDrivers': FieldValue.arrayRemove([favs[index]])}); }),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade100, foregroundColor: Colors.amber.shade900, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(double.infinity, 50)),
            onPressed: _showFavoriteDriversBottomSheet, icon: const Icon(Icons.star_rounded, color: Colors.amber), label: const Text('قائمة كباتني المفضلين', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('trips').where('passengerId', isEqualTo: currentUserId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              var trips = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return data['isDriverPost'] != true && data['isDeletedForPassenger'] != true;
              }).toList();

              trips.sort((a, b) => ((b.data() as Map)['createdAt'] as Timestamp?)?.compareTo(((a.data() as Map)['createdAt'] as Timestamp?) ?? Timestamp.now()) ?? 0);        
              
              if (trips.isEmpty) {
                return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.assignment_turned_in_outlined, size: 60, color: Colors.grey), SizedBox(height: 12), Text('لا توجد طلبات سابقة حاليا', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15))]));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  var doc = trips[index];
                  var data = doc.data() as Map<String, dynamic>;
                  String status = data['status'];
                  bool isErrand = data['tripCategory'] == 'طلبات';

                  if (status == 'canceled' && !_cancellationTimers.containsKey(doc.id)) {
                    _cancellationTimers[doc.id] = true;
                    Future.delayed(const Duration(seconds: 10), () { if (mounted) _deleteTripForUser(doc.id, 'passenger'); });
                  }

                  return Card(
                    elevation: 4, margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isErrand ? 'طلب شراء وتوصيل' : 'مشوار توصيل', style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                              Row(children: [const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(_formatDateTime(data['createdAt']), style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold))]),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(isErrand ? 'أجرة التوصيل: ${data['suggestedPrice']} جنيه' : '${data['vehicleType']} - السعر المقترح: ${data['suggestedPrice']} جنيه', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 15)),
                          
                          if (status == 'canceled')
                            Container(width: double.infinity, margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: royalGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('تم إلغاء هذه الرحلة', textAlign: TextAlign.center, style: TextStyle(color: royalGreen, fontWeight: FontWeight.bold, fontFamily: 'Cairo')), const Spacer(), IconButton(icon: Icon(Icons.close, color: royalGreen), onPressed: () => _deleteTripForUser(doc.id, 'passenger'))]))
                          else if (status == 'pending')
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 8), const Text('جاري البحث عن كباتن...', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)), const SizedBox(height: 8), OutlinedButton.icon(onPressed: () => _cancelTrip(doc.id, 'passenger'), icon: const Icon(Icons.cancel, color: Colors.red), label: const Text('إلغاء الطلب', style: TextStyle(color: Colors.red, fontFamily: 'Cairo')))])
                          else if (status == 'negotiating')
                            Container(
                                  margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                                  child: data['lastNegotiator'] == 'driver'
                                      ? Column(children: [Text('الكابتن عرض عليك أجرة: ${data['negotiationPrice']} جنيه', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14)), const SizedBox(height: 12), Row(children: [Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: royalGreen, padding: const EdgeInsets.symmetric(horizontal: 4)), onPressed: () => _acceptOffer(doc.id, data['negotiationPrice']), icon: const Icon(Icons.check, color: Colors.white, size: 16), label: const Text('موافق', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)))), const SizedBox(width: 4), Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 4)), onPressed: () => _showNegotiationDialog(doc.id), icon: const Icon(Icons.edit, color: Colors.white, size: 16), label: const Text('تفاوض', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)))), const SizedBox(width: 4), Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)), onPressed: () => _cancelTrip(doc.id, 'passenger'), icon: const Icon(Icons.close, color: Colors.red, size: 16), label: const Text('رفض', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12))))])])
                                      : Column(children: [Text('في انتظار رد الكابتن على عرضك (${data['negotiationPrice']} ج)', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)), const SizedBox(height: 8), OutlinedButton.icon(onPressed: () => _cancelTrip(doc.id, 'passenger'), icon: const Icon(Icons.cancel, color: Colors.red, size: 18), label: const Text('إلغاء الطلب', style: TextStyle(color: Colors.red, fontFamily: 'Cairo')))])
                                )
                          else if (status == 'accepted')
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                const Text('الكابتن استلم الطلب وجاي في الطريق', style: TextStyle(fontFamily: 'Cairo', color: Colors.green, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), onPressed: () => _showTrackingMap(doc.id), icon: const Icon(Icons.map, color: Colors.white), label: const Text('تتبع الكابتن', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')))),
                                    const SizedBox(width: 8),
                                    Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: royalGreen), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: doc.id))), icon: const Icon(Icons.chat, color: Colors.white), label: const Text('المحادثة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), onPressed: () => _showRatingDialog(doc.id, targetId: data['driverId'], targetName: data['driverName']), icon: const Icon(Icons.star, color: Colors.white), label: const Text('إنهاء وتقييم', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')))),
                                    const SizedBox(width: 8),
                                    Expanded(child: OutlinedButton.icon(onPressed: () => _cancelTrip(doc.id, 'passenger'), icon: const Icon(Icons.cancel, color: Colors.red), label: const Text('إلغاء الرحلة', style: TextStyle(color: Colors.red, fontFamily: 'Cairo')))),
                                  ],
                                )
                              ],
                            )
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