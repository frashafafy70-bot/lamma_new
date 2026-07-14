// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import 'package:intl/intl.dart' hide TextDirection;
import 'package:audioplayers/audioplayers.dart'; 

import 'package:lamma_new/core/services/fcm_service.dart';
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/di/injection_container.dart'; // 🟢 إضافة الـ DI

import 'package:lamma_new/features/trips/data/repositories/driver_radar_repository_impl.dart'; 
import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart'; 
import 'package:lamma_new/features/trips/data/models/trip_model.dart'; 
import 'package:lamma_new/features/home/cubit/home_cubit.dart';
import 'package:lamma_new/features/trips/presentation/widgets/premium_tab_header.dart'; 

import '../../../cubit/driver/driver_radar_cubit.dart';
import '../../../cubit/driver/driver_radar_state.dart';

// 🟢 استدعاءات الكيوبت الجديد الخاص بالأكشنز (التفاوض)
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_state.dart';

class DriverRadarTab extends StatefulWidget {
  final bool showHeader;
  const DriverRadarTab({super.key, this.showHeader = false});

  @override
  State<DriverRadarTab> createState() => _DriverRadarTabState();
}

class _DriverRadarTabState extends State<DriverRadarTab> with AutomaticKeepAliveClientMixin {
  late final DriverRadarCubit _radarCubit;
  final AudioPlayer _alertAudioPlayer = AudioPlayer(); 
  final ScrollController _scrollController = ScrollController(); 
  int _oldTripsCount = 0; 

  @override
  bool get wantKeepAlive => true; 

