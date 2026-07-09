// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io'; 
import 'package:http/http.dart' as http; 

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart'; 
import 'dart:math' as math; 

import 'package:lamma_new/features/trips/data/repositories/map_repository_impl.dart';
import 'package:lamma_new/features/trips/data/repositories/trip_repository_impl.dart';

import 'package:lamma_new/features/trips/cubit/passenger/passenger_request_cubit.dart';
import 'package:lamma_new/features/trips/presentation/widgets/map_selection_overlay.dart';
import 'package:lamma_new/features/trips/presentation/widgets/lamma_google_map.dart'; 

import 'package:lamma_new/core/constants/app_constants.dart'; 
import 'package:lamma_new/core/theme/app_colors.dart';

import 'package:lamma_new/features/trips/domain/entities/place_search_entity.dart';

// 🟢 استدعاء ملفات الفورم المنفصلة
import 'package:lamma_new/features/trips/presentation/widgets/service_form/buy_orders_service_form.dart';
import 'package:lamma_new/features/trips/presentation/widgets/service_form/ride_service_form.dart';
import 'package:lamma_new/features/trips/presentation/widgets/service_form/travel_service_form.dart';

class PassengerRequestTab extends StatefulWidget {
  final TabController tabController;
  const PassengerRequestTab({super.key, required this.tabController});

  @override
  State<PassengerRequestTab> createState() => _PassengerRequestTabState();
}

class _PassengerRequestTabState extends State<PassengerRequestTab> {
  late PassengerRequestCubit _requestCubit;
  
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _errandDetailsController = TextEditingController();
  final TextEditingController _errandEstimatedCostController = TextEditingController();
  final FocusNode _priceFocusNode = FocusNode();
  
  String _tripCategory = 'داخلي';
  String _vehicleType = 'سيارة';
  File? _orderAudioFile;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {}; 
  final Set<Polyline> _polylines = {}; 

  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  
  bool _isLoadingMap = true;
  String _mapSelectionMode = 'none'; 
  LatLng? _tempMapCenter; 

  bool _isMapFullscreen = false;
  bool _isReverseGeocoding = false;

  final TextEditingController _mapSearchController = TextEditingController();
  List<PlaceSearchEntity> _placePredictions = []; 

  final double _closeZoom = 16.5; 

