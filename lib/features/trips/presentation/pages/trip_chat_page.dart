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
  
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<DocumentSnapshot>? _tripSubscription;
  
  Map<String, dynamic>? _tripData;
  
  bool _isDriver = false;
  String _otherPartyName = 'جاري التحميل...';
  LatLng? _currentLatLng; 

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); 
    _checkUserRoleAndSetupTracking();
    _listenToTripData(); 
  }

  void _listenToTripData() {
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

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    
    if (mounted) {
      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
      });
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
    if (tripData.containsKey('pickupLocation') && tripData['pickupLocation'] is GeoPoint) {
      GeoPoint p = tripData['pickupLocation'];
      updatedMarkers.add(Marker(markerId: const MarkerId('pickup'), position: LatLng(p.latitude, p.longitude), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)));
    }
    if (tripData.containsKey('destinationLocation') && tripData['destinationLocation'] is GeoPoint) {
      GeoPoint d = tripData['destinationLocation'];
      updatedMarkers.add(Marker(markerId: const MarkerId('destination'), position: LatLng(d.latitude, d.longitude), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)));
    }
    if (tripData.containsKey('driverLocation') && tripData['driverLocation'] is GeoPoint) {
      GeoPoint dr = tripData['driverLocation'];
      LatLng driverLatLng = LatLng(dr.latitude, dr.longitude);
      updatedMarkers.add(Marker(markerId: const MarkerId('driver'), position: driverLatLng, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)));
      
      // 🟢 الاستدعاء الآمن بدون علامات تعجب
      if (!_isDriver) {
        _mapController?.animateCamera(CameraUpdate.newLatLng(driverLatLng));
      }
    }
    if (mounted) setState(() => _markers = updatedMarkers);
  }

  LatLng _getInitialCameraPosition() {
    if (_tripData != null && _tripData!.containsKey('pickupLocation') && _tripData!['pickupLocation'] is GeoPoint) {
      final gp = _tripData!['pickupLocation'] as GeoPoint;
      return LatLng(gp.latitude, gp.longitude);
    }
    return _currentLatLng ?? const LatLng(30.0444, 31.2357);
  }

  @override
  Widget build(BuildContext context) {
    bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_otherPartyName, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 18)),
        backgroundColor: royalGreen,
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Visibility(
              visible: !isKeyboardOpen,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                child: _tripData == null
                    ? Center(child: CircularProgressIndicator(color: royalGreen))
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _getInitialCameraPosition(),
                          zoom: 17.0
                        ),
                        markers: _markers,
                        myLocationEnabled: true,
                        onMapCreated: (controller) => _mapController = controller,
                      ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.grey.shade200,
              child: Text(
                _isDriver ? '📍 العميل في انتظارك.. تحرك الآن' : '🚖 الكابتن في الطريق إليك..',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: royalGreen),
              ),
            ),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('trips')
                    .doc(widget.tripId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: royalGreen));
                  }
                  
                  // 🟢 الحل الآمن للبيانات
                  var msgs = snapshot.data?.docs ?? [];
                  if (msgs.isEmpty) {
                    return Center(child: Text('لا توجد رسائل حتى الآن. ابدأ المحادثة 👋', style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Cairo')));
                  }
                  
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: msgs.length,
                    itemBuilder: (context, index) {
                      var msg = msgs[index].data() as Map<String, dynamic>;
                      bool isMe = msg['senderId'] == currentUserId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? royalGreen : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(msg['text'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black, fontFamily: 'Cairo')),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(hintText: 'اكتب رسالتك هنا...'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: royalGreen),
                      onPressed: _sendMessage,
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