// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:auto_route/auto_route.dart';

import 'package:lamma_new/l10n/app_localizations.dart';
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/theme/app_theme.dart'; // 🟢 تم إضافة استدعاء الثيم
import 'package:lamma_new/core/extensions/context_extension.dart';
import 'package:lamma_new/core/di/injection_container.dart';
import 'package:lamma_new/core/services/navigation_service.dart';

import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart';
import 'package:lamma_new/features/trips/presentation/widgets/driver_live_map.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_state.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_state.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_live_cubit.dart'; // 🟢 Cubit البث المباشر
import 'package:lamma_new/features/trips/cubit/shared/trip_live_state.dart';

@RoutePage()
class DriverTripTrackingPage extends StatelessWidget {
  final String tripId;

  const DriverTripTrackingPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<DriverActiveTripsCubit>()),
        BlocProvider(create: (context) => sl<TripActionsCubit>()),
        BlocProvider(
            create: (context) =>
                TripLiveCubit(tripId: tripId)), // 🟢 تسجيل الـ Cubit الجديد
      ],
      child: _DriverTripTrackingView(tripId: tripId),
    );
  }
}

class _DriverTripTrackingView extends StatefulWidget {
  final String tripId;
  const _DriverTripTrackingView({required this.tripId});

  @override
  State<_DriverTripTrackingView> createState() =>
      _DriverTripTrackingViewState();
}

