import 'package:flutter/material.dart';
import 'package:lamma_new/features/trips/presentation/pages/trip_chat_page.dart';
import 'package:lamma_new/features/trips/presentation/widgets/trip_map.dart';
import 'package:lamma_new/features/trips/utils/trip_dialogs_helper.dart';

// ركز هنا: ده الاستدعاء بتاع صفحة الشات اللي ظبطناه المرة اللي فاتت

// هنا هنستدعي ملف الخريطة بتاعك (هنعمله باللمبة الصفرا لو جاب خط أحمر)

class DriverTripTrackingPage extends StatelessWidget {
  final String tripId;
  final String destination;
  final String price;

  const DriverTripTrackingPage({
    super.key, 
    required this.tripId,
    required this.destination,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع الرحلة', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF131E31),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. الخريطة الحقيقية (تم استبدال المربع الرمادي)
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              // استدعاء ويدجت الخريطة اللي موجودة في مشروعك
              child: TripMap(
                // لو ملف الـ TripMap بتاعك بيحتاج بيانات (زي الـ tripId عشان يجيب المسار)، تقدر تمررها هنا
                // tripId: tripId, 
              ),
            ),
          ),

          // 2. كارت معلومات الرحلة في الأسفل
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الوجهة: $destination', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('السعر المتفق عليه: $price جنيه', style: const TextStyle(fontFamily: 'Cairo', color: Colors.green, fontWeight: FontWeight.bold)),
                const Divider(height: 24),
                
                Row(
                  children: [
                    // زرار الشات 
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.chat_rounded, color: Colors.white),
                        label: const Text('محادثة العميل', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TripChatPage(
                                tripId: tripId, 
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // زرار إنهاء الرحلة
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                        label: const Text('إنهاء الرحلة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                        onPressed: () {
                          TripDialogsHelper.showRatingDialog(
                            context: context, 
                            docId: tripId, 
                            royalGreen: Colors.green,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}