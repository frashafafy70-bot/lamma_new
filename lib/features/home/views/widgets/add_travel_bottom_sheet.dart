// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// 🟢 تم إزالة import 'package:firebase_auth/firebase_auth.dart'; نهائياً لنظافة المعمارية
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lamma_new/l10n/app_localizations.dart';

import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_actions_cubit.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_status.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';
import 'package:lamma_new/core/constants/app_constants.dart';

class AddTravelBottomSheet extends StatefulWidget {
  final String userName;
  final String driverId; // 🟢 التعديل الاحترافي: استقبال الـ ID من الخارج

  const AddTravelBottomSheet({
    super.key,
    required this.userName,
    required this.driverId, // 🟢 إجبار الشاشة الأب على تمرير الـ ID
  });

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
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding:
            EdgeInsets.only(left: 20.w, right: 20.w, top: 16.h, bottom: 20.h),
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
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10.r)))),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Icon(Icons.directions_bus_filled_rounded,
                        color: goldAccent, size: 28.sp),
                    SizedBox(width: 10.w),
                    Text(l10n.travel_publishNewTrip,
                        style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: primaryNavy)),
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
                              color: !isFullCar
                                  ? royalGreen
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                  color: !isFullCar
                                      ? royalGreen
                                      : Colors.grey.shade300)),
                          child: Center(
                              child: Text(l10n.travel_individualSeats,
                                  style: TextStyle(
                                      color: !isFullCar
                                          ? Colors.white
                                          : primaryNavy,
                                      fontWeight: FontWeight.bold))),
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
                              color:
                                  isFullCar ? royalGreen : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                  color: isFullCar
                                      ? royalGreen
                                      : Colors.grey.shade300)),
                          child: Center(
                              child: Text(l10n.travel_fullCar,
                                  style: TextStyle(
                                      color: isFullCar
                                          ? Colors.white
                                          : primaryNavy,
                                      fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                if (!isFullCar) ...[
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10.r)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.travel_availableSeatsCount,
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: primaryNavy)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.redAccent),
                              onPressed: () {
                                if (availableSeats > 1)
                                  setState(() => availableSeats--);
                              },
                            ),
                            Text('$availableSeats',
                                style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle,
                                  color: Colors.green),
                              onPressed: () {
                                if (availableSeats < 14)
                                  setState(() => availableSeats++);
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
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.travel_enterDepartureError
                      : null,
                  decoration: InputDecoration(
                    labelText: l10n.travel_departurePoint,
                    prefixIcon: const Icon(Icons.my_location_rounded,
                        color: Colors.blueAccent),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.r)),
                  ),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: toCtrl,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.travel_enterDestinationError
                      : null,
                  decoration: InputDecoration(
                    labelText: l10n.travel_destinationPoint,
                    prefixIcon: const Icon(Icons.location_on_rounded,
                        color: Colors.redAccent),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.r)),
                  ),
                ),
                SizedBox(height: 16.h),
                InkWell(
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (pickedDate != null && context.mounted) {
                      TimeOfDay? pickedTime = await showTimePicker(
                          context: context, initialTime: TimeOfDay.now());
                      if (pickedTime != null) {
                        setState(() {
                          selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute);
                        });
                      }
                    }
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(15.r)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            color: Colors.orange),
                        SizedBox(width: 10.w),
                        Text(
                          selectedDate == null
                              ? l10n.travel_dateAndTime
                              : DateFormat('yyyy/MM/dd - hh:mm a', 'en')
                                  .format(selectedDate!),
                          style: TextStyle(
                              fontSize: 14.sp,
                              color: selectedDate == null
                                  ? Colors.grey.shade600
                                  : primaryNavy),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.travel_enterPriceError
                      : null,
                  decoration: InputDecoration(
                    labelText: isFullCar
                        ? l10n.travel_fullTripPrice
                        : l10n.travel_singleSeatPrice,
                    prefixIcon: Icon(Icons.payments_rounded, color: royalGreen),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.r)),
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryNavy,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r))),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      if (selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(l10n.travel_selectDateError,
                                style: const TextStyle(fontFamily: 'Cairo')),
                            backgroundColor: Colors.red));
                        return;
                      }

                      // 🟢 استخدام widget.driverId المرسل من الخارج
                      bool hasActiveTrip = await context
                          .read<DriverActiveTripsCubit>()
                          .checkHasActiveTrip(widget.driverId);

                      if (!context.mounted) return;

                      if (hasActiveTrip) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(l10n.travel_activeTripExistError,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ));
                        return;
                      }

                      Navigator.pop(context);

                      final newTrip = TripEntity(
                        isDriverPost: true,
                        driverId: widget.driverId, // 🟢 تم التطبيق هنا أيضاً
                        driverName: widget.userName,
                        pickup: fromCtrl.text.trim(),
                        destination: toCtrl.text.trim(),
                        travelDate: selectedDate!,
                        price: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                        tripCategory: AppConstants.travelCategory,
                        tripType: isFullCar
                            ? AppConstants.fullCarType
                            : AppConstants.seatsType,
                        availableSeats: isFullCar ? 1 : availableSeats,
                        status: TripStatus.available,
                      );

                      context
                          .read<TripActionsCubit>()
                          .publishTravelPost(newTrip);
                    },
                    child: Text(l10n.travel_publishBtn,
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: goldAccent)),
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
