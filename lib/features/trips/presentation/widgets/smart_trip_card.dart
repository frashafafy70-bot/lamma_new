import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:audioplayers/audioplayers.dart'; // 🟢 استدعاء مشغل الصوت
import 'package:lamma_new/features/trips/data/models/trip_model.dart';

import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_state.dart';

class SmartTripCard extends StatefulWidget {
  final TripModel trip;
  final bool isDriver; 
  final String currentUserId;
  final VoidCallback onChatPressed;

  const SmartTripCard({
    super.key,
    required this.trip,
    required this.isDriver,
    required this.currentUserId,
    required this.onChatPressed,
  });

  @override
  State<SmartTripCard> createState() => _SmartTripCardState();
}

class _SmartTripCardState extends State<SmartTripCard> {
  final Color primaryGreen = const Color(0xFF1A3B2A);
  final Color accentGold = const Color(0xFFD4AF37);
  final TextEditingController _counterOfferController = TextEditingController();

  // 🟢 متغيرات مشغل الصوت
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    // لما الريكورد يخلص، نرجع الزرار لشكله الطبيعي
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _counterOfferController.dispose();
    _audioPlayer.dispose(); // 🟢 إغلاق المشغل لتوفير الذاكرة
    super.dispose();
  }

  String _formatTripDate(dynamic createdAt) {
    if (createdAt == null) return 'الوقت غير متاح';
    DateTime date;
    if (createdAt is Timestamp) {
      date = createdAt.toDate();
    } else if (createdAt is String) {
      date = DateTime.tryParse(createdAt) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }
    return DateFormat('dd MMM yyyy, hh:mm a', 'ar').format(date);
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('مسح الطلب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18.sp)),
        content: Text('هل أنت متأكد من إزالة هذا الطلب من القائمة عندك؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('تراجع', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14.sp))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), 
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TripActionsCubit>().deleteTripFromList(widget.trip, widget.isDriver);
            }, 
            child: Text('نعم، امسح', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 14.sp))
          ),
        ],
      )
    );
  }

  // 🟢 لوجيك تشغيل وإيقاف الصوت
  Future<void> _toggleAudio(String url) async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isLoadingAudio = true);
      try {
        await _audioPlayer.play(UrlSource(url));
        setState(() {
          _isPlaying = true;
          _isLoadingAudio = false;
        });
      } catch (e) {
        setState(() => _isLoadingAudio = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ في تشغيل الصوت', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMyTurnToNegotiate = widget.trip.status == 'negotiating' && 
       ((widget.isDriver && widget.trip.lastNegotiator == 'passenger') || 
        (!widget.isDriver && widget.trip.lastNegotiator == 'driver'));

    bool isWaitingForOther = widget.trip.status == 'negotiating' && !isMyTurnToNegotiate;
    String displayPrice = widget.trip.finalPrice ?? widget.trip.negotiationPrice ?? widget.trip.price ?? widget.trip.suggestedPrice ?? 'غير محدد';
    String? audioUrl = widget.trip.audioUrl;

    return BlocProvider(
      create: (context) => TripActionsCubit(),
      child: BlocConsumer<TripActionsCubit, TripActionsState>(
        listener: (context, state) {
          if (state is TripActionsError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error, style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
          } else if (state is TripActionsSuccess) {
            if (state.action == 'accept') {
              widget.onChatPressed(); 
            } else if (state.action == 'delete') {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم مسح الطلب', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
            }
          }
        },
        builder: (context, state) {
          bool isProcessing = state is TripActionsLoading;

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(widget.trip.vehicleType == 'موتوسيكل' ? Icons.motorcycle : Icons.directions_car, color: primaryGreen, size: 22.sp),
                          SizedBox(width: 8.w),
                          Text(
                            '${widget.trip.tripCategory} (${widget.trip.vehicleType})',
                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15.sp, color: primaryGreen),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildStatusBadge(),
                          SizedBox(width: 8.w),
                          InkWell(
                            onTap: () => _showDeleteDialog(context),
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                              child: Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20.sp),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: Colors.grey.shade500, size: 18.sp),
                          SizedBox(width: 6.w),
                          Text(
                            _formatTripDate(widget.trip.createdAt),
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      // 🟢 تم إضافة من : 
                      _buildLocationRow(Icons.my_location, Colors.green, 'من : ', widget.trip.pickup ?? 'غير محدد'),
                      Padding(
                        padding: EdgeInsets.only(right: 10.w),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(height: 20.h, width: 2.w, color: Colors.grey.shade300),
                        ),
                      ),
                      // 🟢 تم إضافة إلى :
                      _buildLocationRow(Icons.location_on, Colors.red, 'إلى : ', widget.trip.destination ?? 'غير محدد'),

                      if (audioUrl != null && audioUrl.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: primaryGreen,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.mic, color: accentGold, size: 20.sp),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text('رسالة صوتية من العميل', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 13.sp)),
                              ),
                              InkWell(
                                onTap: () => _toggleAudio(audioUrl),
                                child: CircleAvatar(
                                  radius: 18.r,
                                  backgroundColor: accentGold,
                                  // 🟢 عرض علامة التحميل أو زرار التشغيل/الإيقاف
                                  child: _isLoadingAudio 
                                      ? SizedBox(width: 20.sp, height: 20.sp, child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2))
                                      : Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: primaryGreen, size: 24.sp),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Divider(height: 1, color: Colors.grey.shade200),

                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.trip.status == 'accepted' ? 'السعر النهائي:' : 'السعر المطروح:',
                            style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade700, fontSize: 14.sp, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$displayPrice ج.م', 
                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18.sp, color: accentGold),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      if (isProcessing)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        if (widget.trip.status == 'pending') ...[
                          if (widget.isDriver) ...[
                            Row(
                              children: [
                                Expanded(child: _buildPriceInput('سعر عرضك...', _counterOfferController)),
                                SizedBox(width: 8.w),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                                  onPressed: () => context.read<TripActionsCubit>().sendOffer(widget.trip, _counterOfferController.text, widget.isDriver, widget.currentUserId),
                                  child: Text('إرسال', style: TextStyle(fontFamily: 'Cairo', color: accentGold, fontWeight: FontWeight.bold)),
                                )
                              ],
                            )
                          ] else ...[
                            Center(child: Text('جاري البحث عن كباتن...', style: TextStyle(fontFamily: 'Cairo', color: Colors.orange, fontSize: 14.sp, fontWeight: FontWeight.bold)))
                          ]
                        ],

                        if (widget.trip.status == 'negotiating') ...[
                          if (isWaitingForOther) ...[
                            Center(
                              child: Text(
                                'في انتظار رد ${widget.isDriver ? "العميل" : "الكابتن"}...',
                                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade600, fontSize: 14.sp, fontWeight: FontWeight.bold),
                              ),
                            )
                          ] else if (isMyTurnToNegotiate) ...[
                            Row(
                              children: [
                                Expanded(child: _buildActionButton('موافق', primaryGreen, Colors.white, () => context.read<TripActionsCubit>().acceptOffer(widget.trip, widget.isDriver, widget.currentUserId))),
                                SizedBox(width: 8.w),
                                Expanded(child: _buildActionButton('رفض', Colors.white, Colors.red, () => context.read<TripActionsCubit>().rejectOrCancelTrip(widget.trip, widget.isDriver), isOutlined: true)),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Expanded(child: _buildPriceInput('أو ضع سعراً مختلفاً...', _counterOfferController)),
                                SizedBox(width: 8.w),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: accentGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                                  onPressed: () => context.read<TripActionsCubit>().sendOffer(widget.trip, _counterOfferController.text, widget.isDriver, widget.currentUserId),
                                  child: Text('تفاوض', style: TextStyle(fontFamily: 'Cairo', color: primaryGreen, fontWeight: FontWeight.bold)),
                                )
                              ],
                            )
                          ]
                        ],

                        if (widget.trip.status == 'accepted') ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                                  label: Text('فتح المحادثة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp)),
                                  onPressed: widget.onChatPressed,
                                ),
                              ),
                              if (widget.isDriver) ...[
                                SizedBox(width: 12.w),
                                Expanded(child: _buildActionButton('إنهاء الرحلة', primaryGreen, accentGold, () {})),
                              ]
                            ],
                          )
                        ],
                      ]
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // 🟢 تعديل الدالة لاستقبال كلمة "من" و "إلى"
  Widget _buildLocationRow(IconData icon, Color iconColor, String prefix, String text) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20.sp),
        SizedBox(width: 8.w),
        Text(prefix, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
        Expanded(child: Text(text, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.black87, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor; Color textColor; String text;
    switch (widget.trip.status) {
      case 'accepted': bgColor = Colors.green.shade100; textColor = Colors.green.shade800; text = 'تم القبول'; break;
      case 'negotiating': bgColor = Colors.orange.shade100; textColor = Colors.orange.shade800; text = 'تفاوض'; break;
      case 'cancelled': bgColor = Colors.red.shade100; textColor = Colors.red.shade800; text = 'ملغاة'; break;
      default: bgColor = Colors.blue.shade100; textColor = Colors.blue.shade800; text = 'جديد';
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20.r)),
      child: Text(text, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold, color: textColor)),
    );
  }

  Widget _buildPriceInput(String hint, TextEditingController controller) {
    return SizedBox(
      height: 45.h,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: primaryGreen)),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color bgColor, Color textColor, VoidCallback onTap, {bool isOutlined = false}) {
    return SizedBox(
      height: 45.h,
      child: isOutlined
          ? OutlinedButton(style: OutlinedButton.styleFrom(side: BorderSide(color: textColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))), onPressed: onTap, child: Text(text, style: TextStyle(fontFamily: 'Cairo', color: textColor, fontWeight: FontWeight.bold, fontSize: 14.sp)))
          : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: bgColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), elevation: 0), onPressed: onTap, child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14.sp))),
    );
  }
}