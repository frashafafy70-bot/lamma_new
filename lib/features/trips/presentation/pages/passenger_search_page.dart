import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🟢 الإضافة الخاصة بالاهتزاز
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../cubit/passenger/trip_search_cubit.dart';
import '../../cubit/passenger/trip_search_state.dart';
import '../../cubit/passenger/trip_booking_cubit.dart';
import '../../cubit/passenger/trip_booking_state.dart';

class PassengerSearchPage extends StatefulWidget {
  const PassengerSearchPage({super.key});

  @override
  State<PassengerSearchPage> createState() => _PassengerSearchPageState();
}

class _PassengerSearchPageState extends State<PassengerSearchPage> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocListener<TripBookingCubit, TripBookingState>(
        listener: (context, state) {
          if (state is TripBookingLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('جاري إرسال طلب الحجز...', style: TextStyle(fontFamily: 'Cairo')),
                backgroundColor: AppColors.primaryDark,
                duration: Duration(seconds: 1),
              ),
            );
          } else if (state is TripBookingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is TripBookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primaryDark,
            title: Text(
              'البحث عن رحلة سفر',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18.sp, color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                TextField(
                  controller: _fromController,
                  decoration: InputDecoration(
                    labelText: 'من مدينة',
                    labelStyle: const TextStyle(fontFamily: 'Cairo'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    prefixIcon: const Icon(Icons.my_location, color: AppColors.primaryDark),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: _toController,
                  decoration: InputDecoration(
                    labelText: 'إلى مدينة',
                    labelStyle: const TextStyle(fontFamily: 'Cairo'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    prefixIcon: const Icon(Icons.location_on, color: Colors.redAccent),
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    onPressed: () {
                      final from = _fromController.text.trim();
                      final to = _toController.text.trim();
                      
                      // 🟢 التحقق من عدم ترك الحقول فارغة
                      if (from.isEmpty || to.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('الرجاء إدخال مدينة الانطلاق والوصول', style: TextStyle(fontFamily: 'Cairo')),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }
                      
                      context.read<TripSearchCubit>().searchForRides(from, to);
                    },
                    child: Text(
                      'بحث عن الرحلات',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.accentGold),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: BlocBuilder<TripSearchCubit, TripSearchState>(
                    builder: (context, state) {
                      if (state is TripSearchLoading) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.accentGold));
                      } 
                      else if (state is TripSearchError) {
                        return Center(child: Text(state.message, style: TextStyle(fontFamily: 'Cairo', color: Colors.red, fontSize: 14.sp)));
                      } 
                      else if (state is TripSearchLoaded) {
                        final trips = state.trips;
                        if (trips.isEmpty) {
                          return Center(child: Text('لا توجد رحلات متاحة لهذا المسار حالياً.', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey)));
                        }

                        return ListView.builder(
                          itemCount: trips.length,
                          itemBuilder: (context, index) {
                            final trip = trips[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 12.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              child: ListTile(
                                title: Text('${trip.fromCity} ➔ ${trip.toCity}', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                subtitle: Text('السائق: ${trip.driverName ?? 'غير محدد'} | السعر: ${trip.price} ج.م', style: const TextStyle(fontFamily: 'Cairo')),
                                // 🟢 إضافة الأنيميشن والاهتزاز لزر الحجز
                                trailing: StatefulBuilder(
                                  builder: (context, setLocalState) {
                                    bool isPressed = false;
                                    return GestureDetector(
                                      onTapDown: (_) {
                                        HapticFeedback.lightImpact(); // الاهتزاز الخفيف
                                        setLocalState(() => isPressed = true);
                                      },
                                      onTapUp: (_) => setLocalState(() => isPressed = false),
                                      onTapCancel: () => setLocalState(() => isPressed = false),
                                      onTap: () {
                                        // تنفيذ الحجز
                                        context.read<TripBookingCubit>().bookSelectedTrip(
                                          tripId: trip.id ?? '',
                                          driverId: trip.driverId ?? '',
                                          passengerId: FirebaseAuth.instance.currentUser?.uid ?? '',
                                          requestedSeats: 1,
                                        );
                                      },
                                      child: AnimatedScale(
                                        scale: isPressed ? 0.90 : 1.0, // التصغير عند الضغط
                                        duration: const Duration(milliseconds: 100),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primaryDark,
                                            elevation: isPressed ? 0 : 4,
                                          ),
                                          onPressed: null, // تم التعطيل لأن GestureDetector هو المتحكم
                                          child: Text(
                                            'حجز',
                                            style: TextStyle(fontFamily: 'Cairo', color: AppColors.accentGold, fontSize: 12.sp),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return Center(child: Text('حدد مسار رحلتك واضغط بحث للبدء', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey)));
                    },
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