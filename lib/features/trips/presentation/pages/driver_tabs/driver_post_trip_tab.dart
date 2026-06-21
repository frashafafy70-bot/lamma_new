// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DriverPostTripTab extends StatefulWidget {
  final TabController tabController;
  const DriverPostTripTab({super.key, required this.tabController});

  @override
  State<DriverPostTripTab> createState() => _DriverPostTripTabState();
}

class _DriverPostTripTabState extends State<DriverPostTripTab> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color royalGreen = const Color(0xFF1B4332);

  final TextEditingController _postFromCtrl = TextEditingController();
  final TextEditingController _postToCtrl = TextEditingController();
  final TextEditingController _postTimeCtrl = TextEditingController();
  final TextEditingController _postVehicleTypeCtrl = TextEditingController();
  final TextEditingController _postSeatsCtrl = TextEditingController();
  final TextEditingController _postPriceCtrl = TextEditingController();

  LatLng? _fromLatLng;
  LatLng? _toLatLng;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _postFromCtrl.dispose();
    _postToCtrl.dispose();
    _postTimeCtrl.dispose();
    _postVehicleTypeCtrl.dispose(); 
    _postSeatsCtrl.dispose();
    _postPriceCtrl.dispose();
    super.dispose();
  }

  // 💡 فتح الخريطة واستقبال الاسم والإحداثيات
  Future<void> _openMapPicker(bool isFrom) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const _LocationPickerScreen(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        if (isFrom) {
          _postFromCtrl.text = result['address'];
          _fromLatLng = result['latLng'];
        } else {
          _postToCtrl.text = result['address'];
          _toLatLng = result['latLng'];
        }
      });
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: royalGreen, onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: royalGreen, onPrimary: Colors.white, onSurface: Colors.black),
          ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          String amPm = pickedTime.period == DayPeriod.am ? 'ص' : 'م';
          int hour12 = pickedTime.hourOfPeriod == 0 ? 12 : pickedTime.hourOfPeriod;
          String minute = pickedTime.minute.toString().padLeft(2, '0');
          _postTimeCtrl.text = "${pickedDate.year}/${pickedDate.month}/${pickedDate.day} - $hour12:$minute $amPm";
        });
      }
    }
  }

  Future<void> _postNewTrip() async {
    if (_postFromCtrl.text.isEmpty || _postToCtrl.text.isEmpty || _postTimeCtrl.text.isEmpty || _postPriceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إكمال جميع الحقول!', style: TextStyle(fontFamily: 'Cairo')), 
          backgroundColor: Colors.red
        )
      );
      return;
    }

    if (_fromLatLng == null || _toLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تحديد المواقع من الخريطة بدقة!', style: TextStyle(fontFamily: 'Cairo')), 
          backgroundColor: Colors.orange
        )
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 🚀 رفع البيانات بنفس التكوين القديم للحفاظ على سلامة قاعدة البيانات القديمة بنسبة 100%
      await FirebaseFirestore.instance.collection('trips').add({
        'isDriverPost': true, 
        'driverId': currentUserId, 
        'driverName': 'كابتن', 
        'fromCity': _postFromCtrl.text.trim(), 
        'toCity': _postToCtrl.text.trim(), 
        'fromLocation': GeoPoint(_fromLatLng!.latitude, _fromLatLng!.longitude),
        'toLocation': GeoPoint(_toLatLng!.latitude, _toLatLng!.longitude),
        'time': _postTimeCtrl.text.trim(), 
        'vehicleType': _postVehicleTypeCtrl.text.trim().isNotEmpty ? _postVehicleTypeCtrl.text.trim() : 'سيارة',
        'availableSeats': _postSeatsCtrl.text.trim(), 
        'price': _postPriceCtrl.text.trim(), 
        'status': 'available', 
        'createdAt': FieldValue.serverTimestamp()
      });
      
      if (mounted) { 
        _postFromCtrl.clear(); 
        _postToCtrl.clear();
        _postTimeCtrl.clear();
        _postVehicleTypeCtrl.clear(); 
        _postSeatsCtrl.clear();
        _postPriceCtrl.clear();
        _fromLatLng = null;
        _toLatLng = null;
        widget.tabController.animateTo(2); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء حفظ الرحلة، يرجى المحاولة لاحقاً', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              
              TextField(
                controller: _postFromCtrl, 
                readOnly: true, 
                onTap: () => _openMapPicker(true),
                decoration: InputDecoration(
                  labelText: 'مدينة/مكان التحرك', 
                  prefixIcon: const Icon(Icons.location_on, color: Colors.green), 
                  suffixIcon: const Icon(Icons.map_rounded, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                )
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _postToCtrl, 
                readOnly: true,
                onTap: () => _openMapPicker(false),
                decoration: InputDecoration(
                  labelText: 'مدينة/مكان الوصول', 
                  prefixIcon: const Icon(Icons.flag, color: Colors.red), 
                  suffixIcon: const Icon(Icons.map_rounded, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                )
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _postTimeCtrl, 
                readOnly: true, 
                onTap: () => _selectDateTime(context),
                decoration: InputDecoration(
                  labelText: 'موعد وتاريخ التحرك', 
                  prefixIcon: const Icon(Icons.calendar_month), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                )
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _postVehicleTypeCtrl, 
                decoration: InputDecoration(
                  labelText: 'نوع العربية (مثال: ملاكي، ميكروباص 14)', 
                  prefixIcon: const Icon(Icons.directions_car_rounded), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                )
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _postSeatsCtrl, 
                      keyboardType: TextInputType.number, 
                      decoration: InputDecoration(
                        labelText: 'المقاعد المتاحة', 
                        prefixIcon: const Icon(Icons.airline_seat_recline_normal), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      )
                    )
                  ), 
                  const SizedBox(width: 12), 
                  Expanded(
                    child: TextField(
                      controller: _postPriceCtrl, 
                      keyboardType: TextInputType.number, 
                      decoration: InputDecoration(
                        labelText: 'سعر المقعد (ج)', 
                        prefixIcon: const Icon(Icons.payments_outlined), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      )
                    )
                  )
                ]
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: royalGreen, 
                  padding: const EdgeInsets.symmetric(vertical: 16), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ), 
                onPressed: _isSubmitting ? null : _postNewTrip, 
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('نشر الرحلة للعملاء', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))
              )
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 🗺️ كلاس الخريطة المطور كلياً مع الجيوديكينج العكسي الذكي
// =========================================================================
class _LocationPickerScreen extends StatefulWidget {
  const _LocationPickerScreen();