  static const Color _lighterNavy = Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _requestCubit = PassengerRequestCubit(
      mapRepository: MapRepositoryImpl(), 
      tripRepository: TripRepositoryImpl(),
    );
    _requestCubit.getUserLocation();
  }

  @override
  void dispose() {
    _mapSearchController.dispose();
    _requestCubit.close(); 
    _mapController?.dispose();
    
    _pickupController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    _errandDetailsController.dispose();
    _errandEstimatedCostController.dispose();
    _priceFocusNode.dispose();

    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold)), 
        backgroundColor: isError ? AppColors.error : AppColors.royalGreen,
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
        content: Text('لقد قمت برفض صلاحية الموقع بشكل دائم. لكي تتمكن من استخدام التطبيق، يرجى التفعيل من الإعدادات.', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 14.sp))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
            onPressed: () { Geolocator.openAppSettings(); Navigator.pop(context); },
            child: Text('فتح الإعدادات', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  Future<List<LatLng>> _getRouteCoordinates(LatLng origin, LatLng destination) async {
    String apiKey = AppConstants.googleMapsApiKey; 
    String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
          return _decodePolyline(encodedPolyline);
        }
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
    }
    return [];
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length, lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do { b = encoded.codeUnitAt(index++) - 63; result |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1)); lat += dlat;
      shift = 0; result = 0;
      do { b = encoded.codeUnitAt(index++) - 63; result |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1)); lng += dlng;
      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> _updateRoutePolyline() async {
    _polylines.clear();
    if (_pickupLocation != null && _destinationLocation != null) {
      setState(() {
        _polylines.add(Polyline(
          polylineId: const PolylineId('trip_route_temp'), points: [_pickupLocation!, _destinationLocation!],
          color: AppColors.royalGreen.withValues(alpha: 0.5), width: 4, patterns: [PatternItem.dash(15), PatternItem.gap(10)], endCap: Cap.roundCap, startCap: Cap.roundCap,
        ));
      });
      List<LatLng> routePoints = await _getRouteCoordinates(_pickupLocation!, _destinationLocation!);
      if (routePoints.isNotEmpty && mounted) {
        setState(() {
          _polylines.removeWhere((p) => p.polylineId.value == 'trip_route_temp'); 
          _polylines.add(Polyline(
            polylineId: const PolylineId('trip_route'), points: routePoints, color: AppColors.royalGreen, width: 5, patterns: [PatternItem.dash(15), PatternItem.gap(10)], endCap: Cap.roundCap, startCap: Cap.roundCap,
          ));
        });
        _fitMapToMarkers();
      }
    }
  }

  void _updateLocationOnMap(LatLng newLoc) {
    if (!mounted) return;
    setState(() {
      _isLoadingMap = false;
      if (_pickupLocation == null) {
        _pickupLocation = newLoc;
        _markers.removeWhere((m) => m.markerId.value == 'pickup');
        _markers.add(Marker(markerId: const MarkerId('pickup'), position: newLoc, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), infoWindow: const InfoWindow(title: 'نقطة الانطلاق')));
        if (_mapSelectionMode != 'none' && _tempMapCenter == null) { _tempMapCenter = newLoc; }
        if (_mapController != null && _mapSelectionMode == 'none') { _mapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: newLoc, zoom: _closeZoom))); }
      }
    });
  }

  void _openMapSelection(String mode) {
    FocusScope.of(context).unfocus(); 
    setState(() {
      _mapSelectionMode = mode; _isMapFullscreen = true; 
      _tempMapCenter = mode == 'pickup' ? (_pickupLocation ?? const LatLng(AppConstants.fallbackLatitude, AppConstants.fallbackLongitude)) : (_destinationLocation ?? _pickupLocation ?? const LatLng(AppConstants.fallbackLatitude, AppConstants.fallbackLongitude));
    });
    if (mounted && _mapController != null && _tempMapCenter != null) {
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: _tempMapCenter!, zoom: _closeZoom)));
      _requestCubit.getAddressFromLatLng(_tempMapCenter!);
    }
  }
  
  void _onMapTap(LatLng position) {
    if (_mapSelectionMode == 'none') setState(() { _isMapFullscreen = true; _mapSelectionMode = 'pickup'; });
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: position, zoom: _closeZoom)));
    setState(() => _tempMapCenter = position);
    _requestCubit.getAddressFromLatLng(position);
  }

  void _fitMapToMarkers() {
    if (_pickupLocation != null && _destinationLocation != null && _mapController != null) {
      LatLngBounds bounds = _pickupLocation!.latitude > _destinationLocation!.latitude 
          ? LatLngBounds(southwest: _destinationLocation!, northeast: _pickupLocation!) 
          : LatLngBounds(southwest: _pickupLocation!, northeast: _destinationLocation!);
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } else if (_pickupLocation != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_pickupLocation!, _closeZoom));
    } else if (_destinationLocation != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_destinationLocation!, _closeZoom));
    }
  }

  void _confirmMapSelection() {
    setState(() { 
      LatLng finalLoc = _tempMapCenter ?? const LatLng(AppConstants.fallbackLatitude, AppConstants.fallbackLongitude); 
      String locationText = (_mapSearchController.text.trim().isNotEmpty && _mapSearchController.text != 'جاري تحديد الموقع...' && _mapSearchController.text != 'جاري جلب العنوان...') 
          ? _mapSearchController.text.trim() : "إحداثيات: ${finalLoc.latitude.toStringAsFixed(4)}, ${finalLoc.longitude.toStringAsFixed(4)}"; 
      
      if (_mapSelectionMode == 'pickup') { 
        _pickupLocation = finalLoc; 
        _markers.removeWhere((m) => m.markerId.value == 'pickup'); 
        _markers.add(Marker(markerId: const MarkerId('pickup'), position: finalLoc, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), infoWindow: const InfoWindow(title: 'نقطة الانطلاق'))); 
        _pickupController.text = locationText;
      } else if (_mapSelectionMode == 'destination') { 
        _destinationLocation = finalLoc; 
        _markers.removeWhere((m) => m.markerId.value == 'destination'); 
        _markers.add(Marker(markerId: const MarkerId('destination'), position: finalLoc, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), infoWindow: const InfoWindow(title: 'وجهة الوصول'))); 
        _destinationController.text = locationText;
      } 
      _updateRoutePolyline(); _mapSelectionMode = 'none'; _isMapFullscreen = false; 
    });
    Future.delayed(const Duration(milliseconds: 300), () => _fitMapToMarkers()); 
  }

  void _showLoadingDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)), elevation: 0, backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20.w), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.royalGreen), SizedBox(height: 20.h),
                  Text('جاري إرسال طلبك...', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _submitTrip() {
    FocusScope.of(context).unfocus();

    if (_pickupLocation == null) {
      _showSnackBar('الرجاء تحديد نقطة الانطلاق أولاً');
      return;
    }

    if (_tripCategory == 'داخلي' || _tripCategory == 'سفر') {
      if (_destinationLocation == null) {
        _showSnackBar('الرجاء تحديد مكان الوصول');
        return;
      }
    } else if (_tripCategory == 'طلبات') {
      if (_errandDetailsController.text.trim().isEmpty && _orderAudioFile == null) {
        _showSnackBar('الرجاء كتابة أو تسجيل تفاصيل الطلبات');
        return;
      }
    }

    if (_priceController.text.trim().isEmpty) {
      _showSnackBar('الرجاء إدخال السعر المقترح');
      return;
    }

    double? parsedPrice = double.tryParse(_priceController.text.trim());
    if (parsedPrice == null || parsedPrice <= 0) {
      _showSnackBar('الرجاء إدخال سعر صحيح (أرقام فقط)');
      return;
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

  Widget _buildSelectedServiceForm(bool isSubmitting) {
    switch (_tripCategory) {
      case 'طلبات':
        return BuyOrdersServiceForm(
          isSubmittingTrip: isSubmitting,
          errandDetailsController: _errandDetailsController,
          errandEstimatedCostController: _errandEstimatedCostController,
          pickupController: _pickupController,
          destinationController: _destinationController,
          priceController: _priceController,
          priceFocusNode: _priceFocusNode,
          primaryGreen: AppColors.royalGreen,
          accentGold: AppColors.accentGold,
          onOpenMapSelection: _openMapSelection,
          onAudioRecorded: (file) => setState(() => _orderAudioFile = file),
          onSubmit: _submitTrip,
        );
      case 'داخلي':
        return RideServiceForm(
          vehicleType: _vehicleType,
          onVehicleChanged: (veh) => setState(() => _vehicleType = veh),
          isSubmittingTrip: isSubmitting,
          pickupController: _pickupController,
          destinationController: _destinationController,
          priceController: _priceController,
          priceFocusNode: _priceFocusNode,
          primaryGreen: AppColors.royalGreen,
          accentGold: AppColors.accentGold,
          onOpenMapSelection: _openMapSelection,
          onSubmit: _submitTrip,
        );
      case 'سفر':
        return TravelServiceForm(
          vehicleType: _vehicleType, // 🟢 تم إضافة المتغير هنا لحل الخطأ
          onVehicleChanged: (veh) => setState(() => _vehicleType = veh), // 🟢 وتم إضافة دالة التحديث
          isSubmittingTrip: isSubmitting,
          pickupController: _pickupController,
          destinationController: _destinationController,
          priceController: _priceController,
          priceFocusNode: _priceFocusNode,
          primaryGreen: AppColors.royalGreen,
          accentGold: AppColors.accentGold,
          onOpenMapSelection: _openMapSelection,
          onSubmit: _submitTrip,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildCategoryChip(String logicTitle, String displayTitle, IconData icon) {
    bool isSelected = _tripCategory == logicTitle;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tripCategory = logicTitle;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentGold.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(25.r),
            border: Border.all(color: isSelected ? AppColors.accentGold : Colors.transparent, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18.sp, color: isSelected ? _lighterNavy : Colors.grey.shade400),
              SizedBox(width: 8.w),
              Text(
                displayTitle,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? _lighterNavy : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return BlocProvider.value(
      value: _requestCubit, 
      child: BlocConsumer<PassengerRequestCubit, PassengerRequestState>(
        listener: (context, state) {
          if (state is LocationLoading) {
            setState(() => _isLoadingMap = true);
          } else if (state is LocationLoaded) {
            _updateLocationOnMap(state.position);
          } else if (state is LocationError) {
            setState(() => _isLoadingMap = false); _showSnackBar(state.message);
          } else if (state is LocationPermissionDenied) {
            setState(() => _isLoadingMap = false); _showLocationPermissionDialog();
          } else if (state is AddressLoading) {
            setState(() { _isReverseGeocoding = true; _mapSearchController.text = 'جاري تحديد الموقع...'; });
          } else if (state is AddressLoaded) {
            setState(() { _isReverseGeocoding = false; _mapSearchController.text = state.address; });
          } else if (state is AddressError) {
            setState(() { _isReverseGeocoding = false; _mapSearchController.text = state.message; });
          } else if (state is PlacesSearchLoaded) {
            setState(() => _placePredictions = List<PlaceSearchEntity>.from(state.predictions));
          } else if (state is PlaceDetailsLoaded) {
            setState(() { _tempMapCenter = state.location; _mapSearchController.text = state.description; _placePredictions = []; });
            _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: state.location, zoom: _closeZoom)));
            FocusScope.of(context).unfocus();
          } else if (state is TripSubmitting) {
            _showLoadingDialog(); 
          } else if (state is TripSubmitSuccess) {
            Navigator.of(context, rootNavigator: true).pop(); 
            _destinationController.clear(); _priceController.clear(); _errandDetailsController.clear(); _errandEstimatedCostController.clear(); _orderAudioFile = null;
            _showSnackBar('تم إرسال طلبك بنجاح! 🚀', isError: false);
            widget.tabController.animateTo(2); 
          } else if (state is TripSubmitError) {
            Navigator.of(context, rootNavigator: true).pop(); _showSnackBar(state.message);
          }
        },
        builder: (context, state) {
          bool isPickingMap = _mapSelectionMode != 'none'; 

          return LayoutBuilder(
            builder: (context, constraints) {
              double availableHeight = constraints.maxHeight;
              double requestedHeight = screenHeight * 0.55; 
              double visibleSpace = availableHeight - keyboardHeight;
              double actualContainerHeight = math.max(0.0, math.min(requestedHeight, visibleSpace));

              return Stack(
                children: [
                  Positioned.fill(
                    child: _isLoadingMap 
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
                      : LammaGoogleMap(
                          initialCameraPosition: CameraPosition(target: _pickupLocation ?? const LatLng(AppConstants.fallbackLatitude, AppConstants.fallbackLongitude), zoom: _closeZoom),
                          markers: _markers, polylines: _polylines, showCenterPin: isPickingMap,
                          mapPadding: EdgeInsets.only(bottom: _isMapFullscreen ? 90.h : actualContainerHeight + 10.h, top: isPickingMap ? 100.h : 0),
                          onTap: _onMapTap, onMapCreated: (controller) => _mapController = controller,
                          onCameraMove: (position) {
                            if (isPickingMap) {
                              _tempMapCenter = position.target;
                              if (!_isReverseGeocoding) { setState(() { _isReverseGeocoding = true; _mapSearchController.text = 'جاري تحديد الموقع...'; }); }
                            }
                          },
                          onCameraIdle: () {
                            if (isPickingMap && _tempMapCenter != null) _requestCubit.getAddressFromLatLng(_tempMapCenter!);
                          },
                        ),
                  ),

                  if (isPickingMap)
                    MapSelectionOverlay(
                      mapSearchController: _mapSearchController, placePredictions: _placePredictions.cast<dynamic>(), 
                      isReverseGeocoding: _isReverseGeocoding, primaryGreen: AppColors.royalGreen, accentGold: AppColors.accentGold,
                      onSearch: (input) => _requestCubit.searchForPlaces(input), onSelectPlace: (placeId, desc) => _requestCubit.fetchPlaceDetails(placeId, desc), 
                      onCancel: () {
                        setState(() { _mapSelectionMode = 'none'; _isMapFullscreen = false; _placePredictions = []; }); FocusScope.of(context).unfocus(); _fitMapToMarkers(); 
                      },
                      onConfirm: _confirmMapSelection,
                    ),

                  if (_isMapFullscreen && !isPickingMap)
                    Positioned(
                      bottom: 30.h, left: 30.w, right: 30.w,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalGreen, foregroundColor: AppColors.accentGold, shadowColor: AppColors.royalGreen.withValues(alpha: 0.4), elevation: 10, padding: EdgeInsets.symmetric(vertical: 14.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r))
                        ),
                        onPressed: () { setState(() => _isMapFullscreen = false); _fitMapToMarkers(); }, icon: Icon(Icons.check_circle_rounded, size: 24.sp), label: Text('تأكيد الموقع 🚖', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp)),
                      ),
                    ),

                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    bottom: _isMapFullscreen ? -actualContainerHeight : keyboardHeight, 
                    left: 0, right: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      height: actualContainerHeight, 
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)), 
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -5))]
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 20.h, left: 20.w, right: 20.w, bottom: 10.h),
                              child: Container(
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(30.r),
                                  border: Border.all(color: _lighterNavy.withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  children: [
                                    _buildCategoryChip('داخلي', 'توصيل', Icons.local_taxi_rounded),
                                    _buildCategoryChip('طلبات', 'شراء طلبات', Icons.shopping_bag_rounded),
                                    _buildCategoryChip('سفر', 'سفر', Icons.emoji_transportation_rounded),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: 20.w, 
                                    right: 20.w, 
                                    bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 20.h : 20.h
                                  ),
                                  child: _buildSelectedServiceForm(state is TripSubmitting),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}