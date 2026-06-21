// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../trip_chat_page.dart'; // تأكد إن مسار الشات صحيح

class AvailableTravelsTab extends StatefulWidget {
  const AvailableTravelsTab({super.key});

  @override
  State<AvailableTravelsTab> createState() => _AvailableTravelsTabState();
}

class _AvailableTravelsTabState extends State<AvailableTravelsTab> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color royalGreen = const Color(0xFF1B4332);
  
  Position? _passengerPosition;
  bool _isLoadingLocation = true; 
  bool _showOnlyNearby = false; 
  final double _nearbyRadiusInMeters = 20000; // نطاق 20 كيلو

  @override
  void initState() {
    super.initState();
    _getPassengerLocation();
  }

  Future<void> _getPassengerLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { setState(() => _isLoadingLocation = false); return; }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) { setState(() => _isLoadingLocation = false); return; }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) {
        setState(() {
          _passengerPosition = position;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.radar_rounded, color: _showOnlyNearby ? royalGreen : Colors.grey),
                  const SizedBox(width: 8),
                  const Text('الرحلات القريبة مني فقط', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Switch(
                value: _showOnlyNearby,
                activeThumbColor: Colors.white,
                activeTrackColor: royalGreen,
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade200,
                onChanged: (val) {
                  if (_passengerPosition == null && val) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تفعيل الموقع (GPS) لاستخدام هذه الميزة', style: TextStyle(fontFamily: 'Cairo'))));
                    _getPassengerLocation();
                    return;
                  }
                  setState(() => _showOnlyNearby = val);
                },
              )
            ],
          ),
        ),
        
        // 💡 تم التعديل هنا لـ withValues(alpha: 0.1) للقضاء على التحذير
        if (_isLoadingLocation)
          LinearProgressIndicator(color: royalGreen, backgroundColor: royalGreen.withValues(alpha: 0.1), minHeight: 3),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('trips').where('isDriverPost', isEqualTo: true).where('status', isEqualTo: 'available').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: royalGreen));
              
              var rawTrips = snapshot.data!.docs;
              if (rawTrips.isEmpty) return const Center(child: Text('لا توجد رحلات سفر مطروحة حاليا', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold)));

              List<Map<String, dynamic>> processedTrips = [];
              
              for (var doc in rawTrips) {
                var data = doc.data() as Map<String, dynamic>;
                double distance = double.infinity; 
                bool hasLocation = data['fromLocation'] != null;

                if (hasLocation && _passengerPosition != null) {
                  GeoPoint geo = data['fromLocation'];
                  distance = Geolocator.distanceBetween(
                    _passengerPosition!.latitude, _passengerPosition!.longitude,
                    geo.latitude, geo.longitude
                  );
                }

                if (_showOnlyNearby && distance > _nearbyRadiusInMeters) continue;

                processedTrips.add({
                  'docId': doc.id,
                  'data': data,
                  'distance': distance,
                });
              }

              processedTrips.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

              if (processedTrips.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off_rounded, size: 50, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      const Text('لا توجد رحلات قريبة في نطاق مدينتك', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: processedTrips.length,
                itemBuilder: (context, index) {
                  var trip = processedTrips[index];
                  var data = trip['data'];
                  double dist = trip['distance'];
                  
                  String distanceText = dist != double.infinity 
                      ? 'يبعد عنك: ${(dist / 1000).toStringAsFixed(1)} كم'
                      : '';

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
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('الموعد: ${data['time']}', style: TextStyle(color: Colors.grey.shade700, fontFamily: 'Cairo', fontSize: 13)),
                              if (distanceText.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 14, color: Colors.blue.shade700),
                                    Text(distanceText, style: TextStyle(color: Colors.blue.shade700, fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                )
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: royalGreen, foregroundColor: Colors.white), onPressed: () => _bookDriverPost(trip['docId'], data['driverId']), icon: const Icon(Icons.event_seat_rounded, size: 18), label: const Text('حجز مقعد والتواصل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))))
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