// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart';
import 'package:lamma_new/features/trips/data/models/trip_model.dart';
// 🟢 استيراد ملف الكيوبت الخاص بالرحلات النشطة للسائق
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';

class AddTravelBottomSheet extends StatefulWidget {
  final String userName;
  const AddTravelBottomSheet({super.key, required this.userName});

  @override
  State<AddTravelBottomSheet> createState() => _AddTravelBottomSheetState();
}

class _AddTravelBottomSheetState extends State<AddTravelBottomSheet> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController fromCtrl = TextEditingController();
  final TextEditingController toCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  DateTime? selectedDate;
  
  bool isFullCar = false;
  int availableSeats = 4;

  final Color royalGreen = const Color(0xFF1B4332);
  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);

  @override
  void dispose() {
    fromCtrl.dispose();
    toCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 16.h, bottom: 20.h),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w, 
                    height: 5.h, 
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10.r))
                  )
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Icon(Icons.directions_bus_filled_rounded, color: goldAccent, size: 28.sp),
                    SizedBox(width: 10.w),
                    Text('نشر رحلة سفر جديدة', style: TextStyle(fontFamily: 'Cairo', fontSize: 20.sp, fontWeight: FontWeight.bold, color: primaryNavy)),
                  ],
                ),
                SizedBox(height: 20.h),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isFullCar = false),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: !isFullCar ? royalGreen : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: !isFullCar ? royalGreen : Colors.grey.shade300)
                          ),
                          child: Center(child: Text('مقاعد فردية', style: TextStyle(color: !isFullCar ? Colors.white : primaryNavy, fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isFullCar = true),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: isFullCar ? royalGreen : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: isFullCar ? royalGreen : Colors.grey.shade300)
                          ),
                          child: Center(child: Text('سيارة كاملة', style: TextStyle(color: isFullCar ? Colors.white : primaryNavy, fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                if (!isFullCar) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10.r)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('عدد المقاعد المتاحة:', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: primaryNavy)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                              onPressed: () {
                                if (availableSeats > 1) setState(() => availableSeats--);
                              },
                            ),
                            Text('$availableSeats', style: TextStyle(fontFamily: 'Cairo', fontSize: 20.sp, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () {
                                if (availableSeats < 14) setState(() => availableSeats++);
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                TextFormField(
                  controller: fromCtrl,
                  validator: (value) => value == null || value.trim().isEmpty ? 'برجاء إدخال نقطة التحرك' : null,
                  decoration: InputDecoration(
                    labelText: 'نقطة التحرك (من)',
                    prefixIcon: const Icon(Icons.my_location_rounded, color: Colors.blueAccent),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r)),
                  ),
                ),
                SizedBox(height: 16.h),

                TextFormField(
                  controller: toCtrl,
                  validator: (value) => value == null || value.trim().isEmpty ? 'برجاء إدخال وجهة السفر' : null,
                  decoration: InputDecoration(
                    labelText: 'وجهة السفر (إلى)',
                    prefixIcon: const Icon(Icons.location_on_rounded, color: Colors.redAccent),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r)),
                  ),
                ),
                SizedBox(height: 16.h),

                InkWell(
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (pickedDate != null && context.mounted) {
                      TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (pickedTime != null) {
                        setState(() {
                          selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(15.r)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: Colors.orange),
                        SizedBox(width: 10.w),
                        Text(
                          selectedDate == null ? 'تاريخ ووقت التحرك' : DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(selectedDate!),
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: selectedDate == null ? Colors.grey.shade600 : primaryNavy),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.trim().isEmpty ? 'برجاء إدخال السعر' : null,
                  decoration: InputDecoration(
                    labelText: isFullCar ? 'سعر الرحلة بالكامل (ج.م)' : 'سعر المقعد الواحد (ج.م)',
                    prefixIcon: Icon(Icons.payments_rounded, color: royalGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r)),
                  ),
                ),
                SizedBox(height: 24.h),

                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r))),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return; 
                      
                      if (selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برجاء تحديد تاريخ ووقت الرحلة', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
                        return;
                      }

                      // 🟢 الفحص الجديد: هل السائق عنده رحلة نشطة؟
                      bool hasActiveTrip = await context.read<DriverActiveTripsCubit>().checkHasActiveTrip();
                      
                      if (!context.mounted) return;

                      if (hasActiveTrip) {
                        // لو عنده رحلة نشطة، نطلع رسالة ونمنع الإرسال
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('عفواً، لا يمكنك نشر رحلة جديدة لوجود رحلة نشطة بالفعل.', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), 
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          )
                        );
                        return; 
                      }
                      
                      // لو معندوش، نقفل الـ BottomSheet ونكمل الإرسال عادي
                      Navigator.pop(context); 
                      
                      final newTrip = TripModel(
                        isDriverPost: true,
                        driverId: FirebaseAuth.instance.currentUser?.uid,
                        driverName: widget.userName,
                        pickup: fromCtrl.text.trim(),
                        destination: toCtrl.text.trim(),
                        travelDate: selectedDate!,
                        price: priceCtrl.text.trim(),
                        tripCategory: 'سفر',
                        tripType: isFullCar ? 'full_car' : 'seats',
                        availableSeats: isFullCar ? '1' : availableSeats.toString(),
                        status: 'available',
                      );

                      // 🟢 توجيه الأمر لـ TripActionsCubit بدلاً من HomeCubit
                      context.read<TripActionsCubit>().addTravelTrip(trip: newTrip);
                    },
                    child: Text('نشر الرحلة', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: goldAccent)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}