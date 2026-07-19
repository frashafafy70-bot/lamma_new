// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/theme/app_theme.dart';
import 'package:lamma_new/core/constants/app_constants.dart';
import 'package:lamma_new/core/di/injection_container.dart';

import 'package:lamma_new/features/trips/utils/passenger_utils.dart';
import 'package:lamma_new/features/trips/cubit/passenger/passenger_request_cubit.dart';
import 'package:lamma_new/features/trips/domain/entities/place_search_entity.dart';

import 'package:lamma_new/features/trips/presentation/widgets/passenger_request/trip_category.dart';
import 'package:lamma_new/features/trips/presentation/widgets/passenger_request/passenger_map_section.dart';
import 'package:lamma_new/features/trips/presentation/widgets/map_selection_overlay.dart';
import 'package:lamma_new/features/trips/presentation/widgets/service_form/buy_orders_service_form.dart';
import 'package:lamma_new/features/trips/presentation/widgets/service_form/ride_service_form.dart';
import 'package:lamma_new/features/trips/presentation/widgets/service_form/travel_service_form.dart';
import 'package:lamma_new/features/trips/presentation/widgets/passenger_request/passenger_action_panel.dart';
import 'package:lamma_new/features/trips/presentation/pages/passenger_tabs/mixins/passenger_ui_mixin.dart';
// تأكد من استيراد امتداد اللغة
// import 'package:lamma_new/l10n/l10n.dart';

class PassengerRequestTab extends StatefulWidget {
  final TabController tabController;
  const PassengerRequestTab({super.key, required this.tabController});

  @override
  State<PassengerRequestTab> createState() => _PassengerRequestTabState();
}