class _DriverTripTrackingViewState extends State<_DriverTripTrackingView> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _previousStatus = '';

  Future<void> _playSoundForStatus(String status) async {
    try {
      if (status == 'negotiating')
        await _audioPlayer.play(AssetSource('audio/ping_pong.mp3'));
      else if (status == 'cancelled')
        await _audioPlayer.play(AssetSource('audio/cancell.mp3'));
      else if (status == 'completed')
        await _audioPlayer.play(AssetSource('audio/notification.mp3'));
      else if (status == 'accepted')
        await _audioPlayer.play(AssetSource('audio/edite.mp3'));
    } catch (e) {
      debugPrint("مشكلة في تشغيل الصوت: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _launchGoogleMapsNavigation(
      double? lat, double? lng, ThemeData theme) async {
    if (lat == null || lng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.clientLocationNotAvailable,
                  style: TextStyle(fontSize: 14.sp)),
              backgroundColor: theme.colorScheme.error),
        );
      }
      return;
    }
    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.cannotOpenGoogleMaps,
                  style: TextStyle(fontSize: 14.sp)),
              backgroundColor: theme.colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorsExtension>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: MultiBlocListener(
        listeners: [
          // 🟢 مستمع للأصوات والتغيرات في حالة الرحلة
          BlocListener<TripLiveCubit, TripLiveState>(
            listener: (context, state) {
              if (state is TripLiveLoaded) {
                if (_previousStatus.isNotEmpty &&
                    state.status != _previousStatus) {
                  _playSoundForStatus(state.status);
                }
                _previousStatus = state.status;
              }
            },
          ),
          BlocListener<DriverActiveTripsCubit, DriverActiveTripsState>(
            listener: (context, state) {
              if (state is DriverActiveTripsActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.message,
                        style: const TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: AppColors.success));
              } else if (state is DriverActiveTripsActionError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.message,
                        style: const TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: theme.colorScheme.error));
              }
            },
          ),
          BlocListener<TripActionsCubit, TripActionsState>(
            listener: (context, state) {
              if (state is TripActionsLoading) {
                showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => Center(
                        child: CircularProgressIndicator(
                            color: customColors?.accentGold ??
                                AppColors.accentGold)));
              } else if (state is TripActionsSuccess) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.message,
                        style: const TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: AppColors.success));
              } else if (state is TripActionsError) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.message,
                        style: const TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: theme.colorScheme.error));
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: BlocBuilder<TripLiveCubit, TripLiveState>(
              // 🟢 استبدال StreamBuilder
              builder: (context, state) {
            if (state is TripLiveLoading || state is TripLiveInitial) {
              return Center(
                  child: CircularProgressIndicator(
                      color: theme.colorScheme.primary));
            }

            if (state is TripLiveError) {
              return Center(
                  child: Text(state.message,
                      style: TextStyle(
                          fontSize: 16.sp, color: theme.colorScheme.error)));
            }

            if (state is TripLiveLoaded) {
              GeoPoint? pickupGeo = state.rawData['pickupLocation'];
              double? clientLat = pickupGeo?.latitude;
              double? clientLng = pickupGeo?.longitude;

              return Column(
                children: [
                  _buildHeader(
                      context, theme, customColors, clientLat, clientLng),
                  Expanded(
                    child: DriverLiveMap(
                        tripId: widget.tripId,
                        targetLat: clientLat,
                        targetLng: clientLng),
                  ),
                  _buildBottomSheet(context, state, theme),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ),
      ),
    );
  }

  // 🟢 فصل الواجهة: الهيدر
  Widget _buildHeader(BuildContext context, ThemeData theme,
      AppColorsExtension? customColors, double? lat, double? lng) {
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10.h,
          bottom: 16.h,
          left: 20.w,
          right: 20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          theme.colorScheme.primary,
          customColors?.royalGreen ?? AppColors.royalGreen
        ], begin: Alignment.topRight, end: Alignment.bottomLeft),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
        boxShadow: [
          BoxShadow(
              color: (customColors?.royalGreen ?? AppColors.royalGreen)
                  .withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 28)),
          Text(AppLocalizations.of(context)!.trackTripTitle,
              style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          InkWell(
            onTap: () => _launchGoogleMapsNavigation(lat, lng, theme),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle),
              child: Icon(Icons.navigation_rounded,
                  color: customColors?.accentGold ?? AppColors.accentGold,
                  size: 22.sp),
            ),
          ),
        ],
      ),
    );
  }

  // 🟢 فصل الواجهة: الجزء السفلي
  Widget _buildBottomSheet(
      BuildContext context, TripLiveLoaded state, ThemeData theme) {
    String destination = state.rawData['destination'] ??
        AppLocalizations.of(context)!.unspecifiedDestination;
    String price = state.rawData['price']?.toString() ?? '0';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, -5))
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 40.w,
                  height: 5.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(10.r)))),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_rounded,
                  color: theme.colorScheme.error, size: 24.sp),
              SizedBox(width: 8.w),
              Expanded(
                  child: Text(destination,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          color: theme.colorScheme.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.monetization_on_rounded,
                  color: AppColors.success, size: 24.sp),
              SizedBox(width: 8.w),
              Text(AppLocalizations.of(context)!.agreedPrice(price),
                  style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp)),
            ],
          ),
          Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Divider(color: theme.dividerColor)),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 50.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r))),
                    onPressed: () =>
                        NavigationService.navigateToTripChat(widget.tripId),
                    child: Icon(Icons.chat_rounded,
                        color: Colors.white, size: 24.sp),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 3,
                child: SizedBox(
                    height: 50.h,
                    child: _buildDynamicActionButton(
                        context, state.status, theme)),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDynamicActionButton(
      BuildContext context, String status, ThemeData theme) {
    if (status == 'accepted') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r))),
        icon: Icon(Icons.location_on, color: Colors.white, size: 20.sp),
        label: Text(AppLocalizations.of(context)!.iArrivedToClient,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15.sp)),
        onPressed: () => context
            .read<DriverActiveTripsCubit>()
            .updateTripState(widget.tripId, 'arrived'),
      );
    } else if (status == 'arrived') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r))),
        icon: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20.sp),
        label: Text(AppLocalizations.of(context)!.startTripBtn,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15.sp)),
        onPressed: () => context
            .read<DriverActiveTripsCubit>()
            .updateTripState(widget.tripId, 'in_progress'),
      );
    } else if (status == 'completed') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r))),
        icon: Icon(Icons.done_all_rounded, color: Colors.white, size: 20.sp),
        label: Text(AppLocalizations.of(context)!.tripEndedBtn,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15.sp)),
        onPressed: null,
      );
    } else {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r))),
        icon:
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20.sp),
        label: Text(AppLocalizations.of(context)!.endTripBtn,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15.sp)),
        onPressed: () async {
          await context
              .read<DriverActiveTripsCubit>()
              .updateTripState(widget.tripId, 'completed');
          if (mounted) {
            final stars = await TripDialogsHelper.showRatingDialog(
                context: context,
                royalGreen: theme.extension<AppColorsExtension>()?.royalGreen ??
                    AppColors.royalGreen);
            if (stars != null && mounted) {}
            if (mounted) context.pop();
          }
        },
      );
    }
  }
}
