import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:auto_route/auto_route.dart'; 
// 🟢 استدعاء التخزين المحلي لتهيئة الـ Repository
import 'package:shared_preferences/shared_preferences.dart'; 

import '../../data/repositories/trip_booking_repository_impl.dart';
import '../../cubit/passenger/trip_booking_cubit.dart';
import '../../cubit/passenger/trip_booking_state.dart';
import '../../data/models/trip_model.dart';

@RoutePage() 
class PassengerSearchPage extends StatelessWidget {
  const PassengerSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🟢 استخدام FutureBuilder لتهيئة SharedPreferences قبل بناء الشاشة
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF1B4332)),
            ),
          );
        }
        
        if (snapshot.hasData) {
          return BlocProvider(
            create: (context) => TripBookingCubit(
              // 🟢 تمرير الـ prefs هنا ليعمل الكاش بشكل سليم
              TripBookingRepositoryImpl(prefs: snapshot.data!), 
            ),
            child: const _PassengerSearchView(),
          );
        }

        return const Scaffold(
          body: Center(
            child: Text(
              'حدث خطأ في تحميل البيانات الأساسية', 
              style: TextStyle(fontFamily: 'Cairo')
            ),
          ),
        );
      },
    );
  }
}

class _PassengerSearchView extends StatefulWidget {
  const _PassengerSearchView();

  @override
  State<_PassengerSearchView> createState() => _PassengerSearchViewState();
}

class _PassengerSearchViewState extends State<_PassengerSearchView> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  
  final Color royalGreen = const Color(0xFF1B4332);
  final Color darkSlate = const Color(0xFF0F172A);

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  // 🟢 دالة موحدة لعرض التنبيهات بشكل أنيق وعائم
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 20.h, left: 20.w, right: 20.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onSearch() {
    FocusScope.of(context).unfocus();
    
    final from = _fromController.text.trim();
    final to = _toController.text.trim();

    // 🟢 التحقق من المدخلات (Validation) بصرامة
    if (from.isEmpty) {
      _showSnackBar('برجاء تحديد مدينة الانطلاق', Colors.orange.shade800);
      return;
    }
    if (to.isEmpty) {
      _showSnackBar('برجاء تحديد مدينة الوصول', Colors.orange.shade800);
      return;
    }

    context.read<TripBookingCubit>().searchForRides(from, to);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('ابحث عن رحلة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: royalGreen, fontSize: 18.sp)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: royalGreen),
          onPressed: () => context.router.maybePop(), 
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20.r), bottomRight: Radius.circular(20.r)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: Column(
              children: [
                _buildTextField(_fromController, 'من (مدينة الانطلاق)', Icons.my_location_rounded),
                SizedBox(height: 12.h),
                _buildTextField(_toController, 'إلى (مدينة الوصول)', Icons.location_on_rounded, iconColor: Colors.redAccent),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: BlocBuilder<TripBookingCubit, TripBookingState>(
                    builder: (context, state) {
                      bool isLoading = state is TripSearchLoading;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: royalGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        // 🟢 تعطيل الزر أثناء البحث لمنع الطلبات المكررة
                        onPressed: isLoading ? null : _onSearch,
                        child: isLoading
                            ? SizedBox(height: 24.h, width: 24.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text('بحث الآن', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: BlocConsumer<TripBookingCubit, TripBookingState>(
              listener: (context, state) {
                if (state is TripBookingSuccess) {
                  _showSnackBar(state.message, Colors.green);
                } else if (state is TripBookingError) {
                  _showSnackBar(state.message, Colors.red.shade700);
                }
              },
              builder: (context, state) {
                if (state is TripSearchLoading || state is TripBookingLoading) {
                  return Center(child: CircularProgressIndicator(color: royalGreen));
                } 
                else if (state is TripSearchError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Text(
                        state.message, 
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Cairo', color: Colors.red.shade700, fontSize: 16.sp, fontWeight: FontWeight.w600)
                      ),
                    )
                  );
                } 
                else if (state is TripSearchLoaded) {
                  if (state.trips.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: state.trips.length,
                    itemBuilder: (context, index) => _buildTripCard(context, state.trips[index]),
                  );
                }
                return _buildInitialState();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {Color? iconColor}) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade500, fontSize: 14.sp),
        prefixIcon: Icon(icon, color: iconColor ?? royalGreen),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 80.sp, color: Colors.grey.shade300),
          SizedBox(height: 16.h),
          Text('حدد مسارك وابحث عن رحلتك', style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_filled_rounded, size: 80.sp, color: Colors.grey.shade300),
          SizedBox(height: 16.h),
          Text('لا توجد رحلات متاحة لهذا المسار', style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, TripModel trip) {
    int maxSeats = int.tryParse(trip.availableSeats ?? '0') ?? 0;
    String driverName = (trip.driverName?.trim().isNotEmpty ?? false) ? trip.driverName! : 'كابتن لَمَّة';
    String timeString = trip.travelDate != null ? DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(trip.travelDate!) : 'غير محدد';
    String price = trip.seatPrice ?? trip.price ?? 'غير محدد';

    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 18.r, backgroundColor: Colors.grey.shade200, child: Icon(Icons.person, color: Colors.grey.shade600, size: 20.sp)),
                    SizedBox(width: 8.w),
                    Text(driverName, style: TextStyle(fontWeight: FontWeight.bold, color: darkSlate, fontFamily: 'Cairo', fontSize: 14.sp)),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8.r)),
                  child: Text('متاح $maxSeats مقاعد', style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12.sp, fontFamily: 'Cairo')),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10.r)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(timeString, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
                  Text('$price ج.م', style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            maxSeats <= 0
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade400, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
                      onPressed: null,
                      child: const Text('الرحلة مكتملة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: darkSlate, padding: EdgeInsets.symmetric(vertical: 12.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
                      onPressed: () => _showSeatDialog(context, trip.id!, trip.driverId!, maxSeats),
                      child: Text('احجز مقعدك الآن', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.white)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showSeatDialog(BuildContext context, String tripId, String driverId, int maxSeats) {
    int selectedSeats = 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            title: Text('عدد المقاعد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: royalGreen), textAlign: TextAlign.center),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: selectedSeats > 1 ? () => setState(() => selectedSeats--) : null, icon: Icon(Icons.remove_circle, color: selectedSeats > 1 ? Colors.red : Colors.grey)),
                Text('$selectedSeats', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 20.sp)),
                IconButton(onPressed: selectedSeats < maxSeats ? () => setState(() => selectedSeats++) : null, icon: Icon(Icons.add_circle, color: selectedSeats < maxSeats ? royalGreen : Colors.grey)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: royalGreen),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<TripBookingCubit>().bookSelectedTrip(tripId: tripId, driverId: driverId, requestedSeats: selectedSeats);
                },
                child: const Text('تأكيد', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          );
        },
      ),
    );
  }
}