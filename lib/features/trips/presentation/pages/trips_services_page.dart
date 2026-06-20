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
  final Map<String, bool> _cancellationTimers = {}; 

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
  final TextEditingController _pickupController = TextEditingController(text: 'موقعي الحالي');
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController(); 
  
  final TextEditingController _errandDetailsController = TextEditingController();
  final TextEditingController _errandEstimatedCostController = TextEditingController(); 
  
  final TextEditingController _postFromCtrl = TextEditingController();
  final TextEditingController _postToCtrl = TextEditingController();
  final TextEditingController _postTimeCtrl = TextEditingController();
  final TextEditingController _postVehicleTypeCtrl = TextEditingController();
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
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
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
    _postVehicleTypeCtrl.dispose(); 
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
        _mapSearchController.text = _pickupController.text.isNotEmpty ? _pickupController.text : '';
      } else {
        _tempMapCenter = _destinationLocation ?? _pickupLocation ?? fallbackLoc;
        _mapSearchController.text = _destinationController.text.isNotEmpty ? _destinationController.text : '';
      }
    });
    if (mounted && _mapController != null && _tempMapCenter != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_tempMapCenter!, 18.5));
    }
  }

  Widget _buildTripCategorySelector() {
    List<Map<String, dynamic>> categories = [
      {'id': 'داخلي', 'name': 'توصيل', 'icon': Icons.local_taxi_rounded},
      {'id': 'طلبات', 'name': 'شراء طلبات', 'icon': Icons.shopping_bag_rounded},
      {'id': 'خارجي', 'name': 'سفر', 'icon': Icons.emoji_transportation_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: categories.map((c) {
          bool isSelected = _tripCategory == c['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _tripCategory = c['id'];
                  _mapSelectionMode = 'none';
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(c['icon'], color: isSelected ? royalGreen : Colors.grey.shade600, size: 16),
                    const SizedBox(width: 4),
                    Text(c['name'], style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? royalGreen : Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
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

    return LayoutBuilder(
      builder: (context, constraints) {
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

            if (isPickingMap)
              Positioned(
                top: 20, left: 16, right: 16,
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: TextField(
                                controller: _mapSearchController,
                                onChanged: _searchPlaces, 
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: 'ابحث عن مكان...',
                                  prefixIcon: IconButton(
                                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20), 
                                    onPressed: () { 
                                      setState(() { _mapSelectionMode = 'none'; _placePredictions = []; }); 
                                      FocusScope.of(context).unfocus(); 
                                    }
                                  ),
                                  suffixIcon: IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { _mapSearchController.clear(); setState(() => _placePredictions = []); }),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FloatingActionButton(
                            mini: true, 
                            backgroundColor: Colors.white, 
                            foregroundColor: royalGreen, 
                            onPressed: _getUserLocation, 
                            child: const Icon(Icons.my_location_rounded)
                          ),
                        ],
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
              ),

            if (isPickingMap)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app_rounded, size: 18, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text('حرك الخريطة لتحديد الموقع بدقة', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: royalGreen, 
                              padding: const EdgeInsets.symmetric(vertical: 16), 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              setState(() {
                                LatLng finalLoc = _tempMapCenter ?? const LatLng(30.0444, 31.2357);
                                String locationText = _mapSearchController.text.trim().isNotEmpty ? _mapSearchController.text.trim() : "تم التحديد من الخريطة";

                                if (_mapSelectionMode == 'pickup') {
                                  _pickupLocation = finalLoc;
                                  _pickupController.text = locationText;
                                  _markers.removeWhere((m) => m.markerId.value == 'pickup');
                                  _markers.add(Marker(markerId: const MarkerId('pickup'), position: finalLoc, infoWindow: const InfoWindow(title: 'مكان التحرك'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)));
                                } else if (_mapSelectionMode == 'destination') {
                                  _destinationLocation = finalLoc;
                                  _destinationController.text = locationText;
                                  _markers.removeWhere((m) => m.markerId.value == 'destination');
                                  _markers.add(Marker(markerId: const MarkerId('destination'), position: finalLoc, infoWindow: const InfoWindow(title: 'وجهة الوصول'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)));
                                }
                                _mapSelectionMode = 'none'; 
                              });
                            },
                            child: const Text('تأكيد الموقع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (!isPickingMap)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.95, // إضافة الحد الأقصى للارتفاع لضمان عدم الخروج عن الشاشة
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)), 
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, -5))]
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTripCategorySelector(),
                        const SizedBox(height: 16),
                        
                        if (isErrand)
                          Column(
                            children: [
                              TextField(
                                controller: _errandDetailsController, 
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13), 
                                decoration: InputDecoration(
                                  labelText: 'اكتب طلباتك', 
                                  prefixIcon: const Icon(Icons.shopping_basket, color: Colors.orange), 
                                  filled: true, fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                                )
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _errandEstimatedCostController, 
                                keyboardType: TextInputType.number, 
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo), 
                                decoration: InputDecoration(
                                  labelText: 'سعر الطلبات التقريبي', 
                                  suffixText: 'جنيه', 
                                  prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.indigo), 
                                  filled: true, fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                                )
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),

                        if (!isErrand)
                          Column(
                            children: [
                              _buildVehicleTypeSelector(), 
                              const SizedBox(height: 16),
                            ],
                          ),

                        TextField(
                          controller: _pickupController, 
                          readOnly: true, 
                          onTap: () => _openMapSelection('pickup'), 
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold), 
                          decoration: InputDecoration(
                            labelText: isErrand ? 'مكان الشراء' : 'موقع التحرك', 
                            prefixIcon: const Icon(Icons.my_location, color: Colors.green), 
                            filled: true, fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                          )
                        ),
                        const SizedBox(height: 12),
                        
                        TextField(
                          controller: _destinationController, 
                          readOnly: true, 
                          onTap: () => _openMapSelection('destination'), 
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold), 
                          decoration: InputDecoration(
                            labelText: isErrand ? 'مكان تسليم الطلب' : 'وجهة الوصول', 
                            prefixIcon: const Icon(Icons.location_on, color: Colors.red), 
                            filled: true, fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                          )
                        ),

                        const SizedBox(height: 12),
                        
                        TextField(
                          controller: _priceController, 
                          keyboardType: TextInputType.number, 
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold), 
                          decoration: InputDecoration(
                            labelText: isErrand ? 'أجرة التوصيل للكابتن' : 'سعرك المقترح', 
                            suffixText: 'جنيه',
                            prefixIcon: const Icon(Icons.payments, color: Colors.green), 
                            filled: true, fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                          )
                        ),

                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: royalGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: _isSubmittingTrip ? null : _createNewTripRequest,
                          child: _isSubmittingTrip ? const CircularProgressIndicator(color: Colors.white) : Text(isErrand ? 'إرسال الطلب للكباتن' : 'طلب الكابتن وتأكيد السعر', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        )
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      }
    );
  }

  Widget _buildAvailableTravelsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trips').where('isDriverPost', isEqualTo: true).where('status', isEqualTo: 'available').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var trips = snapshot.data!.docs;
        if (trips.isEmpty) return const Center(child: Text('لا توجد رحلات سفر مطروحة حاليا', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold)));

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
                    Text('من: ${data['fromCity']} الى: ${data['toCity']}', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('المركبة: ${data['vehicleType'] ?? 'سيارة'} | المقاعد المتاحة: ${data['availableSeats']}', style: TextStyle(color: Colors.grey.shade700, fontFamily: 'Cairo')),
                    const SizedBox(height: 4),
                    Text('الموعد: ${data['time']}', style: TextStyle(color: Colors.grey.shade700, fontFamily: 'Cairo')),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade100,
              foregroundColor: Colors.amber.shade900,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 50)
            ),
            onPressed: _showFavoriteDriversBottomSheet,
            icon: const Icon(Icons.star_rounded, color: Colors.amber),
            label: const Text('قائمة كباتني المفضلين', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('trips').where('passengerId', isEqualTo: currentUserId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              var trips = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                bool isNotDriverPost = data['isDriverPost'] != true;
                bool isNotDeleted = data['isDeletedForPassenger'] != true;
                return isNotDriverPost && isNotDeleted;
              }).toList();

              trips.sort((a, b) => ((b.data() as Map)['createdAt'] as Timestamp?)?.compareTo(((a.data() as Map)['createdAt'] as Timestamp?) ?? Timestamp.now()) ?? 0);        
              
              if (trips.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('لا توجد طلبات سابقة حاليا', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                );
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
                    Future.delayed(const Duration(seconds: 10), () {
                      if (mounted) _deleteTripForUser(doc.id, 'passenger');
                    });
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
                            Column(
                              children: [
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: royalGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), 
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('تم إلغاء هذه الرحلة', textAlign: TextAlign.center, style: TextStyle(color: royalGreen, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(Icons.close, color: royalGreen),
                                        onPressed: () => _deleteTripForUser(doc.id, 'passenger'),
                                      )
                                    ],
                                  )
                                )
                              ],
                            )
                          else if (status == 'pending')
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('جاري البحث عن كباتن...', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(onPressed: () => _cancelTrip(doc.id, 'passenger'), icon: const Icon(Icons.cancel, color: Colors.red), label: const Text('إلغاء الطلب', style: TextStyle(color: Colors.red, fontFamily: 'Cairo')))
                              ],
                            )
                          else if (status == 'negotiating')
                            Column(
                              children: [
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                                  child: Column(
                                    children: [
                                      if (data['lastNegotiator'] == 'driver')
                                        Column(
                                          children: [
                                            Text('الكابتن عرض عليك أجرة: ${data['negotiationPrice']} جنيه', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14)),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: royalGreen, padding: const EdgeInsets.symmetric(horizontal: 4)), onPressed: () => _acceptOffer(doc.id, data['negotiationPrice']), icon: const Icon(Icons.check, color: Colors.white, size: 16), label: const Text('موافق', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)))),
                                                const SizedBox(width: 4),
                                                Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 4)), onPressed: () => _showNegotiationDialog(doc.id, isDriver: false), icon: const Icon(Icons.edit, color: Colors.white, size: 16), label: const Text('تفاوض', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)))),
                                                const SizedBox(width: 4),
                                                Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)), onPressed: () => _cancelTrip(doc.id, 'passenger'), icon: const Icon(Icons.close, color: Colors.red, size: 16), label: const Text('رفض', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12))))
                                              ],
                                            )
                                          ],
                                        )
                                      else
                                        Column(
                                          children: [
                                            Text('في انتظار رد الكابتن على عرضك (${data['negotiationPrice']} ج)', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                                            const SizedBox(height: 8),
                                            OutlinedButton.icon(onPressed: () => _cancelTrip(doc.id, 'passenger'), icon: const Icon(Icons.cancel, color: Colors.red, size: 18), label: const Text('إلغاء الطلب', style: TextStyle(color: Colors.red, fontFamily: 'Cairo')))
                                          ],
                                        )
                                    ],
                                  ),
                                )
                              ],
                            )
                          else if (status == 'accepted')
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الكابتن استلم الطلب وجاي في الطريق', style: TextStyle(fontFamily: 'Cairo', color: Colors.green, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: royalGreen), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: doc.id))), icon: const Icon(Icons.chat, color: Colors.white), label: const Text('المحادثة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')))),
                                    const SizedBox(width: 8),
                                    Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), onPressed: () => _showRatingDialog(doc.id, isDriver: false, targetId: data['driverId'], targetName: data['driverName']), icon: const Icon(Icons.star, color: Colors.white), label: const Text('إنهاء وتقييم', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _cancelTrip(doc.id, 'passenger'), icon: const Icon(Icons.cancel, color: Colors.red), label: const Text('إلغاء الرحلة', style: TextStyle(color: Colors.red, fontFamily: 'Cairo'))))
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

  Widget _buildDriverRadarTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trips').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('حدث خطأ في الاتصال', style: TextStyle(fontFamily: 'Cairo', color: Colors.red)));
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

        if (trips.isEmpty) return Center(child: Text('رادار الطلبات شغال.. لا يوجد طلبات حاليا', style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Cairo')));

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
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isErrand ? Colors.indigo.shade50 : royalGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(isErrand ? 'طلب شراء أوردر' : 'مشوار توصيل', style: TextStyle(color: isErrand ? Colors.indigo : royalGreen, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12))),
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
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: royalGreen), onPressed: () => _acceptTripRequest(doc.id, data['suggestedPrice']), child: const Text('قبول بالأجرة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)))),
                        const SizedBox(width: 8),
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), onPressed: () => _showNegotiationDialog(doc.id, isDriver: true), child: const Text('عرض أجرة آخرى', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 11)))),
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
              const Text('طرح رحلة سفر جديدة', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              const SizedBox(height: 20),
              TextField(controller: _postFromCtrl, decoration: InputDecoration(labelText: 'مدينة التحرك', prefixIcon: const Icon(Icons.location_on), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              TextField(controller: _postToCtrl, decoration: InputDecoration(labelText: 'مدينة الوصول', prefixIcon: const Icon(Icons.flag), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              TextField(controller: _postTimeCtrl, decoration: InputDecoration(labelText: 'موعد وتاريخ التحرك', prefixIcon: const Icon(Icons.access_time), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              TextField(controller: _postVehicleTypeCtrl, decoration: InputDecoration(labelText: 'نوع العربية (مثال: ملاكي، ميكروباص 14)', prefixIcon: const Icon(Icons.directions_car_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              
              Row(children: [
                Expanded(child: TextField(controller: _postSeatsCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'المقاعد المتاحة', prefixIcon: const Icon(Icons.airline_seat_recline_normal), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))), 
                const SizedBox(width: 12), 
                Expanded(child: TextField(controller: _postPriceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'سعر المقعد (ج)', prefixIcon: const Icon(Icons.payments_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))))
              ]),
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
                if (mounted) _deleteTripForUser(trips[index].id, 'driver');
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
                            width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: royalGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), 
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('تم إلغاء هذه الرحلة', textAlign: TextAlign.center, style: TextStyle(color: royalGreen, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                const Spacer(),
                                IconButton(
                                  icon: Icon(Icons.close, color: royalGreen),
                                  onPressed: () => _deleteTripForUser(trips[index].id, 'driver'),
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
                                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 4)), onPressed: () => _showNegotiationDialog(trips[index].id, isDriver: true), child: const Text('تفاوض', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 12)))),
                                    const SizedBox(width: 4),
                                    Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)), onPressed: () => _cancelTrip(trips[index].id, 'driver'), child: const Text('رفض', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 12)))),
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
                              Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: royalGreen), onPressed: () => _showRatingDialog(trips[index].id, isDriver: true, targetId: data['passengerId'], targetName: data['passengerName']), icon: const Icon(Icons.done_all, color: Colors.white, size: 18), label: const Text('إنهاء وتقييم', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 12)))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(onPressed: () => _cancelTrip(trips[index].id, 'driver'), icon: const Icon(Icons.cancel, color: Colors.red, size: 18), label: const Text('إلغاء واعتذار', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 12)))
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

  Future<void> _deleteTripForUser(String tripId, String role) async {
    String deleteField = role == 'driver' ? 'isDeletedForDriver' : 'isDeletedForPassenger';
    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
      deleteField: true
    });
  }

  Future<void> _createNewTripRequest() async {
    bool isErrand = _tripCategory == 'طلبات';

    if (_destinationController.text.trim().isEmpty || _priceController.text.trim().isEmpty || _pickupController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إكمال جميع الحقول!', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isSubmittingTrip = true);
    try {
      await FirebaseFirestore.instance.collection('trips').add({
        'isDriverPost': false, 'passengerId': currentUserId, 'passengerName': 'عميل', 
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

  Future<void> _acceptTripRequest(String tripId, String agreedPrice) async {
    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({'status': 'accepted', 'driverId': currentUserId, 'driverName': 'كابتن', 'finalPrice': agreedPrice});
    if(mounted) _tabController.animateTo(2); 
  }

  Future<void> _acceptOffer(String tripId, String acceptedPrice) async {
    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
      'status': 'accepted',
      'finalPrice': acceptedPrice
    });
  }

  void _showNegotiationDialog(String tripId, {required bool isDriver}) {
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
                if (isDriver) 'driverId': currentUserId, 
                if (isDriver) 'driverName': 'كابتن لمة', 
                'negotiationPrice': offerCtrl.text,
                'lastNegotiator': isDriver ? 'driver' : 'passenger'
              }); 
              if(mounted) { 
                Navigator.pop(ctx); 
                if (isDriver) _tabController.animateTo(2); 
              } 
            }, 
            child: const Text('إرسال', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold))
          )
        ]
      )
    );
  }

  Future<void> _postNewTrip() async {
    if (_postFromCtrl.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('trips').add({
      'isDriverPost': true, 
      'driverId': currentUserId, 
      'driverName': 'كابتن', 
      'fromCity': _postFromCtrl.text.trim(), 
      'toCity': _postToCtrl.text.trim(), 
      'time': _postTimeCtrl.text.trim(), 
      'vehicleType': _postVehicleTypeCtrl.text.trim().isNotEmpty ? _postVehicleTypeCtrl.text.trim() : 'سيارة',
      'availableSeats': _postSeatsCtrl.text.trim(), 
      'price': _postPriceCtrl.text.trim(), 
      'status': 'available', 
      'createdAt': FieldValue.serverTimestamp()
    });
    if(mounted) { 
      _postFromCtrl.clear(); 
      _postToCtrl.clear();
      _postTimeCtrl.clear();
      _postVehicleTypeCtrl.clear(); 
      _postSeatsCtrl.clear();
      _postPriceCtrl.clear();
      _tabController.animateTo(2); 
    }
  }

  Future<void> _bookDriverPost(String tripId, String driverId) async {
    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({'status': 'accepted', 'passengerId': currentUserId});
    if(mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatPage(tripId: tripId)));
  }

  void _showRatingDialog(String tripId, {required bool isDriver, String? targetId, String? targetName}) {
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
                
                if (!isDriver && targetId != null)
                  Column(
                    children: [
                      const Divider(),
                      CheckboxListTile(
                        title: const Text('حفظ الكابتن في المفضلة', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
                        value: saveToFavorites,
                        activeColor: Colors.amber,
                        onChanged: (val) => setDialogState(() => saveToFavorites = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      )
                    ],
                  ),

                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: royalGreen, minimumSize: const Size(double.infinity, 45)), 
                  onPressed: () async { 
                    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
                      isDriver ? 'driverRatingForPassenger' : 'passengerRating': stars, 
                      if (isDriver) 'status': 'completed'
                    }); 
                    
                    if (!isDriver && saveToFavorites && targetId != null) {
                      await FirebaseFirestore.instance.collection('users').doc(currentUserId).set({
                        'favoriteDrivers': FieldValue.arrayUnion([{
                          'id': targetId,
                          'name': targetName ?? 'كابتن لمة'
                        }])
                      }, SetOptions(merge: true));
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
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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

                    if (favs.isEmpty) {
                      return const Center(child: Text('لسه مفيش كباتن في المفضلة عندك', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)));
                    }

                    return ListView.builder(
                      itemCount: favs.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.star, color: Colors.white)),
                          title: Text(favs[index]['name'], style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
                                'favoriteDrivers': FieldValue.arrayRemove([favs[index]])
                              });
                            },
                          ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDriver ? 'لوحة الكابتن' : 'خدمات', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        backgroundColor: royalGreen, foregroundColor: Colors.white, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.home_rounded), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()))),
        
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15), 
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent, 
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white, 
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              labelColor: royalGreen, 
              unselectedLabelColor: Colors.white, 
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
              tabs: widget.isDriver 
                  ? const [Tab(text: 'رادار الطلبات'), Tab(text: 'إضافة رحلة'), Tab(text: 'طلباتي النشطة')] 
                  : const [Tab(text: 'طلب مشوار'), Tab(text: 'رحلات السفر'), Tab(text: 'متابعة طلباتي')],
            ),
          ),
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