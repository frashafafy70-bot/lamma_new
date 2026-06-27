// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

// 🟢 تم التعديل إلى المسار المطلق الصحيح لإنهاء الإيرورات تماماً
import 'package:lamma_new/features/trips/data/services/map_service.dart';
import 'package:lamma_new/features/trips/data/services/trip_service.dart';
import 'package:lamma_new/features/trips/cubit/passenger/passenger_request_cubit.dart';

import '../../widgets/map_selection_overlay.dart';
import '../../widgets/trip_form.dart'; 

class PassengerRequestTab extends StatefulWidget {
  final TabController tabController;
  const PassengerRequestTab({super.key, required this.tabController});

  @override
  State<PassengerRequestTab> createState() => _PassengerRequestTabState();
}

class _PassengerRequestTabState extends State<PassengerRequestTab> {
  late PassengerRequestCubit _requestCubit;

  final Color primaryGreen = const Color(0xFF1B4332); 
  final Color accentGold = const Color(0xFFF3C444); 
  
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {}; 
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  bool _isLoadingMap = true;
  String _mapSelectionMode = 'none'; 
  LatLng? _tempMapCenter; 
  StreamSubscription<Position>? _positionStreamSubscription;

  bool _isMapFullscreen = false;
  bool _isSubmittingTrip = false;
  bool _isReverseGeocoding = false;

  final TextEditingController _mapSearchController = TextEditingController();
  List<dynamic> _placePredictions = [];

  String _tripCategory = 'داخلي'; 
  String _vehicleType = 'سيارة'; 
  
  final TextEditingController _pickupController = TextEditingController(text: 'موقعي الحالي');
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController(); 
  final TextEditingController _errandDetailsController = TextEditingController();
  final TextEditingController _errandEstimatedCostController = TextEditingController(); 

  final FocusNode _priceFocusNode = FocusNode();

  final String _premiumMapStyle = '''[
    {
      "featureType": "poi",
      "elementType": "labels",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "transit",
      "elementType": "labels.icon",
      "stylers": [{"visibility": "off"}]
    }
  ]''';