  @override
  State<_LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<_LocationPickerScreen> {
  final Color royalGreen = const Color(0xFF1B4332);
  final TextEditingController _searchController = TextEditingController();
  final String googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? ''; 
  
  GoogleMapController? _mapController;
  LatLng _currentCenter = const LatLng(30.0444, 31.2357); 
  bool _isLoading = true;
  bool _isReverseGeocoding = false; // 💡 تتبع حالة جلب العنوان العكسي
  bool _shouldReverseGeocode = true; // 💡 لمنع استبدال العنوان الدقيق عند الاختيار من قائمة البحث
  List<dynamic> _placePredictions = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_mapController != null) _mapController!.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { setState(() => _isLoading = false); return; }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) { setState(() => _isLoading = false); return; }
    }
    
    try {
      Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation));
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_currentCenter, 16.5));
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // 💡 الجيوديكينج العكسي: تحويل الإحداثيات لعنوان مقروء
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
          setState(() {
            _searchController.text = formattedAddress;
          });
        }
      }
    } catch (e) {
      debugPrint("خطأ في الجيوديكينج العكسي: $e");
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
    } catch (e) { debugPrint("$e"); }
  }

  void _getPlaceDetailsAndMove(String placeId, String description) async {
    String url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleApiKey";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var location = json.decode(response.body)['result']['geometry']['location'];
        LatLng latLng = LatLng(location['lat'], location['lng']);
        
        // 💡 نوقف الجيوديكينج العكسي مؤقتاً لكي لا يتم دهس الاسم الدقيق المختار من البحث بأسماء شوارع فرعية
        _shouldReverseGeocode = false; 
        
        if (_mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 18.0));
        }
        
        setState(() { 
          _searchController.text = description; 
          _placePredictions = []; 
          _currentCenter = latLng; 
          FocusScope.of(context).unfocus(); 
        });
      }
    } catch (e) { debugPrint("$e"); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator(color: royalGreen))
              : GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(target: _currentCenter, zoom: 16.5),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) => _mapController = controller,
                  onCameraMove: (position) {
                    _currentCenter = position.target;
                    // 💡 إذا حرك الخريطة بنفسه، نعيد تفعيل ميزة التحديث التلقائي للعنوان
                    _shouldReverseGeocode = true; 
                  },
                  onCameraIdle: () {
                    // 💡 بمجرد وقوف الخريطة وثباتها، نبدأ جلب العنوان فوراً إن كان مسموحاً
                    if (_shouldReverseGeocode && !_isLoading) {
                      _performReverseGeocoding(_currentCenter);
                    }
                  },
                ),
          
          if (!_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40.0),
                child: Icon(Icons.location_on, size: 50, color: Colors.black87),
              ),
            ),

          // شريط البحث المطور
          Positioned(
            top: 50, right: 16, left: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    FloatingActionButton(
                      mini: true, backgroundColor: Colors.white, foregroundColor: royalGreen, 
                      onPressed: () => Navigator.pop(context), 
                      child: const Icon(Icons.arrow_back)
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _searchPlaces,
                          decoration: InputDecoration(
                            hintText: 'ابحث عن مدينة أو منطقة...',
                            prefixIcon: const Icon(Icons.search),
                            // 💡 تغيير الأيقونة التعبيرية بشكل تفاعلي أثناء جلب العنوان بالخلفية
                            suffixIcon: _isReverseGeocoding 
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.clear), 
                                    onPressed: () { 
                                      _searchController.clear(); 
                                      setState(() => _placePredictions = []); 
                                    }
                                  ),
                            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_placePredictions.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.only(top: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true, padding: EdgeInsets.zero, itemCount: _placePredictions.length,
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

          Positioned(
            bottom: 20, right: 20, left: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: royalGreen, padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 8
              ),
              onPressed: () {
                String address = _searchController.text.isNotEmpty ? _searchController.text : "موقع محدد من الخريطة";
                Navigator.pop(context, {'address': address, 'latLng': _currentCenter});
              },
              child: const Text('تأكيد موقع النقطة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            ),
          )
        ],
      ),
    );
  }
}