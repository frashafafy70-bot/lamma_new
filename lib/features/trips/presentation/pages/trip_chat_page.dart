// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  
  // 💡 الحل الاحترافي: الاشتراكات في الخلفية (بدون StreamBuilder)
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  StreamSubscription<DocumentSnapshot>? _tripSubscription;
  
  List<QueryDocumentSnapshot> _messages = [];
  Map<String, dynamic>? _tripData;
  
  bool _isDriver = false;
  bool _isMessagesLoading = true; // متغير للتحكم في اللودينج مرة واحدة فقط
  String _otherPartyName = 'جاري التحميل...';
  LatLng? _currentLatLng; 

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); 
    _checkUserRoleAndSetupTracking();
    _startListeningToData(); // 🚀 تشغيل مستمع البيانات
  }

  // 🚀 دالة سحب البيانات وتخزينها في الذاكرة (تمنع التهنيج مع الكيبورد نهائياً)
  void _startListeningToData() {
    // 1. الاستماع للرسايل
    _messagesSubscription = FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _messages = snapshot.docs;
          _isMessagesLoading = false;
        });
      }
    });

    // 2. الاستماع لبيانات الرحلة والخريطة
    _tripSubscription = FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .snapshots()
        .listen((snapshot) {
      if (mounted && snapshot.exists) {
        setState(() {
          _tripData = snapshot.data() as Map<String, dynamic>;
          _updateMarkers(_tripData!);
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _locationSubscription?.cancel();
    _messagesSubscription?.cancel();
    _tripSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    
    if (mounted) {
      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
      });
      if (_mapController != null) {
        // 🗺️ زووم عالي 18.5 لتوضيح الشوارع والمباني باحترافية
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng!, 18.5));
      }
    }
  }

  Future<void> _checkUserRoleAndSetupTracking() async {
    DocumentSnapshot tripDoc = await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).get();
    
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && currentUserId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(currentUserId).set({
          'fcmToken': token
        }, SetOptions(merge: true));
      }
    } catch (_) {}

    if (tripDoc.exists) {
      var data = tripDoc.data() as Map<String, dynamic>;
      setState(() {
        _isDriver = data['driverId'] == currentUserId;
        _otherPartyName = _isDriver ? (data['passengerName'] ?? 'العميل') : (data['driverName'] ?? 'الكابتن');
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
            // 🗺️ الخريطة: ثابتة ومستقرة ومفيش StreamBuilder يعملها ريفريش
            Visibility(
              visible: !isKeyboardOpen,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: false,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                child: _tripData == null
                    ? Center(child: CircularProgressIndicator(color: royalGreen))
                    : GoogleMap(
                        mapType: MapType.normal,
                        // 🚀 زووم احترافي عالي
                        initialCameraPosition: CameraPosition(
                          target: _tripData!['pickupLocation'] != null 
                              ? LatLng(_tripData!['pickupLocation'].latitude, _tripData!['pickupLocation'].longitude) 
                              : (_currentLatLng ?? const LatLng(30.0444, 31.2357)), 
                          zoom: 18.5
                        ),
                        markers: _markers,
                        myLocationEnabled: true, 
                        myLocationButtonEnabled: true, 
                        zoomControlsEnabled: true, 
                        zoomGesturesEnabled: true, 
                        onMapCreated: (controller) {
                           _mapController = controller;
                           if (_currentLatLng != null) {
                             _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng!, 18.5));
                           }
                        },
                      ),
              ),
            ),

            // ⚠️ شريط التنبيه
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

            // 💬 منطقة الرسائل (أصبحت بتأخد من الذاكرة مباشرة)
            Expanded(
              child: _isMessagesLoading 
                  ? Center(child: CircularProgressIndicator(color: royalGreen))
                  : _messages.isEmpty
                      ? Center(child: Text('لا توجد رسائل حتى الآن. ابدأ المحادثة 👋', style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Cairo')))
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            var msg = _messages[index].data() as Map<String, dynamic>;
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
                        ),
            ),

            // ✍️ حقل إدخال الرسالة
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
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
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