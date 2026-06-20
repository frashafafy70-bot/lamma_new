// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'trip_chat_page.dart';
import '../../../home/home_page.dart';

class TripsServicesPage extends StatefulWidget {
  final bool isDriver;
  const TripsServicesPage({super.key, required this.isDriver});

  @override
  State<TripsServicesPage> createState() => _TripsServicesPageState();
}

class _TripsServicesPageState extends State<TripsServicesPage> with SingleTickerProviderStateMixin {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color royalGreen = const Color(0xFF1B4332);
  late TabController _tabController;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {}; 
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  bool _isLoadingMap = true;
  bool _isSubmittingTrip = false;
  
  String _mapSelectionMode = 'none'; 
  LatLng? _tempMapCenter; 

  final TextEditingController _mapSearchController = TextEditingController();
  final String googleApiKey = 'AIzaSyBTrwg28lBwTQt8owA9Cy9DOq_LQjFWwOA'; 
  List<dynamic> _placePredictions = [];

  String _tripCategory = 'داخلي'; 
  String _vehicleType = 'سيارة'; 
  final TextEditingController _pickupController = TextEditingController(text: 'موقعي الحالي 📍');
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController(); 
  
  final TextEditingController _errandDetailsController = TextEditingController();
  final TextEditingController _errandEstimatedCostController = TextEditingController(); 
  
