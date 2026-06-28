import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// استدعاء ملف الـ Dialogs اللي عملناه عشان نستخدم زرار المسح/الإلغاء
import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart';
// استدعاء صفحة التتبع (هنعملها في الخطوة الجاية)
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_trip_tracking_page.dart';

class DriverActiveTripsTab extends StatefulWidget {
  final TabController tabController;

  const DriverActiveTripsTab({
    super.key, 
    required this.tabController,
  });

  @override
  State<DriverActiveTripsTab> createState() => _DriverActiveTripsTabState();
}

class _DriverActiveTripsTabState extends State<DriverActiveTripsTab> {
  @override
  Widget build(BuildContext context) {
    final String currentDriverId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .where('driverId', isEqualTo: currentDriverId)
            // نجيب الرحلات اللي لسه شغالة أو تم الموافقة عليها فقط
            .where('status', whereIn: ['accepted', 'in_progress', 'negotiating']) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'حدث خطأ في جلب البيانات',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد رحلات نشطة حالياً',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final trips = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              var tripData = trips[index].data() as Map<String, dynamic>;
              String tripId = trips[index].id; // الـ ID بتاع الرحلة عشان نبعته لصفحة التتبع أو نمسح بيه
              
              String destination = tripData['destination'] ?? 'موقع محدد من الخريطة';
              String finalPrice = tripData['finalPrice']?.toString() ?? '0';

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الجزء الأول: الوجهة
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.redAccent, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              destination,
                              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // الجزء الثاني: السعر
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.green, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'السعر: $finalPrice جنيه',
                            style: const TextStyle(fontFamily: 'Cairo', color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
                      
                      // الجزء الثالث: أزرار التحكم (التفاصيل + الإلغاء)
                      Row(
                        children: [
                          // زرار الإلغاء
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                              onPressed: () {
                                // استدعاء دالة الإلغاء من الـ Helper اللي عملناه
                                TripDialogsHelper.showCancelTripDialog(
                                  context: context, 
                                  docId: tripId,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // زرار التفاصيل والتتبع
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF131E31), // كحلي
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: const Icon(Icons.map_rounded, size: 18),
                              label: const Text('التفاصيل والخريطة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                              onPressed: () {
                                // النقل لصفحة التتبع مع إرسال بيانات الرحلة
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DriverTripTrackingPage(
                                      tripId: tripId,
                                      destination: destination,
                                      price: finalPrice,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}