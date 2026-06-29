// ignore_for_file: use_build_context_synchronously

import 'dart:io'; 
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math; 

import 'package:lamma_new/features/trips/data/services/map_service.dart';
import 'package:lamma_new/features/trips/data/services/trip_service.dart';
import 'package:lamma_new/features/trips/cubit/passenger/passenger_request_cubit.dart';

import '../../widgets/map_selection_overlay.dart';
import '../../widgets/trip_form.dart'; 

import 'package:lamma_new/core/constants/app_constants.dart'; 
import 'package:lamma_new/core/theme/app_colors.dart';

class PassengerRequestTab extends StatefulWidget {
  final TabController tabController;
  const PassengerRequestTab({super.key, required this.tabController});

  @override
  State<PassengerRequestTab> createState() => _PassengerRequestTabState();
}

class _PassengerRequestTabState extends State<PassengerRequestTab> {
  late PassengerRequestCubit _requestCubit;

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
  File? _orderAudioFile;

  @override
  void initState() {
    super.initState();
    _requestCubit = PassengerRequestCubit(
      // 👈 التعديل هنا: شلنا الـ googleApiKey لأن الـ MapService بقى متظبط في الـ main
      mapService: MapService(), 
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
    if (!serviceEnabled) { 
      if (mounted) setState(() => _isLoadingMap = false); 
      _showLocationError('خدمة الموقع مقفولة، يرجى تفعيلها من إعدادات الهاتف.');
      return; 
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) { 
        if (mounted) setState(() => _isLoadingMap = false); 
        _showLocationError('تم رفض صلاحية الموقع.');
        return; 
      }
    }
    
    if (permission == LocationPermission.deniedForever) { 
      if (mounted) setState(() => _isLoadingMap = false); 
      _showLocationPermissionDialog(); 
      return; 
    }

    try {
      Position initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation)
      );
      if (mounted) _updateLocationOnMap(initialPosition, isFirstLoad: true);

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3, 
        )
      ).listen((Position livePosition) {
        if (mounted) _updateLocationOnMap(livePosition, isFirstLoad: false);
      });

    } catch (e) { 
      if (mounted) setState(() => _isLoadingMap = false); 
      _showLocationError('حدث خطأ أثناء جلب الموقع.');
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold)), 
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  void _showLocationPermissionDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.location_off_rounded, color: AppColors.error, size: 24.sp),
            SizedBox(width: 8.w),
            Text('صلاحية الموقع', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18.sp)),
          ],
        ),
        content: Text('لقد قمت برفض صلاحية الموقع بشكل دائم. لكي تتمكن من استخدام التطبيق بشكل صحيح، يرجى تفعيل الصلاحية من إعدادات الهاتف.', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 14.sp)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.royalGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))
            ),
            onPressed: () {
              Geolocator.openAppSettings();
              Navigator.pop(context);
            },
            child: Text('فتح الإعدادات', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
          ),
        ],
      ),
    );
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
              CameraPosition(target: newLoc, zoom: AppConstants.defaultMapZoom, tilt: AppConstants.mapTilt) 
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
      
      if (mode == 'pickup') {
        _tempMapCenter = _pickupLocation ?? AppConstants.fallbackLocation;
      } else {
        _tempMapCenter = _destinationLocation ?? _pickupLocation ?? AppConstants.fallbackLocation;
      }
      
      _markers.removeWhere((m) => m.markerId.value == 'temp_selection');
    });

    if (mounted && _mapController != null && _tempMapCenter != null) {
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _tempMapCenter!, zoom: AppConstants.selectionMapZoom, tilt: AppConstants.mapTilt) 
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
      CameraPosition(target: position, zoom: AppConstants.selectionMapZoom, tilt: AppConstants.mapTilt)
    ));
    
    setState(() => _tempMapCenter = position);
    _requestCubit.getAddressFromLatLng(position);
  }

  void _confirmMapSelection() {
    setState(() { 
      LatLng finalLoc = _tempMapCenter ?? AppConstants.fallbackLocation; 
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
      _showLocationError('الرجاء إكمال جميع الحقول الأساسية!');
      return;
    }

    double? suggestedPrice = double.tryParse(_priceController.text.trim());
    if (suggestedPrice == null || suggestedPrice <= 0) {
      _showLocationError('الرجاء إدخال سعر صحيح (أرقام فقط)!');
      return;
    }

    if (isErrand) {
      if (_errandDetailsController.text.trim().isEmpty && _orderAudioFile == null) {
        _showLocationError('الرجاء كتابة تفاصيل الطلبات أو تسجيلها صوتياً!');
        return;
      }
      double? errandCost = double.tryParse(_errandEstimatedCostController.text.trim());
      if (errandCost == null || errandCost <= 0) {
        _showLocationError('الرجاء إدخال تكلفة تقريبية صحيحة (أرقام فقط)!');
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
      orderAudioFile: _orderAudioFile, 
    );
  }

  Widget _buildGoogleMap(bool showMapControls, double formHeight) {
    if (_isLoadingMap) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentGold));
    }
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _pickupLocation ?? AppConstants.fallbackLocation,
        zoom: AppConstants.defaultMapZoom,
        tilt: AppConstants.mapTilt, 
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
      markers: _mapSelectionMode != 'none' ? {} : _markers, 
      style: AppConstants.premiumMapStyle, 
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
          setState(() {
            _isSubmittingTrip = false;
            _orderAudioFile = null; 
          });
          _destinationController.clear(); 
          _priceController.clear(); 
          _errandDetailsController.clear();
          _errandEstimatedCostController.clear();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إرسال طلبك بنجاح! 🚀', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)), 
              backgroundColor: AppColors.royalGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            )
          );
          
          widget.tabController.animateTo(2); 

        } else if (state is TripSubmitError) {
          setState(() => _isSubmittingTrip = false);
          _showLocationError(state.message);
        }
      },
      builder: (context, state) {
        bool isPickingMap = _mapSelectionMode != 'none'; 
        bool showMapControls = isPickingMap || _isMapFullscreen; 

        return LayoutBuilder(
          builder: (context, constraints) {
            double availableHeight = constraints.maxHeight;
            double requestedHeight = _tripCategory == 'طلبات' ? screenHeight * 0.65 : screenHeight * 0.52; 
            
            double visibleSpace = availableHeight - keyboardHeight;
            double actualContainerHeight = math.max(0.0, math.min(requestedHeight, visibleSpace));

            return Stack(
              children: [
                Positioned.fill(
                  child: _buildGoogleMap(showMapControls, requestedHeight),
                ),

                if (isPickingMap)
                  MapSelectionOverlay(
                    mapSearchController: _mapSearchController,
                    placePredictions: _placePredictions,
                    isReverseGeocoding: _isReverseGeocoding,
                    primaryGreen: AppColors.royalGreen, 
                    accentGold: AppColors.accentGold,
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
                        backgroundColor: AppColors.royalGreen, 
                        foregroundColor: AppColors.accentGold,
                        shadowColor: AppColors.royalGreen.withValues(alpha: 0.4),
                        elevation: 10,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r))
                      ),
                      onPressed: () { 
                        setState(() => _isMapFullscreen = false);
                        _fitMapToMarkers(); 
                      },
                      icon: Icon(Icons.check_circle_rounded, size: 24.sp),
                      label: Text('تأكيد الموقع 🚖', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp)),
                    ),
                  ),

                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  bottom: _isMapFullscreen ? -actualContainerHeight : keyboardHeight, 
                  left: 0, 
                  right: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    height: actualContainerHeight, 
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)), 
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -5))
                      ]
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
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
                        primaryGreen: AppColors.royalGreen,
                        accentGold: AppColors.accentGold,
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
                        onAudioRecorded: (File? audio) {
                          setState(() => _orderAudioFile = audio);
                        },
                      ),
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