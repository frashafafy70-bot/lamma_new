import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lamma_new/core/theme/app_colors.dart'; 
import '../cubit/trip_cubit.dart';
import '../cubit/trip_state.dart';

class TripsTestPage extends StatefulWidget {
  const TripsTestPage({super.key});

  @override
  State<TripsTestPage> createState() => _TripsTestPageState();
}

class _TripsTestPageState extends State<TripsTestPage> {
  @override
  void initState() {
    super.initState();
    context.read<TripCubit>().loadAllTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'اختبار المعمارية النظيفة (الرحلات)',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: BlocBuilder<TripCubit, TripState>(
        builder: (context, state) {
          if (state is TripsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryDark),
            );
          }
          else if (state is TripsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'حدث خطأ:\n${state.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo', 
                    color: Colors.red, 
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }
          else if (state is TripsLoaded) {
            final trips = state.trips;
            
            if (trips.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد رحلات متاحة حالياً',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 18),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      'من: ${trip.pickup ?? "غير محدد"} ➡️ إلى: ${trip.destination ?? "غير محدد"}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      // 🟢 الغلطة اتصلحت هنا
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('السائق: ${trip.driverName ?? "غير معروف"}'),
                          Text('السعر: ${trip.price ?? "غير محدد"} جنيه'),
                          Text('الحالة: ${trip.status}'),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.directions_car, color: AppColors.primaryDark),
                  ),
                );
              },
            );
          }

          return const Center(
            child: Text(
              'جاري تهيئة البيانات...',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          );
        },
      ),
    );
  }
}