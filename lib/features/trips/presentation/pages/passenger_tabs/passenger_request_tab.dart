// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PassengerRequestTab extends StatefulWidget {
  final TabController tabController;
  const PassengerRequestTab({super.key, required this.tabController});

  @override
  State<PassengerRequestTab> createState() => _PassengerRequestTabState();
}

class _PassengerRequestTabState extends State<PassengerRequestTab> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color royalGreen = const Color(0xFF1B4332);
  
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {}; 
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  bool _isLoadingMap = true;
  String _mapSelectionMode = 'none'; 
  LatLng? _tempMapCenter; 
  Timer? _debounce; 

  final TextEditingController _mapSearchController = TextEditingController();
  final String googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? ''; 
  List<dynamic> _placePredictions = [];

  bool _isReverseGeocoding = false;
  bool _shouldReverseGeocode = true;

  bool _isSubmittingTrip = false;
  String _tripCategory = 'داخلي'; 
  String _vehicleType = 'سيارة'; 
  final TextEditingController _pickupController = TextEditingController(text: 'موقعي الحالي');
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController(); 
  final TextEditingController _errandDetailsController = TextEditingController();
  final TextEditingController _errandEstimatedCostController = TextEditingController(); 

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    _errandDetailsController.dispose();
    _errandEstimatedCostController.dispose();
    _mapSearchController.dispose();
    _debounce?.cancel();
    if (_mapController != null) {
      _mapController!.dispose();
    }
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoadingMap = true);
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { if (mounted) setState(() => _isLoadingMap = false); return; }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) { if (mounted) setState(() => _isLoadingMap = false); return; }
    }
    if (permission == LocationPermission.deniedForever) { if (mounted) setState(() => _isLoadingMap = false); return; }

    try {
      Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation));
      if (mounted) {
        LatLng newLoc = LatLng(position.latitude, position.longitude);
        setState(() {
          _pickupLocation = newLoc;
          _isLoadingMap = false;
          _markers.removeWhere((m) => m.markerId.value == 'pickup');
          _markers.add(Marker(
            markerId: const MarkerId('pickup'), 
            position: newLoc, 
            infoWindow: const InfoWindow(title: 'موقعك الحالي'), 
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
          ));
          if (_mapSelectionMode != 'none') _tempMapCenter = newLoc; 
        });
        
        if (mounted && _mapController != null) {
          try { _mapController!.animateCamera(CameraUpdate.newLatLngZoom(newLoc, 15.0)); } catch (e) { debugPrint("$e"); }
        }
      }
    } catch (e) { if (mounted) setState(() => _isLoadingMap = false); }
  }

  Future<void> _performReverseGeocoding(LatLng latLng) async {
    if (googleApiKey.isEmpty) return;
    setState(() => _isReverseGeocoding = true);
    final String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$googleApiKey&language=ar";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          String formattedAddress = data['results'][0]['formatted_address'];
          setState(() => _mapSearchController.text = formattedAddress);
        }
      }
    } catch (e) {
      debugPrint("خطأ في الجيوديكينج: $e");
    } finally {
      setState(() => _isReverseGeocoding = false);
    }
  }

  void _searchPlaces(String input) async {
    if (input.isEmpty) { setState(() => _placePredictions = []); return; }
    String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$googleApiKey&language=ar&components=country:eg";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) setState(() => _placePredictions = json.decode(response.body)['predictions']);
    } catch (e) { debugPrint("Error: $e"); }
  }

  void _getPlaceDetailsAndMove(String placeId, String description) async {
    String url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleApiKey";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var location = json.decode(response.body)['result']['geometry']['location'];
        LatLng latLng = LatLng(location['lat'], location['lng']);
        
        _shouldReverseGeocode = false; 
        if (mounted && _mapController != null) _mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15.0)); 

        setState(() { 
          _mapSearchController.text = description; 
          _placePredictions = []; 
          _tempMapCenter = latLng; 
          FocusScope.of(context).unfocus(); 
        });
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  void _openMapSelection(String mode) {
    FocusScope.of(context).unfocus(); 
    setState(() {
      _mapSelectionMode = mode;
      LatLng fallbackLoc = const LatLng(30.0444, 31.2357);
      if (mode == 'pickup') {
        _tempMapCenter = _pickupLocation ?? fallbackLoc;
        _mapSearchController.text = _pickupController.text.isNotEmpty && _pickupController.text != 'موقعي الحالي' ? _pickupController.text : '';
      } else {
        _tempMapCenter = _destinationLocation ?? _pickupLocation ?? fallbackLoc;
        _mapSearchController.text = _destinationController.text.isNotEmpty ? _destinationController.text : '';
      }
      _shouldReverseGeocode = true;
    });
    if (mounted && _mapController != null && _tempMapCenter != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_tempMapCenter!, 15.0));
    }
  }

  Future<void> _createNewTripRequest() async {
    bool isErrand = _tripCategory == 'طلبات';
    
    if (_destinationController.text.trim().isEmpty || _priceController.text.trim().isEmpty || _pickupController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إكمال جميع الحقول!', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
      return;
    }

    double? suggestedPrice = double.tryParse(_priceController.text.trim());
    if (suggestedPrice == null || suggestedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال سعر صحيح (أرقام فقط)!', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
      return;
    }

    if (isErrand) {
      if (_errandDetailsController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال تفاصيل الطلبات!', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
        return;
      }
      double? errandCost = double.tryParse(_errandEstimatedCostController.text.trim());
      if (errandCost == null || errandCost <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال تكلفة تقريبية صحيحة (أرقام فقط)!', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
        return;
      }
    }
    
    setState(() => _isSubmittingTrip = true);
    
    try {
      await FirebaseFirestore.instance.collection('trips').add({
        'isDriverPost': false, 
        'passengerId': currentUserId, 
        'passengerName': 'عميل', 
        'tripCategory': _tripCategory, 
        'vehicleType': isErrand ? 'موتوسيكل' : _vehicleType, 
        'pickup': _pickupController.text.trim(), 
        'destination': _destinationController.text.trim(), 
        'suggestedPrice': _priceController.text.trim(),
        'errandDetails': isErrand ? _errandDetailsController.text.trim() : '',
        'errandCost': isErrand ? _errandEstimatedCostController.text.trim() : '',
        'pickupLocation': _pickupLocation != null ? GeoPoint(_pickupLocation!.latitude, _pickupLocation!.longitude) : null,
        'destinationLocation': _destinationLocation != null ? GeoPoint(_destinationLocation!.latitude, _destinationLocation!.longitude) : null,
        'status': 'pending', 
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if(mounted) { 
        _destinationController.clear(); 
        _priceController.clear(); 
        _errandDetailsController.clear();
        _errandEstimatedCostController.clear();
        widget.tabController.animateTo(2); 
      }
    } catch (e) { 
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ في الشبكة', style: TextStyle(fontFamily: 'Cairo')))); 
    } finally { 
      if(mounted) setState(() => _isSubmittingTrip = false); 
    }
  }

  Widget _buildTripCategorySelector() {
    List<Map<String, dynamic>> categories = [
      {'id': 'داخلي', 'name': 'توصيل', 'icon': Icons.local_taxi_rounded}, 
      {'id': 'طلبات', 'name': 'شراء طلبات', 'icon': Icons.shopping_bag_rounded}, 
      {'id': 'خارجي', 'name': 'سفر', 'icon': Icons.emoji_transportation_rounded}
    ];
    return Container(
      padding: const EdgeInsets.all(4), 
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: categories.map((c) {
          bool isSelected = _tripCategory == c['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _tripCategory = c['id']; _mapSelectionMode = 'none'; FocusScope.of(context).unfocus(); }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250), 
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : []),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Icon(c['icon'], color: isSelected ? royalGreen : Colors.grey.shade600, size: 16), 
                    const SizedBox(width: 4), 
                    Text(c['name'], style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? royalGreen : Colors.grey.shade600))
                  ]
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
      {'name': 'توكتوك', 'icon': Icons.electric_rickshaw_rounded, 'color': Colors.redAccent}
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
                    boxShadow: isSelected ? [BoxShadow(color: royalGreen.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : []
                  ),
                  child: Column(
                    children: [
                      Icon(v['icon'], color: isSelected ? royalGreen : v['color'], size: 32), 
                      const SizedBox(height: 4), 
                      Text(v['name'], style: TextStyle(fontFamily: 'Cairo', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? royalGreen : Colors.black87, fontSize: 13))
                    ]
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isErrand = _tripCategory == 'طلبات';
    bool isPickingMap = _mapSelectionMode != 'none'; 
    double availableHeight = MediaQuery.of(context).size.height;

    // 🟢 الارتفاع الثابت اللي هيمنع الكارت يغطي الزراير المرفوعة
    double formHeightEstimate = 450.0;
    double bottomPaddingForControls = isPickingMap ? 140 : formHeightEstimate + 20;

    return Stack(
      children: [
        _isLoadingMap
            ? Center(child: CircularProgressIndicator(color: royalGreen))
            : GoogleMap(
                mapType: MapType.normal, 
                buildingsEnabled: true, 
                initialCameraPosition: CameraPosition(target: _pickupLocation ?? const LatLng(30.0444, 31.2357), zoom: 15.0),
                
                myLocationEnabled: true, 
                myLocationButtonEnabled: false, 
                zoomControlsEnabled: false, 
                mapToolbarEnabled: false,

                padding: EdgeInsets.only(top: 100, bottom: isPickingMap ? 120.0 : formHeightEstimate),

                markers: isPickingMap ? {} : _markers, 
                onMapCreated: (controller) => _mapController = controller, 
                onCameraMove: (CameraPosition position) { 
                  if (isPickingMap) {
                    _tempMapCenter = position.target; 
                    _shouldReverseGeocode = true;
                  }
                },
                onCameraIdle: () {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(seconds: 1), () {
                    if (isPickingMap && _shouldReverseGeocode && _tempMapCenter != null) {
                      _performReverseGeocoding(_tempMapCenter!);
                    }
                  });
                },
              ),
              
        if (!_isLoadingMap)
          Positioned(
            bottom: bottomPaddingForControls, 
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.black87), 
                        onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn())
                      ),
                      Container(height: 1, width: 30, color: Colors.grey.shade300),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.black87), 
                        onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut())
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'custom_location_fab', 
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _getUserLocation,
                  child: Icon(Icons.my_location, color: royalGreen),
                ),
              ],
            ),
          ),

        if (isPickingMap)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 45.0), 
              child: Icon(_mapSelectionMode == 'pickup' ? Icons.location_on : Icons.flag, size: 55, color: _mapSelectionMode == 'pickup' ? Colors.green : Colors.red, shadows: const [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))])
            )
          ),

        if (isPickingMap)
          Positioned(
            top: 20, right: 16, left: 16, 
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 8, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: TextField(
                            controller: _mapSearchController, onChanged: _searchPlaces, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'ابحث عن مكان...',
                              prefixIcon: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20), onPressed: () { setState(() { _mapSelectionMode = 'none'; _placePredictions = []; }); FocusScope.of(context).unfocus(); }),
                              suffixIcon: _isReverseGeocoding 
                                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)))
                                  : IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { _mapSearchController.clear(); setState(() => _placePredictions = []); }),
                              border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_placePredictions.isNotEmpty)
                    Card(
                      elevation: 4, margin: const EdgeInsets.only(top: 4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 250), 
                        child: ListView.builder(
                          shrinkWrap: true, padding: EdgeInsets.zero, itemCount: _placePredictions.length, 
                          itemBuilder: (context, index) { 
                            var prediction = _placePredictions[index]; 
                            return ListTile(leading: const Icon(Icons.location_on, color: Colors.grey), title: Text(prediction['description'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)), onTap: () => _getPlaceDetailsAndMove(prediction['place_id'], prediction['description'])); 
                          }
                        )
                      )
                    )
                ],
              ),
            ),
          ),

        if (isPickingMap)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))]),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.touch_app_rounded, size: 18, color: Colors.grey.shade600), const SizedBox(width: 8), Text('حرك الخريطة لتحديد الموقع بدقة', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity, 
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: royalGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                        onPressed: () { 
                          setState(() { 
                            LatLng finalLoc = _tempMapCenter ?? const LatLng(30.0444, 31.2357); 
                            String locationText = _mapSearchController.text.trim().isNotEmpty ? _mapSearchController.text.trim() : "موقع محدد من الخريطة"; 
                            if (_mapSelectionMode == 'pickup') { 
                              _pickupLocation = finalLoc; _pickupController.text = locationText; 
                              _markers.removeWhere((m) => m.markerId.value == 'pickup'); 
                              _markers.add(Marker(markerId: const MarkerId('pickup'), position: finalLoc, infoWindow: const InfoWindow(title: 'مكان التحرك'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen))); 
                            } else if (_mapSelectionMode == 'destination') { 
                              _destinationLocation = finalLoc; _destinationController.text = locationText; 
                              _markers.removeWhere((m) => m.markerId.value == 'destination'); 
                              _markers.add(Marker(markerId: const MarkerId('destination'), position: finalLoc, infoWindow: const InfoWindow(title: 'وجهة الوصول'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))); 
                            } 
                            _mapSelectionMode = 'none'; 
                          }); 
                        }, 
                        child: const Text('تأكيد الموقع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 16))
                      )
                    ),
                  ],
                ),
              ),
            ),
          ),

        if (!isPickingMap)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: BoxConstraints(maxHeight: availableHeight * 0.65), 
              decoration: const BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)), 
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, -5))]
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
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
                            minLines: 1, 
                            maxLines: 4, 
                            keyboardType: TextInputType.multiline, 
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13), 
                            decoration: InputDecoration(
                              labelText: 'اكتب طلباتك بالتفصيل', 
                              prefixIcon: const Icon(Icons.shopping_basket, color: Colors.orange), 
                              filled: true, 
                              fillColor: Colors.grey.shade50, 
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
                              filled: true, 
                              fillColor: Colors.grey.shade50, 
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                            )
                          ), 
                          const SizedBox(height: 16)
                        ]
                      ),
                    
                    if (!isErrand) 
                      Column(
                        children: [
                          _buildVehicleTypeSelector(), 
                          const SizedBox(height: 16)
                        ]
                      ),
                    
                    TextField(
                      controller: _pickupController, 
                      readOnly: true, 
                      onTap: () => _openMapSelection('pickup'), 
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold), 
                      decoration: InputDecoration(
                        labelText: isErrand ? 'مكان الشراء' : 'موقع التحرك', 
                        prefixIcon: const Icon(Icons.my_location, color: Colors.green), 
                        filled: true, 
                        fillColor: Colors.grey.shade50, 
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
                        filled: true, 
                        fillColor: Colors.grey.shade50, 
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
                        filled: true, 
                        fillColor: Colors.grey.shade50, 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                      )
                    ), 
                    const SizedBox(height: 20),
                    
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: royalGreen, 
                        padding: const EdgeInsets.symmetric(vertical: 16), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ), 
                      onPressed: _isSubmittingTrip ? null : _createNewTripRequest, 
                      child: _isSubmittingTrip 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : Text(
                              isErrand ? 'إرسال الطلب للكباتن' : 'طلب الكابتن وتأكيد السعر', 
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')
                            )
                    ),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}