class _PassengerRequestTabState extends State<PassengerRequestTab>
    with PassengerUIMixin {
  late final PassengerRequestCubit _requestCubit = sl<PassengerRequestCubit>();

  final PassengerFormControllers _formControllers = PassengerFormControllers();

  TripCategory _selectedCategory = TripCategory.internal;
  String _vehicleType = 'سيارة';
  File? _orderAudioFile;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  LatLng? _tempMapCenter;

  bool _isLoadingMap = true;
  String _mapSelectionMode = AppConstants.mapModeNone;
  bool _isMapFullscreen = false;
  bool _isReverseGeocoding = false;

  final TextEditingController _mapSearchController = TextEditingController();
  List<PlaceSearchEntity> _placePredictions = [];
  final double _closeZoom = AppConstants.defaultMapZoom;

  @override
  void initState() {
    super.initState();
    _requestCubit.getUserLocation();
  }

  @override
  void dispose() {
    _mapSearchController.dispose();
    _mapController?.dispose();
    _formControllers.dispose();
    super.dispose();
  }

  Future<void> _updateRoutePolyline() async {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    _polylines.clear();
    if (_pickupLocation != null && _destinationLocation != null) {
      setState(() {
        _polylines.add(Polyline(
          polylineId: const PolylineId(AppConstants.tempRoutePolylineId),
          points: [_pickupLocation!, _destinationLocation!],
          color: (colors?.primaryNavy ?? AppColors.primaryNavy).withOpacity(0.5),
          width: 4,
          patterns: [PatternItem.dash(15), PatternItem.gap(10)],
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
        ));
      });
      _requestCubit.fetchRoute(_pickupLocation!, _destinationLocation!);
    }
  }

  void _updateLocationOnMap(LatLng newLoc) {
    if (!mounted) return;
    setState(() {
      _isLoadingMap = false;
      if (_pickupLocation == null) {
        _pickupLocation = newLoc;
        _markers.removeWhere((m) =>
            m.markerId.value == AppConstants.pickupMarkerId);
        _markers.add(Marker(
          markerId: const MarkerId(AppConstants.pickupMarkerId),
          position: newLoc,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: context.l10n.pickupLocation),
        ));
        if (_mapSelectionMode != AppConstants.mapModeNone &&
            _tempMapCenter == null) {
          _tempMapCenter = newLoc;
        }
        if (_mapController != null &&
            _mapSelectionMode == AppConstants.mapModeNone) {
          _mapController!.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: newLoc, zoom: _closeZoom)));
        }
      }
    });
  }

  void _openMapSelection(String mode) {
    FocusScope.of(context).unfocus();
    UXFeedback.lightImpact();
    setState(() {
      _mapSelectionMode = mode;
      _isMapFullscreen = true;
      _tempMapCenter = mode == AppConstants.mapModePickup
          ? (_pickupLocation ??
              const LatLng(AppConstants.fallbackLatitude,
                  AppConstants.fallbackLongitude))
          : (_destinationLocation ??
              _pickupLocation ??
              const LatLng(AppConstants.fallbackLatitude,
                  AppConstants.fallbackLongitude));
    });
    if (mounted && _mapController != null && _tempMapCenter != null) {
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: _tempMapCenter!, zoom: _closeZoom)));
      _requestCubit.getAddressFromLatLng(_tempMapCenter!);
    }
  }

  void _onMapTap(LatLng position) {
    if (_mapSelectionMode == AppConstants.mapModeNone) {
      setState(() {
        _isMapFullscreen = true;
        _mapSelectionMode = AppConstants.mapModePickup;
      });
    }
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: _closeZoom)));
    setState(() => _tempMapCenter = position);
    _requestCubit.getAddressFromLatLng(position);
  }

  void _fitMapToMarkers() {
    if (_pickupLocation != null &&
        _destinationLocation != null &&
        _mapController != null) {
      LatLngBounds bounds =
          _pickupLocation!.latitude > _destinationLocation!.latitude
              ? LatLngBounds(
                  southwest: _destinationLocation!, northeast: _pickupLocation!)
              : LatLngBounds(
                  southwest: _pickupLocation!,
                  northeast: _destinationLocation!);
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } else if (_pickupLocation != null && _mapController != null) {
      _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_pickupLocation!, _closeZoom));
    } else if (_destinationLocation != null && _mapController != null) {
      _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_destinationLocation!, _closeZoom));
    }
  }

  void _confirmMapSelection() {
    UXFeedback.selectionClick();
    setState(() {
      LatLng finalLoc = _tempMapCenter ??
          const LatLng(
              AppConstants.fallbackLatitude, AppConstants.fallbackLongitude);
      String locationText = (_mapSearchController.text.trim().isNotEmpty &&
              _mapSearchController.text != context.l10n.locatingMap &&
              _mapSearchController.text != context.l10n.fetchingAddress)
          ? _mapSearchController.text.trim()
          : "إحداثيات: ${finalLoc.latitude.toStringAsFixed(4)}, ${finalLoc.longitude.toStringAsFixed(4)}";

      if (_mapSelectionMode == AppConstants.mapModePickup) {
        _pickupLocation = finalLoc;
        _markers.removeWhere((m) =>
            m.markerId.value == AppConstants.pickupMarkerId);
        _markers.add(Marker(
            markerId: const MarkerId(AppConstants.pickupMarkerId),
            position: finalLoc,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: context.l10n.pickupLocation)));
        _formControllers.pickup.text = locationText;
      } else if (_mapSelectionMode == AppConstants.mapModeDestination) {
        _destinationLocation = finalLoc;
        _markers.removeWhere((m) =>
            m.markerId.value == AppConstants.destinationMarkerId);
        _markers.add(Marker(
            markerId: const MarkerId(AppConstants.destinationMarkerId),
            position: finalLoc,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: context.l10n.destinationLocation)));
        _formControllers.destination.text = locationText;
      }
      _updateRoutePolyline();
      _mapSelectionMode = AppConstants.mapModeNone;
      _isMapFullscreen = false;
    });
    Future.delayed(const Duration(milliseconds: 300), () => _fitMapToMarkers());
  }

  void _submitTrip() {
    FocusScope.of(context).unfocus();

    if (_pickupLocation == null)
      return showPassengerSnackBar(context.l10n.errorSelectPickup);

    if (_selectedCategory == TripCategory.internal ||
        _selectedCategory == TripCategory.travel) {
      if (_destinationLocation == null)
        return showPassengerSnackBar(context.l10n.errorSelectDestination);
    } else if (_selectedCategory == TripCategory.shopping) {
      if (_formControllers.errandDetails.text.trim().isEmpty &&
          _orderAudioFile == null)
        return showPassengerSnackBar(context.l10n.errorProvideOrderDetails);
    }

    if (_formControllers.price.text.trim().isEmpty)
      return showPassengerSnackBar(context.l10n.errorEnterPrice);

    double? parsedPrice = double.tryParse(_formControllers.price.text.trim());
    if (parsedPrice == null || parsedPrice <= 0)
      return showPassengerSnackBar(context.l10n.errorInvalidPrice);

    _requestCubit.submitTripRequest(
      tripCategory: _selectedCategory.value,
      vehicleType: _vehicleType,
      pickup: _formControllers.pickup.text.trim(),
      destination: _formControllers.destination.text.trim(),
      price: _formControllers.price.text.trim(),
      errandDetails: _formControllers.errandDetails.text.trim(),
      errandCost: _formControllers.errandEstimatedCost.text.trim(),
      pickupLocation: _pickupLocation,
      destinationLocation: _destinationLocation,
      orderAudioFile: _orderAudioFile,
    );
  }

  Widget _buildSelectedServiceForm(bool isSubmitting, AppColorsExtension colors) {
    final Map<TripCategory, Widget Function()> formStrategies = {
      TripCategory.shopping: () => BuyOrdersServiceForm(
            isSubmittingTrip: isSubmitting,
            errandDetailsController: _formControllers.errandDetails,
            errandEstimatedCostController: _formControllers.errandEstimatedCost,
            pickupController: _formControllers.pickup,
            destinationController: _formControllers.destination,
            priceController: _formControllers.price,
            priceFocusNode: _formControllers.priceFocusNode,
            primaryGreen: colors.royalGreen, 
            accentGold: colors.accentGold,
            onOpenMapSelection: _openMapSelection,
            onAudioRecorded: (file) => setState(() => _orderAudioFile = file),
            onSubmit: _submitTrip,
          ),
      TripCategory.internal: () => RideServiceForm(
            vehicleType: _vehicleType,
            onVehicleChanged: (veh) {
              UXFeedback.selectionClick();
              setState(() => _vehicleType = veh);
            },
            isSubmittingTrip: isSubmitting,
            pickupController: _formControllers.pickup,
            destinationController: _formControllers.destination,
            priceController: _formControllers.price,
            priceFocusNode: _formControllers.priceFocusNode,
            primaryGreen: colors.royalGreen, 
            accentGold: colors.accentGold,
            onOpenMapSelection: _openMapSelection,
            onSubmit: _submitTrip,
          ),
      TripCategory.travel: () => TravelServiceForm(
            vehicleType: _vehicleType,
            onVehicleChanged: (veh) {
              UXFeedback.selectionClick();
              setState(() => _vehicleType = veh);
            },
            isSubmittingTrip: isSubmitting,
            pickupController: _formControllers.pickup,
            destinationController: _formControllers.destination,
            priceController: _formControllers.price,
            priceFocusNode: _formControllers.priceFocusNode,
            primaryGreen: colors.royalGreen, 
            accentGold: colors.accentGold,
            onOpenMapSelection: _openMapSelection,
            onSubmit: _submitTrip,
          ),
    };

    return formStrategies[_selectedCategory]?.call() ?? const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>() ?? 
        const AppColorsExtension(
          primaryNavy: AppColors.primaryNavy,
          primaryDarkLight: AppColors.primaryDarkLight,
          accentGold: AppColors.accentGold,
          accentGoldLight: AppColors.accentGoldLight,
          royalGreen: AppColors.royalGreen,
          royalGreenLight: AppColors.royalGreenLight,
          medicalTeal: AppColors.medicalTeal,
          medicalTealLight: AppColors.medicalTealLight,
        );

    double screenHeight = MediaQuery.of(context).size.height;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return BlocProvider.value(
      value: _requestCubit,
      child: BlocConsumer<PassengerRequestCubit, PassengerRequestState>(
        listener: (context, state) {
          if (state is LocationLoading)
            setState(() => _isLoadingMap = true);
          else if (state is LocationLoaded)
            _updateLocationOnMap(state.position);
          else if (state is LocationError) {
            setState(() => _isLoadingMap = false);
            showPassengerSnackBar(state.message);
          } else if (state is LocationPermissionDenied) {
            setState(() => _isLoadingMap = false);
            showLocationPermissionDialog(context.l10n);
          } else if (state is AddressLoading)
            setState(() {
              _isReverseGeocoding = true;
              _mapSearchController.text = context.l10n.locatingMap;
            });
          else if (state is AddressLoaded)
            setState(() {
              _isReverseGeocoding = false;
              _mapSearchController.text = state.address;
            });
          else if (state is AddressError)
            setState(() {
              _isReverseGeocoding = false;
              _mapSearchController.text = state.message;
            });
          else if (state is PlacesSearchLoaded)
            setState(() => _placePredictions =
                List<PlaceSearchEntity>.from(state.predictions));
          else if (state is PlaceDetailsLoaded) {
            setState(() {
              _tempMapCenter = state.location;
              _mapSearchController.text = state.description;
              _placePredictions = [];
            });
            _mapController?.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(target: state.location, zoom: _closeZoom)));
            FocusScope.of(context).unfocus();
          } else if (state is TripSubmitting)
            showTripLoadingDialog(context.l10n);
          else if (state is TripSubmitSuccess) {
            Navigator.of(context, rootNavigator: true).pop();
            UXFeedback.success();
            _formControllers.destination.clear();
            _formControllers.price.clear();
            _formControllers.errandDetails.clear();
            _formControllers.errandEstimatedCost.clear();
            _orderAudioFile = null;
            showPassengerSnackBar(context.l10n.requestSentSuccess,
                isError: false);
            widget.tabController.animateTo(2);
          } else if (state is TripSubmitError) {
            Navigator.of(context, rootNavigator: true).pop();
            showPassengerSnackBar(state.message);
          } else if (state is RouteCoordinatesLoaded &&
              state.routePoints.isNotEmpty &&
              mounted) {
            setState(() {
              _polylines.removeWhere((p) =>
                  p.polylineId.value == AppConstants.tempRoutePolylineId);
              _polylines.add(Polyline(
                polylineId: const PolylineId(AppConstants.finalRoutePolylineId),
                points: state.routePoints,
                color: colors.primaryNavy,
                width: 5,
                endCap: Cap.roundCap,
                startCap: Cap.roundCap,
              ));
            });
            _fitMapToMarkers();
          }
        },
        builder: (context, state) {
          bool isPickingMap = _mapSelectionMode != AppConstants.mapModeNone;

          return LayoutBuilder(
            builder: (context, constraints) {
              double actualContainerHeight = math.max(
                  0.0,
                  math.min(screenHeight * 0.55,
                      constraints.maxHeight - keyboardHeight));

              return Stack(
                children: [
                  Positioned.fill(
                    child: PassengerMapSection(
                      isLoadingMap: _isLoadingMap,
                      pickupLocation: _pickupLocation,
                      fallbackLatitude: AppConstants.fallbackLatitude,
                      fallbackLongitude: AppConstants.fallbackLongitude,
                      closeZoom: _closeZoom,
                      markers: _markers,
                      polylines: _polylines,
                      isPickingMap: isPickingMap,
                      isMapFullscreen: _isMapFullscreen,
                      actualContainerHeight: actualContainerHeight,
                      onMapCreated: (c) => _mapController = c,
                      onMapTap: _onMapTap,
                      onCameraMove: (pos) {
                        if (isPickingMap) {
                          _tempMapCenter = pos.target;
                          if (!_isReverseGeocoding)
                            setState(() {
                              _isReverseGeocoding = true;
                              _mapSearchController.text =
                                  context.l10n.locatingMap;
                            });
                        }
                      },
                      onCameraIdle: () => (isPickingMap &&
                              _tempMapCenter != null)
                          ? _requestCubit.getAddressFromLatLng(_tempMapCenter!)
                          : null,
                    ),
                  ),
                  if (isPickingMap)
                    MapSelectionOverlay(
                      mapSearchController: _mapSearchController,
                      placePredictions: _placePredictions.cast<dynamic>(),
                      isReverseGeocoding: _isReverseGeocoding,
                      primaryGreen: colors.royalGreen, 
                      accentGold: colors.accentGold,
                      onSearch: (input) => _requestCubit.searchForPlaces(input),
                      onSelectPlace: (id, desc) =>
                          _requestCubit.fetchPlaceDetails(id, desc),
                      onCancel: () {
                        UXFeedback.lightImpact();
                        setState(() {
                          _mapSelectionMode = AppConstants.mapModeNone;
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
                      bottom: 30.h,
                      left: 30.w,
                      right: 30.w,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.royalGreen, 
                          foregroundColor: colors.accentGold,
                          shadowColor: colors.royalGreen.withOpacity(0.4),
                          elevation: 10,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r)),
                        ),
                        onPressed: () {
                          UXFeedback.selectionClick();
                          setState(() => _isMapFullscreen = false);
                          _fitMapToMarkers();
                        },
                        icon: Icon(Icons.check_circle_rounded, size: 24.sp),
                        label: Text(context.l10n.confirmLocation,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16.sp)),
                      ),
                    ),
                  PassengerActionPanel(
                    actualContainerHeight: actualContainerHeight,
                    keyboardHeight: keyboardHeight,
                    isMapFullscreen: _isMapFullscreen,
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: (cat) {
                      UXFeedback.selectionClick();
                      setState(() => _selectedCategory = cat);
                    },
                    serviceFormWidget: _buildSelectedServiceForm(
                      state is TripSubmitting, 
                      colors,
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