  @override
  void initState() {
    super.initState();
    _requestCubit = PassengerRequestCubit(
      mapService: MapService(googleApiKey: dotenv.env['GOOGLE_MAPS_API_KEY'] ?? ''),
      tripService: TripService(),
    );
    _getUserLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _pickupController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    _errandDetailsController.dispose();
    _errandEstimatedCostController.dispose();
    _mapSearchController.dispose();
    _priceFocusNode.dispose(); 
    _requestCubit.close(); 
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
      Position initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation)
      );
      _updateLocationOnMap(initialPosition, isFirstLoad: true);

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3, 
        )
      ).listen((Position livePosition) {
        _updateLocationOnMap(livePosition, isFirstLoad: false);
      });

    } catch (e) { 
      if (mounted) setState(() => _isLoadingMap = false); 
    }
  }

  void _updateLocationOnMap(Position position, {required bool isFirstLoad}) {
    if (!mounted) return;
    LatLng newLoc = LatLng(position.latitude, position.longitude);

    setState(() {
      _isLoadingMap = false;
      
      if (_pickupController.text == 'موقعي الحالي' || _pickupController.text.trim().isEmpty) {
        _pickupLocation = newLoc;
        _markers.removeWhere((m) => m.markerId.value == 'pickup');
        _markers.add(Marker(
          markerId: const MarkerId('pickup'), 
          position: newLoc, 
          infoWindow: const InfoWindow(title: 'موقعك الحالي'), 
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow) 
        ));
        
        if (_mapSelectionMode != 'none' && _tempMapCenter == null) {
          _tempMapCenter = newLoc; 
        }

        if (_mapController != null && (_mapSelectionMode == 'none' || isFirstLoad)) {
          try { 
            _mapController!.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: newLoc, zoom: 16.5, tilt: 45.0) 
            )); 
          } catch (e) { 
            debugPrint("$e"); 
          }
        }
      }
    });
  }

  void _openMapSelection(String mode) {
    FocusScope.of(context).unfocus(); 
    setState(() {
      _mapSelectionMode = mode;
      _isMapFullscreen = true; 
      LatLng fallbackLoc = const LatLng(30.0444, 31.2357);
      
      if (mode == 'pickup') {
        _tempMapCenter = _pickupLocation ?? fallbackLoc;
      } else {
        _tempMapCenter = _destinationLocation ?? _pickupLocation ?? fallbackLoc;
      }
      
      _markers.removeWhere((m) => m.markerId.value == 'temp_selection');
    });

    if (mounted && _mapController != null && _tempMapCenter != null) {
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _tempMapCenter!, zoom: 17.2, tilt: 45.0) 
      ));
      _requestCubit.getAddressFromLatLng(_tempMapCenter!);
    }
  }

  void _fitMapToMarkers() {
    if (_pickupLocation != null && _destinationLocation != null && _mapController != null) {
      LatLngBounds bounds;
      if (_pickupLocation!.latitude > _destinationLocation!.latitude) {
        bounds = LatLngBounds(southwest: _destinationLocation!, northeast: _pickupLocation!);
      } else {
        bounds = LatLngBounds(southwest: _pickupLocation!, northeast: _destinationLocation!);
      }
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 90));
    } else if (_pickupLocation != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_pickupLocation!, 16));
    } else if (_destinationLocation != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_destinationLocation!, 16));
    }
  }

  void _onMapTap(LatLng position) {
    if (_mapSelectionMode == 'none') {
      setState(() {
        _isMapFullscreen = true;
        _mapSelectionMode = 'pickup'; 
      });
    }

    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: position, zoom: 17.2, tilt: 45.0)
    ));
    
    setState(() => _tempMapCenter = position);
    _requestCubit.getAddressFromLatLng(position);
  }

  void _confirmMapSelection() {
    setState(() { 
      LatLng finalLoc = _tempMapCenter ?? const LatLng(30.0444, 31.2357); 
      String fallbackCoordinatesText = "إحداثيات: ${finalLoc.latitude.toStringAsFixed(4)}, ${finalLoc.longitude.toStringAsFixed(4)}";
      String locationText = (_mapSearchController.text.trim().isNotEmpty && _mapSearchController.text != 'جاري تحديد الموقع...' && _mapSearchController.text != 'جاري جلب العنوان...') 
          ? _mapSearchController.text.trim() 
          : fallbackCoordinatesText; 
      
      if (_mapSelectionMode == 'pickup') { 
        _pickupLocation = finalLoc; 
        _pickupController.text = locationText; 
        _markers.removeWhere((m) => m.markerId.value == 'pickup'); 
        _markers.add(Marker(markerId: const MarkerId('pickup'), position: finalLoc, infoWindow: const InfoWindow(title: 'مكان التحرك'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow))); 
      } else if (_mapSelectionMode == 'destination') { 
        _destinationLocation = finalLoc; 
        _destinationController.text = locationText; 
        _markers.removeWhere((m) => m.markerId.value == 'destination'); 
        _markers.add(Marker(markerId: const MarkerId('destination'), position: finalLoc, infoWindow: const InfoWindow(title: 'وجهة الوصول'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))); 
      } 
      _mapSelectionMode = 'none'; 
      _isMapFullscreen = false; 
    });
    _fitMapToMarkers(); 
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) FocusScope.of(context).requestFocus(_priceFocusNode);
    });
  }

  void _validateAndSubmitTrip() {
    bool isErrand = _tripCategory == 'طلبات';
    
    if (_destinationController.text.trim().isEmpty || _priceController.text.trim().isEmpty || _pickupController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('الرجاء إكمال جميع الحقول!', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: primaryGreen));
      return;
    }

    double? suggestedPrice = double.tryParse(_priceController.text.trim());
    if (suggestedPrice == null || suggestedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('الرجاء إدخال سعر صحيح (أرقام فقط)!', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: primaryGreen));
      return;
    }

    if (isErrand) {
      if (_errandDetailsController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('الرجاء إدخل تفاصيل الطلبات!', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: primaryGreen));
        return;
      }
      double? errandCost = double.tryParse(_errandEstimatedCostController.text.trim());
      if (errandCost == null || errandCost <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('الرجاء إدخال تكلفة تقريبية صحيحة (أرقام فقط)!', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: primaryGreen));
        return;
      }
    }
    
    _requestCubit.submitTripRequest(
      tripCategory: _tripCategory,
      vehicleType: _vehicleType,
      pickup: _pickupController.text.trim(),
      destination: _destinationController.text.trim(),
      price: _priceController.text.trim(),
      errandDetails: _errandDetailsController.text.trim(),
      errandCost: _errandEstimatedCostController.text.trim(),
      pickupLocation: _pickupLocation,
      destinationLocation: _destinationLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return BlocConsumer<PassengerRequestCubit, PassengerRequestState>(
      bloc: _requestCubit,
      listener: (context, state) {
        if (state is AddressLoading) {
          setState(() {
            _isReverseGeocoding = true;
            _mapSearchController.text = 'جاري تحديد الموقع...';
          });
        } else if (state is AddressLoaded) {
          setState(() {
            _isReverseGeocoding = false;
            _mapSearchController.text = state.address;
          });
        } else if (state is AddressError) {
          setState(() {
            _isReverseGeocoding = false;
            _mapSearchController.text = state.message;
          });
        } 
        else if (state is PlacesSearchLoaded) {
          setState(() {
            _placePredictions = state.predictions;
          });
        } else if (state is PlaceDetailsLoaded) {
          _onMapTap(state.location);
          setState(() {
            _mapSearchController.text = state.description;
            _placePredictions = [];
            FocusScope.of(context).unfocus();
          });
        } 
        else if (state is TripSubmitting) {
          setState(() => _isSubmittingTrip = true);
        } else if (state is TripSubmitSuccess) {
          setState(() => _isSubmittingTrip = false);
          _destinationController.clear(); 
          _priceController.clear(); 
          _errandDetailsController.clear();
          _errandEstimatedCostController.clear();
          
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تم إرسال طلبك بنجاح!', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)), backgroundColor: primaryGreen));
          widget.tabController.animateTo(2); 
        } else if (state is TripSubmitError) {
          setState(() => _isSubmittingTrip = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
        }
      },
      builder: (context, state) {
        bool isPickingMap = _mapSelectionMode != 'none'; 
        bool showMapControls = isPickingMap || _isMapFullscreen; 

        return LayoutBuilder(
          builder: (context, constraints) {
            double availableHeight = constraints.maxHeight;
            double requestedHeight = _tripCategory == 'طلبات' ? screenHeight * 0.65 : screenHeight * 0.52; 
            double formHeight = requestedHeight > availableHeight ? availableHeight : requestedHeight;

            double currentContainerHeight = keyboardHeight > 0 
                ? (formHeight + keyboardHeight > availableHeight ? availableHeight : formHeight + keyboardHeight)
                : formHeight;

            return Stack(
              children: [
                Positioned.fill(
                  child: _isLoadingMap
                      ? Center(child: CircularProgressIndicator(color: accentGold))
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _pickupLocation ?? const LatLng(30.0444, 31.2357),
                            zoom: 16.5,
                            tilt: 45.0, 
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: showMapControls,
                          zoomControlsEnabled: false, 
                          mapToolbarEnabled: false, 
                          zoomGesturesEnabled: true,
                          scrollGesturesEnabled: true,
                          rotateGesturesEnabled: true,
                          tiltGesturesEnabled: true,
                          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                          },
                          padding: EdgeInsets.only(
                            top: showMapControls ? 95.h : 20.h, 
                            bottom: showMapControls ? 160.h : formHeight + 15.h
                          ),
                          markers: isPickingMap ? {} : _markers, 
                          style: _premiumMapStyle, 
                          onMapCreated: (controller) => _mapController = controller,
                          onTap: _onMapTap,
                          onCameraMove: (position) {
                            if (_mapSelectionMode != 'none') {
                              _tempMapCenter = position.target;
                              if (!_isReverseGeocoding) {
                                setState(() {
                                  _isReverseGeocoding = true;
                                  _mapSearchController.text = 'جاري تحديد الموقع...';
                                });
                              }
                            }
                          },
                          onCameraIdle: () {
                            if (_mapSelectionMode != 'none' && _tempMapCenter != null) {
                              _requestCubit.getAddressFromLatLng(_tempMapCenter!);
                            }
                          },
                        ),
                ),

                if (isPickingMap)
                  MapSelectionOverlay(
                    mapSearchController: _mapSearchController,
                    placePredictions: _placePredictions,
                    isReverseGeocoding: _isReverseGeocoding,
                    primaryGreen: primaryGreen, 
                    accentGold: accentGold,
                    onSearch: (input) => _requestCubit.searchForPlaces(input), 
                    onSelectPlace: (placeId, desc) => _requestCubit.fetchPlaceDetails(placeId, desc), 
                    onCancel: () {
                      setState(() { 
                        _mapSelectionMode = 'none'; 
                        _isMapFullscreen = false;
                        _placePredictions = []; 
                      }); 
                      FocusScope.of(context).unfocus();
                      _fitMapToMarkers(); 
                    },
                    onConfirm: _confirmMapSelection,
                  ),

                if (_isMapFullscreen && !isPickingMap)
                  Positioned(
                    bottom: 30.h, left: 30.w, right: 30.w,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen, 
                        foregroundColor: accentGold,
                        shadowColor: Colors.black45,
                        elevation: 12,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r))
                      ),
                      onPressed: () { 
                        setState(() => _isMapFullscreen = false);
                        _fitMapToMarkers(); 
                      },
                      icon: Icon(Icons.arrow_drop_up_rounded, size: 28.sp),
                      label: Text('تكملة الحجز 🚖', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp)),
                    ),
                  ),

                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  bottom: _isMapFullscreen ? -currentContainerHeight : 0, 
                  left: 0, 
                  right: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: currentContainerHeight, 
                    padding: EdgeInsets.only(bottom: keyboardHeight), 
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)), 
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, -5))]
                    ),
                    child: TripForm(
                      tripCategory: _tripCategory,
                      vehicleType: _vehicleType,
                      isSubmittingTrip: _isSubmittingTrip,
                      errandDetailsController: _errandDetailsController,
                      errandEstimatedCostController: _errandEstimatedCostController,
                      pickupController: _pickupController,
                      destinationController: _destinationController,
                      priceController: _priceController,
                      priceFocusNode: _priceFocusNode,
                      primaryGreen: primaryGreen,
                      accentGold: accentGold,
                      onCategoryChanged: (category) {
                        setState(() { 
                          _tripCategory = category; 
                          _mapSelectionMode = 'none'; 
                        });
                        FocusScope.of(context).unfocus();
                      },
                      onVehicleChanged: (vehicle) => setState(() => _vehicleType = vehicle),
                      onOpenMapSelection: _openMapSelection,
                      onSubmit: _validateAndSubmitTrip, 
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}