  @override
  void initState() {
    super.initState();
    _radarCubit = DriverRadarCubit(DriverRadarRepositoryImpl());
    
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      if (mounted) {
        _radarCubit.fetchInitialRadarTrips();
      }
    });

    FCMService.subscribeToDriversRadar();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= (maxScroll - 200)) {
      _radarCubit.fetchMoreRadarTrips();
    }
  }

  @override
  void dispose() {
    _alertAudioPlayer.dispose(); 
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _radarCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 

    // 🟢 توفير الكيوبت للرادار والأكشنز معاً
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _radarCubit),
        BlocProvider(create: (context) => sl<TripActionsCubit>()),
      ],
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Column(
          children: [
            if (widget.showHeader)
              const PremiumTabHeader(title: 'الرادار'),
            
            Expanded(
              // 🟢 الاستماع لـ TripActionsCubit لعرض تحميل/نجاح/خطأ التفاوض
              child: BlocListener<TripActionsCubit, TripActionsState>(
                listener: (context, state) {
                  if (state is TripActionsLoading) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
                    );
                  } else if (state is TripActionsSuccess) {
                    Navigator.of(context).pop(); 
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.success));
                  } else if (state is TripActionsError) {
                    Navigator.of(context).pop(); 
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.error));
                  }
                },
                child: BlocConsumer<DriverRadarCubit, DriverRadarState>(
                  listener: (context, state) {
                    if (state is DriverRadarLoaded) {
                      if (state.radarTrips.length > _oldTripsCount && !state.isFetchingMore) {
                        _alertAudioPlayer.play(AssetSource('sounds/alert.mp3'), mode: PlayerMode.lowLatency);
                      }
                      _oldTripsCount = state.radarTrips.length;
                    }

                    if (state is DriverRadarActionSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم قبول الرحلة بنجاح! 🚗', style: TextStyle(fontFamily: 'Cairo')), 
                          backgroundColor: AppColors.success,
                        )
                      );
                      context.read<HomeCubit>().changeTab(2); 
                    } 
                    else if (state is DriverRadarActionError) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')), 
                          backgroundColor: AppColors.error,
                        )
                      );
                    }
                  },
                  buildWhen: (previous, current) => current is DriverRadarLoaded || current is DriverRadarLoading || current is DriverRadarError,
                  builder: (context, state) {
                    if (state is DriverRadarLoading || state is DriverRadarInitial) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: AppColors.accentGold),
                            SizedBox(height: 16.h),
                            Text('جاري جلب الطلبات...', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: AppColors.textMuted)),
                          ],
                        ),
                      );
                    }

                    if (state is DriverRadarError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(state.message, style: TextStyle(color: AppColors.error, fontFamily: 'Cairo', fontSize: 16.sp)),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: () => _radarCubit.fetchInitialRadarTrips(),
                              child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                            ),
                          ],
                        )
                      );
                    }

                    if (state is DriverRadarLoaded) {
                      final activeTrips = state.radarTrips;

                      if (activeTrips.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            await _radarCubit.fetchInitialRadarTrips();
                          },
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(25.w),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle, 
                                        color: AppColors.accentGold.withValues(alpha: 0.1),
                                      ),
                                      child: Icon(Icons.radar_rounded, size: 60.sp, color: AppColors.accentGold),
                                    ),
                                    SizedBox(height: 24.h),
                                    Text('لا توجد طلبات في محيطك حالياً', style: TextStyle(fontFamily: 'Cairo', fontSize: 18.sp, color: AppColors.textDark, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 8.h),
                                    Text('الرادار يعمل، اسحب للأسفل للتحديث', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          await _radarCubit.fetchInitialRadarTrips();
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.only(top: 16.h, left: 16.w, right: 16.w, bottom: 16.h), 
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: activeTrips.length + (state.isFetchingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            
                            if (index >= activeTrips.length) {
                              return Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Center(
                                  child: SizedBox(
                                    height: 24.w,
                                    width: 24.w,
                                    child: const CircularProgressIndicator(color: AppColors.accentGold, strokeWidth: 2),
                                  ),
                                ),
                              );
                            }

                            TripModel trip = activeTrips[index];
                            
                            String timeStr = 'الآن';
                            if (trip.createdAt != null) {
                              timeStr = DateFormat('hh:mm a').format(trip.createdAt!);
                            }

                            String displayPrice = trip.status == 'negotiating' && trip.negotiationPrice != null 
                                ? trip.negotiationPrice!
                                : trip.price ?? '0';

                            String clientName = trip.passengerName ?? 'عميل';
                            String pickupPoint = trip.pickup ?? 'موقع الانطلاق';
                            String dropoffPoint = trip.destination ?? 'وجهة الوصول';
                            
                            bool isOrdersTrip = trip.tripCategory == 'طلبات';

                            return Card(
                              elevation: 4,
                              shadowColor: Colors.black12,
                              margin: EdgeInsets.only(bottom: 16.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: AppColors.textDark.withValues(alpha: 0.1), 
                                              child: const Icon(Icons.person, color: AppColors.textDark)
                                            ),
                                            SizedBox(width: 10.w),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(clientName, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.textDark)),
                                                Row(
                                                  children: [
                                                    Text(timeStr, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: AppColors.textMuted.shade500)),
                                                    SizedBox(width: 6.w),
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                                      decoration: BoxDecoration(
                                                        color: isOrdersTrip ? AppColors.accentGold.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(4.r)
                                                      ),
                                                      child: Text(
                                                        trip.tripCategory ?? 'داخلي',
                                                        style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.bold, color: isOrdersTrip ? AppColors.textDark : Colors.blue.shade800),
                                                      ),
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20.r)),
                                          child: Text('$displayPrice ج.م', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 14.sp)),
                                        ),
                                      ],
                                    ),
                                    
                                    if (trip.status == 'negotiating') ...[
                                      SizedBox(height: 10.h),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                        decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8.r)),
                                        child: Row(
                                          children: [
                                            Icon(Icons.handshake_rounded, color: AppColors.warning, size: 16.sp),
                                            SizedBox(width: 8.w),
                                            Text(
                                              trip.lastNegotiator == 'driver' ? 'في انتظار رد العميل' : 'العميل يقترح هذا السعر', 
                                              style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: AppColors.textDark, fontWeight: FontWeight.bold)
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    
                                    Divider(height: 20.h, color: AppColors.dividerColor),
                                    
                                    if (isOrdersTrip) ...[
                                      Container(
                                        padding: EdgeInsets.all(12.w),
                                        decoration: BoxDecoration(
                                          color: AppColors.backgroundLight,
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(color: AppColors.dividerColor)
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.shopping_bag_rounded, color: AppColors.primaryDark, size: 18.sp),
                                                SizedBox(width: 6.w),
                                                Text('تفاصيل المشتريات:', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp, color: AppColors.primaryDark)),
                                              ],
                                            ),
                                            SizedBox(height: 8.h),
                                            
                                            if (trip.errandDetails != null && trip.errandDetails!.isNotEmpty)
                                              Text(trip.errandDetails!, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: AppColors.textDark)),
                                            
                                            if (trip.audioUrl != null && trip.audioUrl!.isNotEmpty) ...[
                                              SizedBox(height: 10.h),
                                              _OrderAudioPlayer(audioUrl: trip.audioUrl!),
                                            ],

                                            if (trip.errandCost != null && trip.errandCost!.isNotEmpty) ...[
                                              SizedBox(height: 8.h),
                                              Text('تكلفة المشتروات التقريبية: ${trip.errandCost} ج.م', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.error)),
                                            ]
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 12.h),
                                    ],

                                    Row(
                                      children: [
                                        const Icon(Icons.my_location_rounded, color: AppColors.info, size: 20),
                                        SizedBox(width: 8.w),
                                        Expanded(child: Text(pickupPoint, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                    SizedBox(height: 12.h),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, color: AppColors.error, size: 20),
                                        SizedBox(width: 8.w),
                                        Expanded(child: Text(dropoffPoint, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                    SizedBox(height: 20.h),
                                    
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.primaryDark,
                                              side: const BorderSide(color: AppColors.primaryDark),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                              padding: EdgeInsets.symmetric(vertical: 12.h),
                                            ),
                                            icon: Icon(Icons.handshake_rounded, size: 18.sp),
                                            label: Text('تفاوض', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold)),
                                            // 🟢 استخدام Helper التفاوض النظيف
                                            onPressed: () async {
                                              final offer = await TripDialogsHelper.showNegotiationDialog(
                                                context: context, 
                                                royalGreen: AppColors.royalGreen,
                                              );
                                              if (offer != null) {
                                                context.read<TripActionsCubit>().submitNegotiationOffer(
                                                  docId: trip.id!,
                                                  offerPrice: offer,
                                                  isDriver: true,
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primaryDark,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                              padding: EdgeInsets.symmetric(vertical: 12.h),
                                            ),
                                            icon: Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18.sp),
                                            label: Text('موافق بالسعر', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                                            onPressed: () {
                                              String? negotiatedPrice = trip.status == 'negotiating' ? displayPrice : null;
                                              context.read<DriverRadarCubit>().acceptTrip(trip.id!, negotiatedPrice: negotiatedPrice);
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderAudioPlayer extends StatefulWidget {
  final String audioUrl;
  const _OrderAudioPlayer({required this.audioUrl});

  @override
  State<_OrderAudioPlayer> createState() => _OrderAudioPlayerState();
}

class _OrderAudioPlayerState extends State<_OrderAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) await _player.pause();
      else {
        setState(() => _isLoading = true);
        await _player.play(UrlSource(widget.audioUrl));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("خطأ في تشغيل الصوت: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: CircleAvatar(
              radius: 16.r,
              backgroundColor: AppColors.accentGold,
              child: _isLoading 
                ? SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 20.sp),
            ),
          ),
          SizedBox(width: 10.w),
          Text('تسجيل صوتي للطلبات', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          SizedBox(width: 10.w),
          Icon(Icons.graphic_eq_rounded, color: AppColors.accentGold, size: 18.sp),
        ],
      ),
    );
  }
}