  final TextEditingController _postFromCtrl = TextEditingController();
  final TextEditingController _postToCtrl = TextEditingController();
  final TextEditingController _postTimeCtrl = TextEditingController();
  final TextEditingController _postSeatsCtrl = TextEditingController();
  final TextEditingController _postPriceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _requestAllPermissions();
    _getUserLocation();
    _setupPushNotifications(); 
  }

  Future<void> _requestAllPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      
      await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true,
      );

      await _saveDeviceToken();
    } catch (e) {
      debugPrint("Error requesting permissions: $e");
    }
  }

  Future<void> _saveDeviceToken() async {
    if (currentUserId.isEmpty) return;
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUserId).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error saving token: $e");
    }
  }

  void _setupPushNotifications() async {
    if (widget.isDriver) {
      await FirebaseMessaging.instance.subscribeToTopic('drivers_radar');
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic('drivers_radar');
    }
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'الآن';
    DateTime dt = timestamp.toDate();
    String amPm = dt.hour >= 12 ? 'م' : 'ص';
    int hour12 = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    String minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}/${dt.month}/${dt.day} - $hour12:$minute $amPm';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    _errandDetailsController.dispose();
    _errandEstimatedCostController.dispose();
    _postFromCtrl.dispose();
    _postToCtrl.dispose();
    _postTimeCtrl.dispose();
    _postSeatsCtrl.dispose();
    _postPriceCtrl.dispose();
    _mapSearchController.dispose();
    if (_mapController != null) {
      _mapController!.dispose();
      _mapController = null;
    }
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoadingMap = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoadingMap = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoadingMap = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoadingMap = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
      if (mounted) {
        LatLng newLoc = LatLng(position.latitude, position.longitude);
        setState(() {
          _pickupLocation = newLoc;
          _isLoadingMap = false;
          _markers.removeWhere((m) => m.markerId.value == 'pickup');
          _markers.add(Marker(markerId: const MarkerId('pickup'), position: newLoc, infoWindow: const InfoWindow(title: 'موقعك الحالي'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)));
          if (_mapSelectionMode != 'none') _tempMapCenter = newLoc; 
        });
        
        if (mounted && _mapController != null) {
          try {
             _mapController!.animateCamera(CameraUpdate.newLatLngZoom(newLoc, 18.5));
          } catch (e) {
            debugPrint("Map animation ignored due to dispose: $e");
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMap = false);
    }
  }

  void _searchPlaces(String input) async {
    if (input.isEmpty) { 
      setState(() => _placePredictions = []); 
      return; 
    }
    String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$googleApiKey&language=ar&components=country:eg";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() => _placePredictions = json.decode(response.body)['predictions']);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _getPlaceDetailsAndMove(String placeId, String description) async {
    String url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleApiKey";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var location = json.decode(response.body)['result']['geometry']['location'];
        LatLng latLng = LatLng(location['lat'], location['lng']);
        
        if (mounted && _mapController != null) {
           _mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 18.5)); 
        }

        setState(() {
          _mapSearchController.text = description;
          _placePredictions = [];
          _tempMapCenter = latLng;
          FocusScope.of(context).unfocus(); 
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _openMapSelection(String mode) {
    FocusScope.of(context).unfocus(); 
    setState(() {
      _mapSelectionMode = mode;
      LatLng fallbackLoc = const LatLng(30.0444, 31.2357);
      if (mode == 'pickup') {
        _tempMapCenter = _pickupLocation ?? fallbackLoc;
        _mapSearchController.text = _pickupController.text.contains('📍') ? '' : _pickupController.text;
      } else {
        _tempMapCenter = _destinationLocation ?? _pickupLocation ?? fallbackLoc;
        _mapSearchController.text = _destinationController.text.contains('📍') ? '' : _destinationController.text;
      }
    });
    if (mounted && _mapController != null && _tempMapCenter != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_tempMapCenter!, 18.5));
    }
  }

  Widget _buildVehicleTypeSelector() {
    List<Map<String, dynamic>> vehicles = [
      {'name': 'سيارة', 'icon': Icons.directions_car_rounded, 'color': Colors.blue},
      {'name': 'موتوسيكل', 'icon': Icons.two_wheeler_rounded, 'color': Colors.orange},
      {'name': 'توكتوك', 'icon': Icons.electric_rickshaw_rounded, 'color': Colors.redAccent},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('اختر نوع المركبة:', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: vehicles.map((v) {
            bool isSelected = _vehicleType == v['name'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _vehicleType = v['name']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? royalGreen.withValues(alpha: 0.1) : Colors.white,
                    border: Border.all(color: isSelected ? royalGreen : Colors.grey.shade300, width: isSelected ? 2 : 1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected ? [BoxShadow(color: royalGreen.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
                  ),
                  child: Column(
                    children: [
                      Icon(v['icon'], color: isSelected ? royalGreen : v['color'], size: 32),
                      const SizedBox(height: 4),
                      Text(v['name'], style: TextStyle(fontFamily: 'Cairo', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? royalGreen : Colors.black87, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPassengerRequestTab() {
    bool isErrand = _tripCategory == 'طلبات';
    bool isPickingMap = _mapSelectionMode != 'none'; 

    return Stack(
      children: [
        _isLoadingMap
            ? Center(child: CircularProgressIndicator(color: royalGreen))
            : GoogleMap(
                mapType: MapType.normal, 
                buildingsEnabled: true, 
                initialCameraPosition: CameraPosition(target: _pickupLocation ?? const LatLng(30.0444, 31.2357), zoom: 18.5),
                myLocationEnabled: true, 
                myLocationButtonEnabled: false, 
                zoomControlsEnabled: false,
                markers: isPickingMap ? {} : _markers, 
                onMapCreated: (controller) => _mapController = controller,
                onCameraMove: (CameraPosition position) {
                  if (isPickingMap) _tempMapCenter = position.target;
                },
              ),
              
        if (isPickingMap)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 45.0), 
              child: Icon(
                _mapSelectionMode == 'pickup' ? Icons.location_on : Icons.flag,
                size: 55,
                color: _mapSelectionMode == 'pickup' ? Colors.green : Colors.red,
                shadows: const [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
              ),
            ),
          ),
        
        Positioned(
          top: isPickingMap ? 140 : 16, right: 16, 
          child: FloatingActionButton(mini: true, backgroundColor: Colors.white, foregroundColor: royalGreen, onPressed: _getUserLocation, child: const Icon(Icons.my_location_rounded))
        ),

        if (isPickingMap)
          Positioned(
            top: 20, left: 16, right: 16,
            child: Column(
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: _mapSearchController,
                    onChanged: _searchPlaces, 
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن مكان (مثل: مطعم، شارع)...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.blue),
                      suffixIcon: IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { _mapSearchController.clear(); setState(() => _placePredictions = []); }),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                if (_placePredictions.isNotEmpty)
                  Card(
                    elevation: 4, margin: const EdgeInsets.only(top: 4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true, padding: EdgeInsets.zero,
                        itemCount: _placePredictions.length,
                        itemBuilder: (context, index) {
                          var prediction = _placePredictions[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on, color: Colors.grey),
                            title: Text(prediction['description'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                            onTap: () => _getPlaceDetailsAndMove(prediction['place_id'], prediction['description']),
                          );
                        },
                      ),
                    ),
                  )
              ],
            ),
          ),

        if (isPickingMap)
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: royalGreen, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          setState(() {
                            LatLng finalLoc = _tempMapCenter ?? const LatLng(30.0444, 31.2357);
                            String locationText = _mapSearchController.text.trim().isNotEmpty ? _mapSearchController.text.trim() : "تم التحديد من الخريطة 📍";

                            if (_mapSelectionMode == 'pickup') {
                              _pickupLocation = finalLoc;
                              _pickupController.text = locationText;
                              _markers.removeWhere((m) => m.markerId.value == 'pickup');
                              _markers.add(Marker(markerId: const MarkerId('pickup'), position: finalLoc, infoWindow: const InfoWindow(title: 'مكان التحرك/الشراء'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)));
                            } else if (_mapSelectionMode == 'destination') {
                              _destinationLocation = finalLoc;
                              _destinationController.text = locationText;
                              _markers.removeWhere((m) => m.markerId.value == 'destination');
                              _markers.add(Marker(markerId: const MarkerId('destination'), position: finalLoc, infoWindow: const InfoWindow(title: 'وجهة الوصول/التسليم'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)));
                            }
                            _mapSelectionMode = 'none'; 
                          });
                        },
                        child: const Text('تأكيد الموقع ✅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () { setState(() { _mapSelectionMode = 'none'; _placePredictions = []; }); FocusScope.of(context).unfocus(); },
                      child: const Text('إلغاء ❌', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 16)),
                    ),
                  ],
                )
              ],
            ),
          ),

        if (!isPickingMap)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, -5))]),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'داخلي', label: Text('توصيل', style: TextStyle(fontFamily: 'Cairo')), icon: Icon(Icons.location_city_rounded)),
                          ButtonSegment(value: 'طلبات', label: Text('شراء طلبات', style: TextStyle(fontFamily: 'Cairo')), icon: Icon(Icons.shopping_bag_rounded)),
                          ButtonSegment(value: 'خارجي', label: Text('سفر', style: TextStyle(fontFamily: 'Cairo')), icon: Icon(Icons.emoji_transportation_rounded)),
                        ],
                        selected: {_tripCategory},
                        onSelectionChanged: (Set<String> newSelection) => setState(() { _tripCategory = newSelection.first; _mapSelectionMode = 'none'; }),
                        style: ButtonStyle(backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? royalGreen.withValues(alpha: 0.1) : Colors.transparent)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (isErrand) ...[
                      TextField(controller: _errandDetailsController, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13), decoration: const InputDecoration(labelText: 'اكتب طلباتك (مثال: هاتلي أكل من مطعم...)', prefixIcon: Icon(Icons.shopping_basket, color: Colors.orange), border: UnderlineInputBorder())),
                      const SizedBox(height: 8),
                      TextField(controller: _errandEstimatedCostController, keyboardType: TextInputType.number, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo), decoration: const InputDecoration(labelText: 'سعر الطلبات التقريبي (اللي الكابتن هيدفعه)', suffixText: 'جنيه', prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.indigo), border: UnderlineInputBorder())),
                      const SizedBox(height: 16),
                    ],

                    if (!isErrand) ...[
                      _buildVehicleTypeSelector(), 
                      const SizedBox(height: 16),
                    ],

                    // ✅ تعديل: تم إزالة أيقونة الخريطة الزرقاء الجانبية 
                    TextField(
                      controller: _pickupController, 
                      readOnly: true, 
                      onTap: () => _openMapSelection('pickup'), 
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold), 
                      decoration: InputDecoration(
                        labelText: isErrand ? 'مكان الشراء' : 'موقع التحرك', 
                        prefixIcon: IconButton(icon: Icon(isErrand ? Icons.storefront : Icons.my_location, color: Colors.green), onPressed: () => _openMapSelection('pickup')), 
                        border: const UnderlineInputBorder()
                      )
                    ),
                    const SizedBox(height: 8),
                    
                    // ✅ تعديل: تم إزالة أيقونة الخريطة الزرقاء الجانبية
                    TextField(
                      controller: _destinationController, 
                      readOnly: true, 
                      onTap: () => _openMapSelection('destination'), 
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold), 
                      decoration: InputDecoration(
                        labelText: isErrand ? 'مكان تسليم الطلب' : 'وجهة الوصول', 
                        prefixIcon: IconButton(icon: const Icon(Icons.flag, color: Colors.red), onPressed: () => _openMapSelection('destination')), 
                        border: const UnderlineInputBorder()
                      )
                    ),

                    const SizedBox(height: 12),
                    TextField(controller: _priceController, keyboardType: TextInputType.number, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: isErrand ? 'أجرة التوصيل للكابتن (ج)' : 'سعرك (ج)', prefixIcon: const Icon(Icons.payments, color: Colors.green), border: const UnderlineInputBorder())),

                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: royalGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: _isSubmittingTrip ? null : _createNewTripRequest,
                      child: _isSubmittingTrip ? const CircularProgressIndicator(color: Colors.white) : Text(isErrand ? 'إرسال الطلب للكباتن 🛍️' : 'طلب الكابتن وتأكيد السعر 🚀', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    )
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // شاشات المتابعة وإلغاء الرحلات
  // ==========================================

  Widget _buildAvailableTravelsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trips').where('isDriverPost', isEqualTo: true).where('status', isEqualTo: 'available').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var trips = snapshot.data!.docs;
        if (trips.isEmpty) return const Center(child: Text('لا توجد رحلات سفر مطروحة حالياً 🛣️', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            var data = trips[index].data() as Map<String, dynamic>;
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
                    Text('من: ${data['fromCity']} ➡️ إلى: ${data['toCity']}', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('الموعد: ${data['time']} | المقاعد المتاحة: ${data['availableSeats']}', style: TextStyle(color: Colors.grey.shade700, fontFamily: 'Cairo')),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: royalGreen, foregroundColor: Colors.white), onPressed: () => _bookDriverPost(trips[index].id, data['driverId']), icon: const Icon(Icons.event_seat_rounded, size: 18), label: const Text('حجز مقعد والتواصل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))))
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPassengerMyRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trips').where('passengerId', isEqualTo: currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var trips = snapshot.data!.docs.where((doc) => (doc.data() as Map)['isDriverPost'] != true).toList();
        trips.sort((a, b) => ((b.data() as Map)['createdAt'] as Timestamp?)?.compareTo(((a.data() as Map)['createdAt'] as Timestamp?) ?? Timestamp.now()) ?? 0);        
        if (trips.isEmpty) return const Center(child: Text('لم تقم بأي طلبات بعد.', style: TextStyle(fontFamily: 'Cairo')));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            var doc = trips[index];
            var data = doc.data() as Map<String, dynamic>;
            String status = data['status'];
            bool isErrand = data['tripCategory'] == 'طلبات';

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
                        Text(isErrand ? 'طلب شراء وتوصيل 🛍️' : 'مشوار توصيل 🚖', style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                        Row(children: [const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(_formatDateTime(data['createdAt']), style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold))]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(isErrand ? 'أجرة التوصيل: ${data['suggestedPrice']} ج' : '${data['vehicleType']} - السعر المقترح: ${data['suggestedPrice']} ج', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 15)),
                    
                    if (status == 'canceled') ...[
                      const SizedBox(height: 8),
                      Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: const Text('تم إلغاء هذه الرحلة 🚫', textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Cairo')))
                    ],

                    if (status == 'pending') ...[
                      const Text('جاري البحث عن كباتن... ⏳', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(onPressed: () => _cancelTrip(doc.id, 'passenger'), icon: const Icon(Icons.cancel, color: Colors.red), label: const Text('إلغاء الطلب', style: TextStyle(color: Colors.red, fontFamily: 'Cairo')))
                    ],

                    if (status == 'accepted' || status == 'negotiating') ...[
                       if (status == 'accepted') const Text('الكابتن استلم الطلب وجاي في الطريق 🚀', style: TextStyle(fontFamily: 'Cairo', color: Colors.green, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 8),
                       Row(
                         children: [
                           if (status == 'accepted') Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: royalGreen), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: doc.id))), icon: const Icon(Icons.chat, color: Colors.white), label: const Text('المحادثة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')))),
                           if (status == 'accepted') const SizedBox(width: 8),
                           Expanded(child: OutlinedButton.icon(onPressed: () => _cancelTrip(doc.id, 'passenger'), icon: const Icon(Icons.cancel, color: Colors.red), label: const Text('إلغاء', style: TextStyle(color: Colors.red, fontFamily: 'Cairo'))))
                         ],
                       )
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDriverRadarTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trips').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('حدث خطأ في الاتصال ❌', style: TextStyle(fontFamily: 'Cairo', color: Colors.red)));
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: royalGreen));
        
        var trips = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return data['isDriverPost'] != true;
        }).toList();

        trips.sort((a, b) {
          var timeA = (a.data() as Map)['createdAt'] as Timestamp?;
          var timeB = (b.data() as Map)['createdAt'] as Timestamp?;
          if (timeA == null) return 1; if (timeB == null) return -1;
          return timeB.compareTo(timeA);
        });

        if (trips.isEmpty) return Center(child: Text('رادار لَمَّة شغال.. لا يوجد طلبات حالياً 📡', style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Cairo')));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            var doc = trips[index];
            var data = doc.data() as Map<String, dynamic>;
            bool isErrand = data['tripCategory'] == 'طلبات';

            return Card(
              elevation: 4, margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isErrand ? Colors.indigo.shade50 : royalGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(isErrand ? '🛍️ طلب شراء أوردر' : '🚖 مشوار توصيل', style: TextStyle(color: isErrand ? Colors.indigo : royalGreen, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12))),
                        Text(_formatDateTime(data['createdAt']), style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(isErrand ? 'العميل: ${data['passengerName']}' : 'المركبة: ${data['vehicleType']} - العميل: ${data['passengerName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo', color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(isErrand ? 'من (مكان الشراء): ${data['pickup']}\nإلى (مكان التسليم): ${data['destination']}' : 'من: ${data['pickup']}\nإلى: ${data['destination']}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)), child: Text(isErrand ? 'أجرة التوصيل المقترحة: ${data['suggestedPrice']} جنيه' : 'سعر العميل المقترح: ${data['suggestedPrice']} جنيه', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: royalGreen), onPressed: () => _acceptTripRequest(doc.id, data['suggestedPrice'], data['passengerId']), child: const Text('قبول بالأجرة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)))),
                        const SizedBox(width: 8),
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), onPressed: () => _showCounterOfferDialog(doc.id, data['passengerId']), child: const Text('عرض أجرة آخرى', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 11)))),
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

  Widget _buildDriverPostTripTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('طرح رحلة سفر جديدة 🛣️', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              const SizedBox(height: 20),
              TextField(controller: _postFromCtrl, decoration: InputDecoration(labelText: 'مدينة التحرك', prefixIcon: const Icon(Icons.location_on), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              TextField(controller: _postToCtrl, decoration: InputDecoration(labelText: 'مدينة الوصول', prefixIcon: const Icon(Icons.flag), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              TextField(controller: _postTimeCtrl, decoration: InputDecoration(labelText: 'موعد وتاريخ التحرك', prefixIcon: const Icon(Icons.access_time), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              Row(children: [Expanded(child: TextField(controller: _postSeatsCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'المقاعد المتاحة', prefixIcon: const Icon(Icons.airline_seat_recline_normal), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))), const SizedBox(width: 12), Expanded(child: TextField(controller: _postPriceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'سعر المقعد (ج)', prefixIcon: const Icon(Icons.payments_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))))]),
              const SizedBox(height: 24),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: royalGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _postNewTrip, child: const Text('نشر الرحلة للعملاء', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverActiveTripsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trips').where('driverId', isEqualTo: currentUserId).where('status', whereIn: ['negotiating', 'accepted']).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var trips = snapshot.data!.docs;
        if (trips.isEmpty) return const Center(child: Text('لا توجد رحلات/طلبات نشطة حالياً.', style: TextStyle(fontFamily: 'Cairo')));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            var data = trips[index].data() as Map<String, dynamic>;
            bool isNegotiating = data['status'] == 'negotiating';
            bool isErrand = data['tripCategory'] == 'طلبات';

            return Card(
              elevation: 3, margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(isErrand ? 'تنفيذ طلب أوردر للعميل' : 'توصيل عميل (${data['vehicleType']})', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14)),
                    const SizedBox(height: 12),
                    
                    if (isNegotiating)
                      Text('في انتظار رد العميل على عرضك (${data['driverOffer']} ج) ⏳', style: const TextStyle(color: Colors.orange, fontFamily: 'Cairo', fontWeight: FontWeight.bold))
                    else
                      Row(
                        children: [
                          Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: trips[index].id))), icon: const Icon(Icons.chat, color: Colors.white, size: 18), label: const Text('محادثة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 12)))),
                          const SizedBox(width: 4),
                          Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: royalGreen), onPressed: () => _showRatingDialog(trips[index].id, isDriver: true), icon: const Icon(Icons.done_all, color: Colors.white, size: 18), label: const Text('إنهاء', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 12)))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(onPressed: () => _cancelTrip(trips[index].id, 'driver'), icon: const Icon(Icons.cancel, color: Colors.red, size: 18), label: const Text('إلغاء واعتذار', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 12)))
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // ⚙️ العمليات (إضافة/قبول/إلغاء)
  // ==========================================

  Future<void> _createNewTripRequest() async {
    bool isErrand = _tripCategory == 'طلبات';

    if (_destinationController.text.trim().isEmpty || _priceController.text.trim().isEmpty || _pickupController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إكمال جميع الحقول!', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isSubmittingTrip = true);
    try {
      await FirebaseFirestore.instance.collection('trips').add({
        'isDriverPost': false, 'passengerId': currentUserId, 'passengerName': 'عميل لَمَّة', 
        'tripCategory': _tripCategory, 'vehicleType': isErrand ? 'موتوسيكل' : _vehicleType, 
        'pickup': _pickupController.text.trim(), 'destination': _destinationController.text.trim(), 'suggestedPrice': _priceController.text.trim(),
        'pickupLocation': _pickupLocation != null ? GeoPoint(_pickupLocation!.latitude, _pickupLocation!.longitude) : null,
        'destinationLocation': _destinationLocation != null ? GeoPoint(_destinationLocation!.latitude, _destinationLocation!.longitude) : null,
        'status': 'pending', 'createdAt': FieldValue.serverTimestamp(),
      });
      if(mounted) {
        _destinationController.clear(); _priceController.clear(); _tabController.animateTo(2); 
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ في الشبكة')));
    } finally {
      if(mounted) setState(() => _isSubmittingTrip = false);
    }
  }

  Future<void> _cancelTrip(String tripId, String canceledByRole) async {
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
        'canceledBy': canceledByRole 
      });
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الرحلة بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.orange));
      }
    }
  }

  Future<void> _acceptTripRequest(String tripId, String agreedPrice, String passengerId) async {
    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({'status': 'accepted', 'driverId': currentUserId, 'driverName': 'كابتن لَمَّة', 'finalPrice': agreedPrice});
    if(mounted) _tabController.animateTo(2); 
  }

  void _showCounterOfferDialog(String tripId, String passengerId) {
    TextEditingController offerCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('تقديم عرض', style: TextStyle(fontFamily: 'Cairo')), content: TextField(controller: offerCtrl, keyboardType: TextInputType.number), actions: [ElevatedButton(onPressed: () async { await FirebaseFirestore.instance.collection('trips').doc(tripId).update({'status': 'negotiating', 'driverId': currentUserId, 'driverOffer': offerCtrl.text}); if(mounted) { Navigator.pop(ctx); _tabController.animateTo(2); } }, child: const Text('إرسال'))]));
  }

  Future<void> _postNewTrip() async {
    if (_postFromCtrl.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('trips').add({'isDriverPost': true, 'driverId': currentUserId, 'driverName': 'كابتن', 'fromCity': _postFromCtrl.text.trim(), 'toCity': _postToCtrl.text.trim(), 'time': _postTimeCtrl.text.trim(), 'availableSeats': _postSeatsCtrl.text.trim(), 'price': _postPriceCtrl.text.trim(), 'status': 'available', 'createdAt': FieldValue.serverTimestamp()});
    if(mounted) { _postFromCtrl.clear(); _tabController.animateTo(2); }
  }

  Future<void> _bookDriverPost(String tripId, String driverId) async {
    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({'status': 'accepted', 'passengerId': currentUserId});
    if(mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: tripId)));
  }

  void _showRatingDialog(String tripId, {required bool isDriver}) {
    int stars = 5; 
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                const Text('تم إنهاء الرحلة!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) => IconButton(icon: Icon(index < stars ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 35), onPressed: () => setDialogState(() => stars = index + 1)))),
                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: royalGreen), onPressed: () async { await FirebaseFirestore.instance.collection('trips').doc(tripId).update({isDriver ? 'driverRatingForPassenger' : 'passengerRating': stars, if (isDriver) 'status': 'completed'}); if(mounted) Navigator.pop(ctx); }, child: const Text('إرسال', style: TextStyle(color: Colors.white)))
              ],
            ),
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDriver ? 'لوحة الكابتن 🚖' : 'خدمات لَمَّة 📍', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        backgroundColor: royalGreen, foregroundColor: Colors.white, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.home_rounded), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()))),
        bottom: TabBar(
          controller: _tabController, indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
          // ✅ تعديل: تم تغيير كلمة "متابعة" إلى "متابعة طلباتي" للعميل
          tabs: widget.isDriver ? const [Tab(text: 'الرادار'), Tab(text: 'إضافة رحلة'), Tab(text: 'طلباتي النشطة')] : const [Tab(text: 'طلب مشوار/أوردر'), Tab(text: 'رحلات السفر'), Tab(text: 'متابعة طلباتي')],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: TabBarView(
          controller: _tabController, physics: const NeverScrollableScrollPhysics(), 
          children: widget.isDriver
              ? [ _buildDriverRadarTab(), _buildDriverPostTripTab(), _buildDriverActiveTripsTab() ]
              : [ _buildPassengerRequestTab(), _buildAvailableTravelsTab(), _buildPassengerMyRequestsTab() ],
        ),
      ),
    );
  }
}