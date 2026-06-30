// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart'; 
import 'dart:math' as math; 

import 'package:lamma_new/features/trips/data/services/map_service.dart';
import 'package:lamma_new/features/trips/data/services/trip_service.dart';
import 'package:lamma_new/features/trips/cubit/passenger/passenger_request_cubit.dart';

import '../../widgets/map_selection_overlay.dart';
import '../../widgets/trip_form.dart'; 
import '../../widgets/lamma_google_map.dart'; 

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

  // 🟢 مفتاح الفورم عشان نبعتله العناوين بعد اختيارها من الخريطة
  final GlobalKey<TripFormState> _formKey = GlobalKey<TripFormState>();

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {}; 
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  
  bool _isLoadingMap = true;
  String _mapSelectionMode = 'none'; 
  LatLng? _tempMapCenter; 

  bool _isMapFullscreen = false;
  bool _isReverseGeocoding = false;

  final TextEditingController _mapSearchController = TextEditingController();
  List<dynamic> _placePredictions = [];

  @override
  void initState() {
    super.initState();
    _requestCubit = PassengerRequestCubit(
      mapService: MapService(), 
      tripService: TripService(),
    );
    // جلب موقع العميل أول ما الشاشة تفتح
    _requestCubit.getUserLocation();
  }

  @override
  void dispose() {
    _mapSearchController.dispose();
    _requestCubit.close(); 
    _mapController?.dispose();
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

  void _updateLocationOnMap(LatLng newLoc) {
    if (!mounted) return;
    setState(() {
      _isLoadingMap = false;
      
      // بنحط الدبوس فقط لو مفيش مكان متسجل قبل كده
      if (_pickupLocation == null) {
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

        if (_mapController != null && _mapSelectionMode == 'none') {
          _mapController!.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: newLoc, zoom: AppConstants.defaultMapZoom) 
          )); 
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
        _tempMapCenter = _pickupLocation ?? const LatLng(AppConstants.fallbackLatitude, AppConstants.fallbackLongitude);
      } else {
        _tempMapCenter = _destinationLocation ?? _pickupLocation ?? const LatLng(AppConstants.fallbackLatitude, AppConstants.fallbackLongitude);
      }
    });

    if (mounted && _mapController != null && _tempMapCenter != null) {
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _tempMapCenter!, zoom: AppConstants.selectionMapZoom) 
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

  void _confirmMapSelection() {
    setState(() { 
      LatLng finalLoc = _tempMapCenter ?? const LatLng(AppConstants.fallbackLatitude, AppConstants.fallbackLongitude); 
      String fallbackCoordinatesText = "إحداثيات: ${finalLoc.latitude.toStringAsFixed(4)}, ${finalLoc.longitude.toStringAsFixed(4)}";
      String locationText = (_mapSearchController.text.trim().isNotEmpty && _mapSearchController.text != 'جاري تحديد الموقع...' && _mapSearchController.text != 'جاري جلب العنوان...') 
          ? _mapSearchController.text.trim() 
          : fallbackCoordinatesText; 
      
      if (_mapSelectionMode == 'pickup') { 
        _pickupLocation = finalLoc; 
        _markers.removeWhere((m) => m.markerId.value == 'pickup'); 
        _markers.add(Marker(markerId: const MarkerId('pickup'), position: finalLoc, infoWindow: const InfoWindow(title: 'مكان التحرك'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow))); 
      } else if (_mapSelectionMode == 'destination') { 
        _destinationLocation = finalLoc; 
        _markers.removeWhere((m) => m.markerId.value == 'destination'); 
        _markers.add(Marker(markerId: const MarkerId('destination'), position: finalLoc, infoWindow: const InfoWindow(title: 'وجهة الوصول'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))); 
      } 
      
      // 🟢 إرسال العنوان الجديد للفورم مباشرة
      _formKey.currentState?.updateLocationText(_mapSelectionMode, locationText);

      _mapSelectionMode = 'none'; 
      _isMapFullscreen = false; 
    });
    _fitMapToMarkers(); 
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.royalGreen),
                  SizedBox(height: 20.h),
                  Text('جاري إرسال طلبك...', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  SizedBox(height: 8.h),
                  Text('برجاء الانتظار قليلاً ⏳', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return BlocProvider.value(
      value: _requestCubit, // 🟢 توفير الكيوبت للفورم الداخلي عشان يقدر يقرأ الحالات ويبعت الطلب
      child: BlocConsumer<PassengerRequestCubit, PassengerRequestState>(
        listener: (context, state) {
          // حالات الموقع
          if (state is LocationLoading) {
            setState(() => _isLoadingMap = true);
          } else if (state is LocationLoaded) {
            _updateLocationOnMap(state.position);
          } else if (state is LocationError) {
            setState(() => _isLoadingMap = false);
            _showSnackBar(state.message);
          } else if (state is LocationPermissionDenied) {
            setState(() => _isLoadingMap = false);
            _showLocationPermissionDialog();
          } 
          
          // حالات العنوان
          else if (state is AddressLoading) {
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
          
          // حالات البحث
          else if (state is PlacesSearchLoaded) {
            setState(() => _placePredictions = state.predictions);
          } else if (state is PlaceDetailsLoaded) {
            setState(() {
              _tempMapCenter = state.location;
              _mapSearchController.text = state.description;
              _placePredictions = [];
            });
            _mapController?.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: state.location, zoom: AppConstants.selectionMapZoom)
            ));
            FocusScope.of(context).unfocus();
          } 
          
          // إرسال الطلب (Submit)
          else if (state is TripSubmitting) {
            _showLoadingDialog(); 
          } else if (state is TripSubmitSuccess) {
            Navigator.of(context, rootNavigator: true).pop(); // إغلاق الديالوج
            
            // إعادة ضبط الفورم بعد النجاح
            _formKey.currentState?.destinationController.clear();
            _formKey.currentState?.priceController.clear();
            _formKey.currentState?.errandDetailsController.clear();
            _formKey.currentState?.errandEstimatedCostController.clear();
            _formKey.currentState?.orderAudioFile = null;
            
            _showSnackBar('تم إرسال طلبك بنجاح! 🚀', isError: false);
            widget.tabController.animateTo(2); 
          } else if (state is TripSubmitError) {
            Navigator.of(context, rootNavigator: true).pop();
            _showSnackBar(state.message);
          }
        },
        builder: (context, state) {
          bool isPickingMap = _mapSelectionMode != 'none'; 

          return LayoutBuilder(
            builder: (context, constraints) {
              double availableHeight = constraints.maxHeight;
              // 🟢 خلينا الارتفاع ثابت ومناسب، والفورم جواه Scrollable لو احتاج مساحة أكبر
              double requestedHeight = screenHeight * 0.55; 
              double visibleSpace = availableHeight - keyboardHeight;
              double actualContainerHeight = math.max(0.0, math.min(requestedHeight, visibleSpace));

              return Stack(
                children: [
                  // 🗺️ الخريطة
                  Positioned.fill(
                    child: _isLoadingMap 
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
                      : LammaGoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _pickupLocation ?? const LatLng(AppConstants.fallbackLatitude, AppConstants.fallbackLongitude),
                            zoom: AppConstants.defaultMapZoom,
                          ),
                          markers: isPickingMap ? {} : _markers,
                          showCenterPin: isPickingMap,
                          onMapCreated: (controller) => _mapController = controller,
                          onCameraMove: (position) {
                            if (isPickingMap) {
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
                            if (isPickingMap && _tempMapCenter != null) {
                              _requestCubit.getAddressFromLatLng(_tempMapCenter!);
                            }
                          },
                        ),
                  ),

                  // 🔍 شريط البحث أثناء اختيار الموقع
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

                  // 📌 زر التأكيد في وضع الشاشة الكاملة
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

                  // 📋 فورم الطلب
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
                          key: _formKey, // ربط الـ Key عشان نقدر نحدث العنوان
                          pickupLocation: _pickupLocation,
                          destinationLocation: _destinationLocation,
                          onOpenMapSelection: _openMapSelection,
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