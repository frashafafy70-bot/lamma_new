// ignore_for_file: use_build_context_synchronously

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auto_route/auto_route.dart';

import 'package:lamma_new/l10n/app_localizations.dart';
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/theme/app_theme.dart'; // 🟢 استدعاء الثيم المخصص
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';
import 'package:lamma_new/features/trips/presentation/widgets/negotiation_widget.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_live_cubit.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_live_state.dart';
import 'package:lamma_new/core/services/navigation_service.dart';

// ==========================================
// Tween for smooth marker animation
// ==========================================
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required super.begin, required super.end});
  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}

// ==========================================
// Page Wrapper with BlocProvider
// ==========================================
@RoutePage()
class PassengerTripTrackingPage extends StatelessWidget {
  final String tripId;
  final String passengerId;

  const PassengerTripTrackingPage(
      {super.key, required this.tripId, required this.passengerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TripLiveCubit(tripId: tripId),
      child:
          _PassengerTripTrackingView(tripId: tripId, passengerId: passengerId),
    );
  }
}

// ==========================================
// Main Stateful View
// ==========================================
class _PassengerTripTrackingView extends StatefulWidget {
  final String tripId;
  final String passengerId;
  const _PassengerTripTrackingView(
      {required this.tripId, required this.passengerId});

  @override
  State<_PassengerTripTrackingView> createState() =>
      _PassengerTripTrackingViewState();
}

