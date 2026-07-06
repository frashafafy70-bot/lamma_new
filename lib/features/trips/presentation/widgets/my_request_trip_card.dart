// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import 'dart:math' as math;

import '../../cubit/passenger/passenger_my_requests_cubit.dart';
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';
import 'package:lamma_new/features/trips/presentation/widgets/trip_map.dart'; 

class MyRequestTripCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final Color royalGreen;

  const MyRequestTripCard({
    super.key,
    required this.docId,
    required this.data,
    required this.royalGreen,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.grey;
      case 'available': return Colors.grey; 
      case 'negotiating': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'in_progress': return Colors.indigo; 
      case 'completed': return Colors.green;
      case 'canceled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'في انتظار سائق';
      case 'available': return 'في انتظار سائق'; 
      case 'negotiating': return 'جاري التفاوض';
      case 'accepted': return 'تم القبول';
      case 'in_progress': return 'الرحلة جارية'; 
      case 'completed': return 'مكتملة';
      case 'canceled': return 'ملغية';
      default: return status;
    }
  }

  Future<void> _confirmDeleteRequest(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18.sp)),
        content: Text('هل أنت متأكد أنك تريد حذف هذا الطلب نهائياً من القائمة؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14.sp))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<PassengerMyRequestsCubit>().deleteRequest(docId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إخفاء الطلب بنجاح ✅', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحذف', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: Colors.red));
        }
      }
    }
  }

  // 🟢 هنا التعديل: الدالة بتاخد currentType وبتباصيه
  void _showNegotiationDialog(BuildContext context, String currentType) {
    TextEditingController offerCtrl = TextEditingController();
    String typeLabel = currentType == 'full_car' ? 'السيارة كاملة' : 'المقعد الفردي';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('التفاوض على سعر $typeLabel', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp)), 
        content: TextField(
          controller: offerCtrl, 
          keyboardType: TextInputType.number,
          style: TextStyle(color: Colors.black, fontFamily: 'Cairo', fontSize: 14.sp),
          decoration: InputDecoration(
            labelText: 'سعر العرض الجديد', 
            labelStyle: TextStyle(fontSize: 14.sp),
            suffixText: 'جنيه', 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r))
          )
        ), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14.sp))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: royalGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
            onPressed: () async { 
              if (offerCtrl.text.trim().isEmpty) return;
              try {
                // 🟢 هنا باصينا الـ currentType عشان الدالة متضربش إيرور (3 قيم)
                await context.read<PassengerMyRequestsCubit>().negotiateTrip(docId, offerCtrl.text.trim(), currentType);
                if (ctx.mounted) Navigator.pop(ctx); 
              } catch (e) {
                 debugPrint('خطأ أثناء إرسال العرض: $e');
              }
            }, 
            child: Text('إرسال العرض', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp))
          )
        ]
      )
    );
  }

  Widget _buildDriverInfoCard() {
    String driverName = data['driverName'] ?? 'سائق لَمّة';
    String vehicleType = data['vehicleType'] ?? 'مركبة';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: royalGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: royalGreen.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: royalGreen.withValues(alpha: 0.1),
            child: Icon(Icons.person_outline_rounded, color: royalGreen, size: 26.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driverName, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.black87)),
                Text(vehicleType, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)]
            ),
            child: Icon(Icons.star_rounded, color: Colors.amber, size: 20.sp),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String status = data['status'] ?? 'pending';
    String category = data['tripCategory'] ?? 'داخلي';
    String currentType = data['tripType'] ?? 'seat'; 
    bool isErrand = category == 'طلبات';
    bool isNegotiating = status == 'negotiating';
    
    bool isWaitingForDriver = status == 'pending' || status == 'available' || status == 'searching';
    bool isAcceptedOrInProgress = status == 'accepted' || status == 'in_progress';

    String formattedDate = '';
    if (data.containsKey('createdAt') && data['createdAt'] != null) {
      Timestamp timestamp = data['createdAt'];
      DateTime dt = timestamp.toDate();
      formattedDate = "${dt.day}/${dt.month}/${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }

    Set<Marker> trackingMarkers = {};
    LatLng? mapCenter;

    if (data.containsKey('pickupLocation') && data['pickupLocation'] is GeoPoint) {
      GeoPoint p = data['pickupLocation'];
      mapCenter = LatLng(p.latitude, p.longitude);
      trackingMarkers.add(Marker(
        markerId: const MarkerId('pickup_mini'),
        position: mapCenter,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    if (data.containsKey('destinationLocation') && data['destinationLocation'] is GeoPoint) {
      GeoPoint d = data['destinationLocation'];
      LatLng destLatLng = LatLng(d.latitude, d.longitude);
      mapCenter ??= destLatLng; 
      trackingMarkers.add(Marker(
        markerId: const MarkerId('dest_mini'),
        position: destLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    if (isAcceptedOrInProgress && data.containsKey('driverLocation') && data['driverLocation'] is GeoPoint) {
      GeoPoint drLoc = data['driverLocation'];
      trackingMarkers.add(Marker(
        markerId: const MarkerId('live_driver_mini'),
        position: LatLng(drLoc.latitude, drLoc.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16.h),
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(color: royalGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
                      child: Row(
                        children: [
                          Icon(isErrand ? Icons.shopping_bag_rounded : Icons.local_taxi_rounded, color: royalGreen, size: 16.sp),
                          SizedBox(width: 6.w),
                          Text(category, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: royalGreen, fontSize: 12.sp)),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(color: _getStatusColor(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
                      child: Text(_getStatusLabel(status), style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12.sp)),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _confirmDeleteRequest(context),
                  borderRadius: BorderRadius.circular(50.r),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20.sp),
                  ),
                ),
              ],
            ),
            Divider(height: 24.h),
            
            if (isErrand) ...[
              Text('الطلبات: ${data['errandDetails'] ?? ''}', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
              SizedBox(height: 8.h),
              Text('التكلفة التقريبية: ${data['errandCost'] ?? '0'} ج', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade700, fontSize: 13.sp)),
              SizedBox(height: 4.h),
              Text('مكان الشراء: ${data['pickup'] ?? ''}', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade700, fontSize: 13.sp)),
              SizedBox(height: 4.h),
              Text('مكان التسليم: ${data['destination'] ?? ''}', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade700, fontSize: 13.sp)),
            ] else ...[
              Text('من: ${data['pickup'] ?? ''}', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
              SizedBox(height: 4.h),
              Text('إلى: ${data['destination'] ?? ''}', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
              SizedBox(height: 8.h),
              Text('نوع المركبة: ${data['vehicleType'] ?? 'سيارة'}', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade700, fontSize: 13.sp)),
            ],
            
            if (formattedDate.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14.sp, color: Colors.grey.shade500),
                  SizedBox(width: 4.w),
                  Text(formattedDate, style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade500, fontSize: 11.sp, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            SizedBox(height: 16.h),

            if (mapCenter != null) ...[
              SizedBox(
                height: 130.h,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      IgnorePointer( 
                        child: GoogleMap(
                          liteModeEnabled: true, 
                          initialCameraPosition: CameraPosition(
                            target: mapCenter,
                            zoom: 12.5, 
                          ),
                          markers: trackingMarkers,
                          myLocationEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          compassEnabled: false,
                        ),
                      ),
                      if (isWaitingForDriver)
                        IgnorePointer(
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.1),
                            child: _LammaPingPongRadar(
                              color: royalGreen,
                              size: 100.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],

            if (isAcceptedOrInProgress) _buildDriverInfoCard(),

            if (isNegotiating)
              if (data['lastNegotiator'] == 'passenger')
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8.r)),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.orange, size: 18.sp),
                      SizedBox(width: 8.w),
                      Expanded(child: Text('في انتظار رد السائق على عرضك (${data['negotiationPrice']} ج)', style: TextStyle(color: Colors.orange, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp))),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8.r)),
                      child: Text('عرض من السائق ${data['driverName'] ?? ''}: ${data['negotiationPrice']} ج', style: TextStyle(color: Colors.blue, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: royalGreen, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), onPressed: () async => await context.read<PassengerMyRequestsCubit>().acceptOffer(docId, data['negotiationPrice'].toString()), child: Text('موافق', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 13.sp)))),
                        SizedBox(width: 8.w),
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), onPressed: () => _showNegotiationDialog(context, currentType), child: Text('تفاوض', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 13.sp)))),
                        SizedBox(width: 8.w),
                        Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), onPressed: () async => await context.read<PassengerMyRequestsCubit>().rejectTrip(docId), child: Text('رفض', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 13.sp)))),
                      ],
                    )
                  ],
                )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isErrand ? 'سعرك المقترح: ${data['suggestedPrice'] ?? data['finalPrice'] ?? '0'} ج' : 'السعر المقترح: ${data['suggestedPrice'] ?? data['finalPrice'] ?? '0'} ج',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14.sp),
                      ),
                    ],
                  ),
                  
                  if (isAcceptedOrInProgress) ...[
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600, 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                              elevation: 0,
                            ), 
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => TripChatPage(tripId: docId)),
                              );
                            }, 
                            icon: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16.sp), 
                            label: Text('المحادثة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp))
                          )
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade600, 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                              elevation: 0,
                            ), 
                            onPressed: () {
                              LatLng? pickup;
                              if (data['pickupLocation'] is GeoPoint) {
                                pickup = LatLng((data['pickupLocation'] as GeoPoint).latitude, (data['pickupLocation'] as GeoPoint).longitude);
                              }
                              LatLng? dropoff;
                              if (data['destinationLocation'] is GeoPoint) {
                                dropoff = LatLng((data['destinationLocation'] as GeoPoint).latitude, (data['destinationLocation'] as GeoPoint).longitude);
                              }
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TripMap(
                                    isTrackingMode: true,
                                    pickupPoint: pickup,
                                    dropoffPoint: dropoff,
                                  )
                                ),
                              );
                            }, 
                            icon: Icon(Icons.map_rounded, color: Colors.white, size: 16.sp), 
                            label: Text('تتبع الرحلة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp))
                          )
                        ),
                      ],
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LammaPingPongRadar extends StatefulWidget {
  final Color color;
  final double size;

  const _LammaPingPongRadar({
    this.color = const Color(0xFF1B4332), 
    this.size = 60.0,
  });

  @override
  State<_LammaPingPongRadar> createState() => _LammaPingPongRadarState();
}

class _LammaPingPongRadarState extends State<_LammaPingPongRadar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), 
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadarPainter(
        animation: _controller,
        color: widget.color,
      ),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_rounded, 
              color: widget.color,
              size: widget.size * 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _RadarPainter({required this.animation, required this.color}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);
    for (int wave = 3; wave >= 0; wave--) {
      circle(canvas, rect, wave + animation.value);
    }
  }

  void circle(Canvas canvas, Rect rect, double value) {
    final double opacity = (1.0 - (value / 4.0)).clamp(0.0, 1.0);
    final Color waveColor = color.withValues(alpha: opacity * 0.6); 
    final Paint paint = Paint()..color = waveColor;
    final double radius = math.min(rect.width, rect.height) / 2.0;
    canvas.drawCircle(rect.center, radius * (value / 4.0), paint);
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) => true;
}