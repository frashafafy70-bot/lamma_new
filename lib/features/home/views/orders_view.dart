// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart'; 

class OrdersView extends StatelessWidget {
  final String activeRole;

  const OrdersView({super.key, required this.activeRole});

  final Color primaryNavy = const Color(0xFF0F172A);

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return 'تاريخ غير معروف';
    DateTime dt = ts.toDate();
    String amPm = dt.hour >= 12 ? 'م' : 'ص';
    int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    String minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}/${dt.month}/${dt.day} - $hour:$minute $amPm';
  }

  Future<void> _deleteOrder(BuildContext context, String docId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24.sp), 
            SizedBox(width: 8.w), 
            Text('حذف الطلب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18.sp))
          ],
        ),
        content: Text('هل أنت متأكد من حذف هذا الطلب نهائياً؟ لا يمكن التراجع عن هذا الإجراء.', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14.sp))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text('حذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
          ),
        ],
      )
    );

    if (confirm == true) {
      String collection = activeRole == 'lawyer' ? 'legal_requests' : 'trips';
      await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حذف الطلب بنجاح 🗑️', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: Colors.redAccent));
      }
    }
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> data, String docId) {
    String type = data.containsKey('tripCategory') ? '🚗 ${data['tripCategory']}' : (data['serviceType'] ?? 'طلب خدمة');
    String status = data['status'] ?? 'pending';
    String statusText = status == 'accepted' ? 'تم القبول ✅' : 'قيد الانتظار/التفاوض ⏳';
    Timestamp? ts = data['createdAt'] ?? data['timestamp'];
    String timeStr = _formatTimestamp(ts);
    
    GeoPoint? pickup = data['pickupLocation'];
    GeoPoint? destination = data['destinationLocation'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.r))),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: EdgeInsets.all(24.w),
            height: MediaQuery.of(context).size.height * 0.75, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40.w, height: 5.h, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10.r)))),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(type, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: primaryNavy, fontFamily: 'Cairo')),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(color: status == 'accepted' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
                      child: Text(statusText, style: TextStyle(color: status == 'accepted' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 13.sp, fontFamily: 'Cairo')),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 18.sp, color: Colors.grey),
                    SizedBox(width: 8.w),
                    Text(timeStr, style: TextStyle(color: Colors.grey.shade700, fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 14.sp)),
                  ],
                ),
                Divider(height: 30.h),
                Text('التفاصيل:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, fontFamily: 'Cairo')),
                SizedBox(height: 4.h),
                Text(data['details'] ?? data['errandDetails'] ?? data['destination'] ?? 'لا توجد تفاصيل إضافية مسجلة', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
                SizedBox(height: 15.h),
                if (data.containsKey('suggestedPrice') && data['suggestedPrice'].toString().isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.monetization_on_rounded, color: Colors.green, size: 24.sp),
                      SizedBox(width: 8.w),
                      Text('السعر المقترح: ${data['suggestedPrice']} جنيه', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontFamily: 'Cairo', fontSize: 15.sp)),
                    ],
                  ),
                SizedBox(height: 20.h),
                if (pickup != null) ...[
                  Text('📍 مسار الرحلة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, fontFamily: 'Cairo')),
                  SizedBox(height: 10.h),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.r), border: Border.all(color: Colors.grey.shade300), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15.r),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(target: LatLng(pickup.latitude, pickup.longitude), zoom: 14),
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          markers: {
                            Marker(markerId: const MarkerId('pickup'), position: LatLng(pickup.latitude, pickup.longitude), infoWindow: const InfoWindow(title: 'مكان التحرك'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)),
                            if (destination != null)
                              Marker(markerId: const MarkerId('destination'), position: LatLng(destination.latitude, destination.longitude), infoWindow: const InfoWindow(title: 'وجهة الوصول'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
                          },
                          onMapCreated: (GoogleMapController controller) {
                            if (destination != null) {
                              double minLat = pickup.latitude < destination.latitude ? pickup.latitude : destination.latitude;
                              double maxLat = pickup.latitude > destination.latitude ? pickup.latitude : destination.latitude;
                              double minLng = pickup.longitude < destination.longitude ? pickup.longitude : destination.longitude;
                              double maxLng = pickup.longitude > destination.longitude ? pickup.longitude : destination.longitude;
                              
                              LatLngBounds bounds = LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
                              Future.delayed(const Duration(milliseconds: 500), () {
                                controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  )
                ] else ...[
                  const Spacer(),
                ],
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, padding: EdgeInsets.symmetric(vertical: 14.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('إغلاق التفاصيل', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp))
                  )
                )
              ]
            )
          )
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    
    Stream<QuerySnapshot> ordersStream;
    if (activeRole == 'lawyer') {
      ordersStream = FirebaseFirestore.instance.collection('legal_requests').orderBy('timestamp', descending: true).snapshots();
    } else {
      ordersStream = FirebaseFirestore.instance.collection('trips')
        .where('passengerId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'negotiating', 'accepted'])
        .snapshots();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Container(
            width: double.infinity, padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20.h, bottom: 20.h),
            decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.vertical(bottom: Radius.circular(25.r))),
            child: Text(
              activeRole == 'lawyer' ? 'طلبات العملاء الواردة ⚖️' : 'متابعة طلباتي النشطة 🚀', 
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ordersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 80.sp, color: Colors.grey.shade300),
                        SizedBox(height: 16.h),
                        Text('ليس لديك أي طلبات نشطة حالية.', style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ],
                    ),
                  );
                }
                
                var docs = snapshot.data!.docs;
                if (activeRole != 'lawyer') {
                  docs.sort((a, b) {
                    var aData = a.data() as Map<String, dynamic>?;
                    var bData = b.data() as Map<String, dynamic>?;
                    Timestamp? aTs = aData?['createdAt'] ?? aData?['timestamp'];
                    Timestamp? bTs = bData?['createdAt'] ?? bData?['timestamp'];
                    if (aTs == null && bTs == null) return 0;
                    if (aTs == null) return 1;
                    if (bTs == null) return -1;
                    return bTs.compareTo(aTs);
                  });
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    
                    String type = data.containsKey('tripCategory') ? '🚗 ${data['tripCategory']}' : (data['serviceType'] ?? 'طلب خدمة');
                    String status = data['status'] ?? 'pending';
                    String details = data.containsKey('destination') ? 'إلى: ${data['destination']}' : (data['details'] ?? '');
                    String clientName = data['clientName'] ?? 'عميل غير معروف';
                    
                    Timestamp? ts = data['createdAt'] ?? data['timestamp'];
                    String timeStr = _formatTimestamp(ts);
                    
                    return Card(
                      elevation: 3, margin: EdgeInsets.only(bottom: 12.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                      child: InkWell(
                        onTap: () => _showOrderDetails(context, data, doc.id),
                        borderRadius: BorderRadius.circular(15.r),
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(type, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: primaryNavy, fontFamily: 'Cairo'))),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(color: status == 'accepted' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
                                    child: Text(status == 'accepted' ? 'تم القبول' : 'قيد الانتظار', style: TextStyle(color: status == 'accepted' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12.sp, fontFamily: 'Cairo')),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24.sp),
                                    tooltip: 'مسح الطلب',
                                    onPressed: () => _deleteOrder(context, doc.id),
                                  )
                                ],
                              ),
                              if (activeRole == 'lawyer') ...[
                                SizedBox(height: 4.h),
                                Text('مُقدم الطلب: $clientName', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Cairo', fontSize: 14.sp)),
                              ],
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(details, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700, fontFamily: 'Cairo', fontSize: 13.sp))),
                                  Text(timeStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 11.sp, fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}