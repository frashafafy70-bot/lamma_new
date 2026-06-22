// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
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
  
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startLiveTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _startLiveTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 5)
    ).listen((Position position) async {
      try {
        var snapshot = await FirebaseFirestore.instance.collection('trips')
          .where('driverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'accepted')
          .get();

        for (var doc in snapshot.docs) {
          doc.reference.update({
            'driverLocation': GeoPoint(position.latitude, position.longitude),
            'driverHeading': position.heading,
          });
        }
      } catch (e) {
        debugPrint('خطأ في تحديث الموقع: $e');
      }
    });
  }

  Future<void> _deleteTripForUser(String tripId) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({'isDeletedForDriver': true});
    } catch (e) {
      debugPrint('خطأ في إخفاء الرحلة: $e');
    }
  }

  Future<void> _cancelTrip(String tripId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الرحلة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('هل أنت متأكد من إلغاء هذه الرحلة؟ سيتم إبلاغ الطرف الآخر.', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red), 
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('نعم، إلغاء', style: TextStyle(color: Colors.white, fontFamily: 'Cairo'))
          ),
        ],
      )
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
          'status': 'canceled', 
          'canceledBy': 'driver'
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إلغاء الرحلة بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.orange)
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ أثناء الإلغاء', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red)
          );
        }
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
      debugPrint('خطأ في قبول العرض: $e');
    }
  }

  void _showNegotiationDialog(String tripId) {
    TextEditingController offerCtrl = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('التفاوض على الأجرة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), 
        content: TextField(
          controller: offerCtrl, 
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.black, fontFamily: 'Cairo'),
          decoration: InputDecoration(
            labelText: 'اكتب سعرك المقترح', 
            suffixText: 'جنيه', 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
          )
        ), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: royalGreen),
            onPressed: () async { 
              if (offerCtrl.text.isEmpty) return;
              try {
                await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
                  'status': 'negotiating', 
                  'negotiationPrice': offerCtrl.text.trim(), 
                  'lastNegotiator': 'driver'
                }); 
                if(mounted) Navigator.pop(ctx); 
              } catch (e) {
                debugPrint('خطأ في إرسال التفاوض: $e');
              }
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: List.generate(5, (index) => IconButton(
                    icon: Icon(index < stars ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 35), 
                    onPressed: () => setDialogState(() => stars = index + 1)
                  ))
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: royalGreen, minimumSize: const Size(double.infinity, 45)), 
                  onPressed: () async { 
                    try {
                      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
                        'driverRatingForPassenger': stars, 
                        'status': 'completed'
                      }); 
                      if(mounted) Navigator.pop(ctx); 
                    } catch (e) {
                      debugPrint('خطأ في التقييم: $e');
                    }
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
      stream: FirebaseFirestore.instance.collection('trips')
          .where('driverId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('لا توجد رحلات/طلبات نشطة حاليا.', style: TextStyle(fontFamily: 'Cairo')));
        }

        var trips = snapshot.data!.docs.where((doc) {
           var data = doc.data() as Map<String, dynamic>;
           bool isNotDeleted = data['isDeletedForDriver'] != true;
           bool isValidStatus = data['status'] == 'negotiating' || data['status'] == 'accepted' || data['status'] == 'canceled';
           return isNotDeleted && isValidStatus;
        }).toList();
        
        if (trips.isEmpty) {
          return const Center(child: Text('لا توجد رحلات/طلبات نشطة حاليا.', style: TextStyle(fontFamily: 'Cairo')));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            var docId = trips[index].id;
            var data = trips[index].data() as Map<String, dynamic>;
            
            bool isNegotiating = data['status'] == 'negotiating';
            bool isCanceled = data['status'] == 'canceled';
            bool isErrand = data['tripCategory'] == 'طلبات';

            if (isCanceled && !_cancellationTimers.containsKey(docId)) {
              _cancellationTimers[docId] = true;
              Future.delayed(const Duration(seconds: 10), () {
                if (mounted) _deleteTripForUser(docId);
              });
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
                      children: [
                        Icon(isErrand ? Icons.shopping_bag : Icons.local_taxi, color: royalGreen),
                        const SizedBox(width: 8),
                        Text(
                          isErrand ? 'تنفيذ طلب أوردر للعميل' : 'توصيل عميل (${data['vehicleType'] ?? ''})', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14)
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    
                    if (isCanceled)
                      Container(
                        width: double.infinity, 
                        padding: const EdgeInsets.all(12), 
                        decoration: BoxDecoration(
                          color: royalGreen.withValues(alpha: 0.1), 
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('تم إلغاء هذه الرحلة', style: TextStyle(color: royalGreen, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                            IconButton(
                              icon: Icon(Icons.close, color: royalGreen), 
                              onPressed: () => _deleteTripForUser(docId)
                            )
                          ],
                        )
                      )
                    else if (isNegotiating)
                      if (data['lastNegotiator'] == 'driver')
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('في انتظار رد العميل على عرضك (${data['negotiationPrice']} ج)', style: const TextStyle(color: Colors.orange, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
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
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: Text('عرض العميل: ${data['negotiationPrice']} ج', style: const TextStyle(color: Colors.blue, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: royalGreen, padding: EdgeInsets.zero), 
                                    onPressed: () => _acceptOffer(docId, data['negotiationPrice']), 
                                    child: const Text('موافق', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 13))
                                  )
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: EdgeInsets.zero), 
                                    onPressed: () => _showNegotiationDialog(docId), 
                                    child: const Text('تفاوض', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 13))
                                  )
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, side: const BorderSide(color: Colors.red)), 
                                    onPressed: () => _cancelTrip(docId), 
                                    child: const Text('رفض', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 13))
                                  )
                                ),
                              ],
                            )
                          ],
                        )
                    else
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), 
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: docId))), 
                                  icon: const Icon(Icons.chat, color: Colors.white, size: 18), 
                                  label: const Text('محادثة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 13))
                                )
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: royalGreen), 
                                  onPressed: () => _showRatingDialog(docId), 
                                  icon: const Icon(Icons.done_all, color: Colors.white, size: 18), 
                                  label: const Text('إنهاء', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 13))
                                )
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                              onPressed: () => _cancelTrip(docId), 
                              icon: const Icon(Icons.cancel, color: Colors.red, size: 18), 
                              label: const Text('إلغاء واعتذار', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 13))
                            ),
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
    );
  }
}