// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class TripChatPage extends StatefulWidget {
  final String tripId;
  const TripChatPage({super.key, required this.tripId});

  @override
  State<TripChatPage> createState() => _TripChatPageState();
}

class _TripChatPageState extends State<TripChatPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color royalGreen = const Color(0xFF1B4332);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  StreamSubscription<Position>? _locationSubscription;
  
  bool _isDriver = false;
  bool _isLoading = true;
  String _otherPartyName = 'جاري التحميل...';
  LatLng? _currentLatLng; // المتغير ده عشان يحفظ مكانك الحقيقي ويبعدنا عن التحرير

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // بنجيب مكانك أول ما تفتح
    _checkUserRoleAndSetupTracking();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _locationSubscription?.cancel();
    super.dispose();
  }

  // 📍 دالة تحديد مكانك الفعلي عشان الخريطة تفتح عليه
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
      });
      // تحريك الكاميرا لمكانك لو الخريطة كانت حملت
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng!, 15));
      }
    }
  }

  Future<void> _checkUserRoleAndSetupTracking() async {
    DocumentSnapshot tripDoc = await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).get();
    
    if (tripDoc.exists) {
      var data = tripDoc.data() as Map<String, dynamic>;
      setState(() {
        _isDriver = data['driverId'] == currentUserId;
        _otherPartyName = _isDriver ? (data['passengerName'] ?? 'العميل') : (data['driverName'] ?? 'الكابتن');
        _isLoading = false;
      });
      if (_isDriver) _startLiveTracking();
    }
  }

  void _startLiveTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      FirebaseFirestore.instance.collection('trips').doc(widget.tripId).update({
        'driverLocation': GeoPoint(position.latitude, position.longitude),
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    String text = _messageController.text.trim();
    _messageController.clear();

    await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).collection('messages').add({
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0.0, curve: Curves.easeOut, duration: const Duration(milliseconds: 300));
    }
  }

  void _updateMarkers(Map<String, dynamic> tripData) {
    Set<Marker> updatedMarkers = {};
    if (tripData['pickupLocation'] != null) {
      GeoPoint p = tripData['pickupLocation'];
      updatedMarkers.add(Marker(markerId: const MarkerId('pickup'), position: LatLng(p.latitude, p.longitude), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), infoWindow: const InfoWindow(title: 'مكان التحرك')));
    }
    if (tripData['destinationLocation'] != null) {
      GeoPoint d = tripData['destinationLocation'];
      updatedMarkers.add(Marker(markerId: const MarkerId('destination'), position: LatLng(d.latitude, d.longitude), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), infoWindow: const InfoWindow(title: 'وجهة الوصول')));
    }
    if (tripData['driverLocation'] != null) {
      GeoPoint dr = tripData['driverLocation'];
      LatLng driverLatLng = LatLng(dr.latitude, dr.longitude);
      updatedMarkers.add(Marker(markerId: const MarkerId('driver'), position: driverLatLng, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), infoWindow: const InfoWindow(title: 'الكابتن 🚖')));
      if (!_isDriver && _mapController != null) _mapController!.animateCamera(CameraUpdate.newLatLng(driverLatLng));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _markers = updatedMarkers);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(body: Center(child: CircularProgressIndicator(color: royalGreen)));
    bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_otherPartyName, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 18)),
        backgroundColor: royalGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.call), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري الاتصال... 📞', style: TextStyle(fontFamily: 'Cairo'))));
          }),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            if (!isKeyboardOpen)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('trips').doc(widget.tripId).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.data() != null) {
                      var tripData = snapshot.data!.data() as Map<String, dynamic>;
                      _updateMarkers(tripData);
                      
                      // 🌍 ضبط نقطة البداية (لو العميل حدد مكان بياخده، لو لأ بياخد مكانك الفعلي اللي جبناه فوق)
                      LatLng initialTarget = _currentLatLng ?? const LatLng(30.0444, 31.2357);
                      if (tripData['pickupLocation'] != null) {
                        initialTarget = LatLng(tripData['pickupLocation'].latitude, tripData['pickupLocation'].longitude);
                      }
                      
                      return GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: CameraPosition(target: initialTarget, zoom: 15),
                        markers: _markers,
                        myLocationEnabled: true, // إظهار النقطة الزرقاء بتاعتك
                        myLocationButtonEnabled: true, // إرجاع زرار تحديد الموقع
                        zoomControlsEnabled: true, // ✅ إرجاع زراير الزووم (+ و -)
                        zoomGesturesEnabled: true, // ✅ تفعيل الزووم بالإيد
                        onMapCreated: (controller) => _mapController = controller,
                      );
                    }
                    return Center(child: CircularProgressIndicator(color: royalGreen));
                  }
                ),
              ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: Colors.grey.shade200, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]),
              child: Text(
                _isDriver ? '📍 العميل في انتظارك.. تحرك الآن' : '🚖 الكابتن في الطريق إليك..',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: royalGreen),
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('trips').doc(widget.tripId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var messages = snapshot.data!.docs;

                  if (messages.isEmpty) {
                    return Center(child: Text('لا توجد رسائل حتى الآن. ابدأ المحادثة 👋', style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Cairo')));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var msg = messages[index].data() as Map<String, dynamic>;
                      bool isMe = msg['senderId'] == currentUserId;

                      DateTime dt;
                      if (msg['timestamp'] != null) {
                        dt = (msg['timestamp'] as Timestamp).toDate();
                      } else {
                        dt = DateTime.now(); 
                      }
                      String period = dt.hour >= 12 ? 'م' : 'ص';
                      int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
                      String minute = dt.minute.toString().padLeft(2, '0');
                      String timeText = '$hour:$minute $period';

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? royalGreen : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 16),
                            ),
                            border: isMe ? null : Border.all(color: Colors.grey.shade300),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                msg['text'] ?? '',
                                style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontFamily: 'Cairo', fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeText,
                                style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontFamily: 'Cairo', fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(fontFamily: 'Cairo'),
                        decoration: InputDecoration(
                          hintText: 'اكتب رسالتك هنا...',
                          hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: royalGreen,
                      radius: 24,
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: _sendMessage,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}