class _PassengerTripTrackingViewState extends State<_PassengerTripTrackingView>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _hasShownRatingDialog = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _previousStatus = '';

  AnimationController? _animationController;
  LatLng? _currentDriverPosition;
  double _markerRotation = 0.0;

  final String _premiumMapStyle =
      '''[{"elementType": "geometry", "stylers": [{"color": "#f5f5f5"}]}, {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]}, {"elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]}, {"elementType": "labels.text.stroke", "stylers": [{"color": "#f5f5f5"}]}, {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]}]''';
  final String _darkMapStyle =
      '''[{"elementType": "geometry", "stylers": [{"color": "#212121"}]}, {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]}, {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]}, {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]}, {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#2c2c2c"}]}]''';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
  }

  Future<void> _playSoundForStatus(String status) async {
    try {
      if (status == 'negotiating')
        await _audioPlayer.play(AssetSource('audio/ping_pong.mp3'));
      else if (status == 'cancelled')
        await _audioPlayer.play(AssetSource('audio/cancell.mp3'));
      else if (status == 'completed')
        await _audioPlayer.play(AssetSource('audio/notification.mp3'));
      else if (status == 'accepted' ||
          status == 'arrived' ||
          status == 'on_the_way')
        await _audioPlayer.play(AssetSource('audio/edite.mp3'));
    } catch (e) {
      debugPrint("مشكلة في تشغيل الصوت: $e");
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _audioPlayer.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  double _getBearing(LatLng begin, LatLng end) {
    double lat1 = begin.latitude * math.pi / 180.0;
    double lon1 = begin.longitude * math.pi / 180.0;
    double lat2 = end.latitude * math.pi / 180.0;
    double lon2 = end.longitude * math.pi / 180.0;
    double dLon = lon2 - lon1;
    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return ((math.atan2(y, x) * 180.0 / math.pi) + 360.0) % 360.0;
  }

  void _updateDriverMarker(BuildContext context, GeoPoint? driverLocation) {
    if (driverLocation == null) return;
    LatLng newDriverPos =
        LatLng(driverLocation.latitude, driverLocation.longitude);

    if (_currentDriverPosition == null) {
      setState(() {
        _currentDriverPosition = newDriverPos;
        _drawMarkers(context);
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(newDriverPos));
      return;
    }

    if (_currentDriverPosition != newDriverPos) {
      _markerRotation = _getBearing(_currentDriverPosition!, newDriverPos);
      Animation<LatLng> animation =
          LatLngTween(begin: _currentDriverPosition, end: newDriverPos).animate(
              CurvedAnimation(
                  parent: _animationController!, curve: Curves.linear));
      animation.addListener(() {
        setState(() {
          _currentDriverPosition = animation.value;
          _drawMarkers(context);
        });
      });
      _animationController?.forward(from: 0.0);
      _mapController?.animateCamera(CameraUpdate.newLatLng(newDriverPos));
    }
  }

  void _drawMarkers(BuildContext context) {
    _markers.removeWhere((m) => m.markerId.value == 'driver_car');
    if (_currentDriverPosition != null) {
      _markers.add(Marker(
          markerId: const MarkerId('driver_car'),
          position: _currentDriverPosition!,
          rotation: _markerRotation,
          anchor: const Offset(0.5, 0.5),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
              title: AppLocalizations.of(context)!.driverMarkerTitle)));
    }
  }

  String _getStatusText(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return AppLocalizations.of(context)!.statusPendingSearching;
      case 'negotiating':
        return AppLocalizations.of(context)!.statusNegotiatingPrice;
      case 'accepted':
        return AppLocalizations.of(context)!.statusAcceptedGettingReady;
      case 'on_the_way':
        return AppLocalizations.of(context)!.statusOnTheWay;
      case 'arrived':
        return AppLocalizations.of(context)!.statusCaptainArrived;
      case 'in_progress':
        return AppLocalizations.of(context)!.statusTripInProgress;
      case 'completed':
        return AppLocalizations.of(context)!.statusArrivedSafely;
      case 'cancelled':
        return AppLocalizations.of(context)!.statusTripCancelled;
      default:
        return AppLocalizations.of(context)!.loading;
    }
  }

  Color _getStatusColor(String status, ThemeData theme) {
    final customColors = theme.extension<AppColorsExtension>();
    switch (status) {
      case 'pending':
      case 'negotiating':
        return Colors.orange;
      case 'accepted':
      case 'on_the_way':
        return Colors.blueAccent;
      case 'arrived':
      case 'in_progress':
      case 'completed':
        return customColors?.royalGreen ?? AppColors.royalGreen;
      case 'cancelled':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.primary;
    }
  }

  // 🟢 دالة التقييم كاملة
  void _showRatingDialog(
      BuildContext context, TripEntity trip, ThemeData theme) {
    int selectedRating = 5;
    TextEditingController commentController = TextEditingController();
    final customColors = theme.extension<AppColorsExtension>();

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r)),
              elevation: 10,
              backgroundColor: theme.colorScheme.surface,
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color:
                            (customColors?.royalGreen ?? AppColors.royalGreen)
                                .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle_rounded,
                          color:
                              customColors?.royalGreen ?? AppColors.royalGreen,
                          size: 50.sp),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      AppLocalizations.of(context)!.tripEndedSuccessfully,
                      style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      AppLocalizations.of(context)!
                          .rateCaptain(trip.driverName ?? ''),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14.sp,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7)),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setStateDialog(() => selectedRating = index + 1);
                          },
                          child: Icon(
                            index < selectedRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: customColors?.accentGold ??
                                AppColors.accentGold,
                            size: 40.sp,
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 20.h),
                    TextField(
                      controller: commentController,
                      maxLines: 2,
                      style: TextStyle(
                          fontSize: 14.sp, color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(context)!.addCommentOptional,
                        hintStyle: TextStyle(
                            fontSize: 12.sp,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5)),
                        filled: true,
                        fillColor:
                            theme.colorScheme.onSurface.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              customColors?.royalGreen ?? AppColors.royalGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          context.read<TripActionsCubit>().submitRating(
                              tripId: trip.id ?? widget.tripId,
                              rating: selectedRating.toDouble(),
                              comment: commentController.text.trim());
                          Navigator.pop(dialogContext);
                          Navigator.pop(context);
                        },
                        child: Text(
                            AppLocalizations.of(context)!.submitRatingBtn,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                                color: Colors.white)),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.of(context)!.skipBtn,
                          style: TextStyle(
                              fontSize: 14.sp,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          title: Text(AppLocalizations.of(context)!.trackTripTitle,
              style: TextStyle(
                  color: theme.appBarTheme.foregroundColor, fontSize: 18.sp)),
          centerTitle: true,
          iconTheme: theme.appBarTheme.iconTheme ??
              IconThemeData(color: theme.appBarTheme.foregroundColor),
        ),
        body: BlocConsumer<TripLiveCubit, TripLiveState>(
            listener: (context, state) {
          if (state is TripLiveLoaded) {
            if (_previousStatus.isNotEmpty && state.status != _previousStatus) {
              _playSoundForStatus(state.status);
            }
            _previousStatus = state.status;

            if (state.status == 'completed' && !_hasShownRatingDialog) {
              _hasShownRatingDialog = true;
              _showRatingDialog(context, state.trip, theme);
            }

            if (['in_progress', 'arrived', 'accepted', 'on_the_way']
                .contains(state.status)) {
              _updateDriverMarker(context, state.rawData['driverLocation']);
            }
          }
        }, builder: (context, state) {
          if (state is TripLiveLoading || state is TripLiveInitial) {
            return Center(
                child: CircularProgressIndicator(
                    color: theme.colorScheme.primary));
          }
          if (state is TripLiveError) {
            return Center(
                child: Text(state.message,
                    style: TextStyle(
                        fontSize: 16.sp, color: theme.colorScheme.onSurface)));
          }

          if (state is TripLiveLoaded) {
            return Stack(
              children: [
                Positioned.fill(
                  bottom: state.status == 'negotiating' ? 300.h : 260.h,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                        target: LatLng(
                            state.trip.pickupLocation?.latitude ?? 30.0,
                            state.trip.pickupLocation?.longitude ?? 31.0),
                        zoom: 15),
                    style: isDarkMode ? _darkMapStyle : _premiumMapStyle,
                    markers: _markers,
                    onMapCreated: (controller) => _mapController = controller,
                    zoomControlsEnabled: false,
                    myLocationEnabled: true,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildPassengerBottomSheet(context, state, theme),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        }),
      ),
    );
  }

  // 🟢 فصل الواجهة: الجزء السفلي للراكب
  Widget _buildPassengerBottomSheet(
      BuildContext context, TripLiveLoaded state, ThemeData theme) {
    final customColors = theme.extension<AppColorsExtension>();
    bool driverAssigned =
        state.trip.driverId != null && state.trip.driverId!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, -5))
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 40.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(10.r)))),
          SizedBox(height: 16.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                    color: _getStatusColor(state.status, theme)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(Icons.info_outline,
                    color: _getStatusColor(state.status, theme), size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                  child: Text(_getStatusText(context, state.status),
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary))),
            ],
          ),
          Divider(height: 24, thickness: 1, color: theme.dividerColor),
          if (driverAssigned && state.status != 'negotiating') ...[
            _buildDriverInfo(context, state.rawData, state.trip, theme),
            Divider(height: 24, thickness: 1, color: theme.dividerColor),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.toDestination,
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5))),
                  SizedBox(
                      width: 200.w,
                      child: Text(
                          state.trip.destination ??
                              AppLocalizations.of(context)!
                                  .destinationPlaceholder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: theme.colorScheme.onSurface))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(AppLocalizations.of(context)!.priceLabel,
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5))),
                  Text(
                      AppLocalizations.of(context)!.priceWithCurrency(
                          '${state.trip.finalPrice ?? state.trip.price ?? '--'}'),
                      style: TextStyle(
                          color:
                              customColors?.royalGreen ?? AppColors.royalGreen,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          if (state.status == 'negotiating') ...[
            SizedBox(height: 16.h),
            NegotiationWidget(
                trip: state.trip,
                isDriver: false,
                currentUserId: widget.passengerId),
          ],
          if (state.status == 'pending' || state.status == 'accepted') ...[
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r))),
                onPressed: () => context
                    .read<TripActionsCubit>()
                    .cancelTripFully(tripId: widget.tripId, isDriver: false),
                child: Text(AppLocalizations.of(context)!.cancelTripBtn,
                    style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  // 🟢 فصل الواجهة: معلومات السائق للراكب
  Widget _buildDriverInfo(BuildContext context, Map<String, dynamic> rawData,
      TripEntity trip, ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28.r,
          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          backgroundImage: rawData['driverImage'] != null
              ? NetworkImage(rawData['driverImage'])
              : null,
          child: rawData['driverImage'] == null
              ? Icon(Icons.person,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  size: 30.sp)
              : null,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  trip.driverName ?? AppLocalizations.of(context)!.lammaCaptain,
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface)),
              Text(
                  '${rawData['carModel'] ?? AppLocalizations.of(context)!.carVehicle} • ${rawData['carPlate'] ?? AppLocalizations.of(context)!.noPlateBoard}',
                  style: TextStyle(
                      fontSize: 13.sp,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => NavigationService.navigateToTripChat(widget.tripId),
              child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: Icon(Icons.chat_bubble_outline,
                      color: AppColors.info, size: 22.sp)),
            ),
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: () async {
                final phone = rawData['driverPhone'] ?? '';
                if (phone.isNotEmpty) {
                  final url = Uri.parse('tel:$phone');
                  if (await canLaunchUrl(url)) await launchUrl(url);
                }
              },
              child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: Icon(Icons.phone_in_talk,
                      color: AppColors.success, size: 22.sp)),
            ),
          ],
        )
      ],
    );
  }
}
