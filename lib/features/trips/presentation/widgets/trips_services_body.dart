import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

import '../../cubit/shared/trips_services_cubit.dart';
import '../../cubit/shared/trips_services_state.dart';
import 'service_card_widget.dart';
import 'trip_form.dart'; 
import 'trip_map.dart'; 

class TripsServicesBody extends StatefulWidget {
  const TripsServicesBody({super.key});

  @override
  State<TripsServicesBody> createState() => _TripsServicesBodyState();
}

class _TripsServicesBodyState extends State<TripsServicesBody> {
  late TextEditingController _errandDetailsController;
  late TextEditingController _errandEstimatedCostController;
  late TextEditingController _pickupController;
  late TextEditingController _destinationController;
  late TextEditingController _priceController;
  late FocusNode _priceFocusNode;

  String _currentCategory = 'داخلي';
  String _currentVehicleType = 'سيارة';
  
  GeoPoint? _pickupGeoPoint;
  GeoPoint? _destinationGeoPoint;

  @override
  void initState() {
    super.initState();
    _errandDetailsController = TextEditingController();
    _errandEstimatedCostController = TextEditingController();
    _pickupController = TextEditingController();
    _destinationController = TextEditingController();
    _priceController = TextEditingController();
    _priceFocusNode = FocusNode();
    
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isNotEmpty) {
      context.read<TripsServicesCubit>().fetchTrips(currentUserId);
    }
  }

  @override
  void dispose() {
    _errandDetailsController.dispose();
    _errandEstimatedCostController.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  void _openTripFormBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return TripForm(
              tripCategory: _currentCategory,
              vehicleType: _currentVehicleType,
              isSubmittingTrip: false, 
              errandDetailsController: _errandDetailsController,
              errandEstimatedCostController: _errandEstimatedCostController,
              pickupController: _pickupController,
              destinationController: _destinationController,
              priceController: _priceController,
              priceFocusNode: _priceFocusNode,
              primaryGreen: const Color(0xFF131E31), 
              accentGold: const Color(0xFFD4AF37), 
              onCategoryChanged: (category) {
                setSheetState(() => _currentCategory = category);
              },
              onVehicleChanged: (vehicle) {
                setSheetState(() => _currentVehicleType = vehicle);
              },
              onOpenMapSelection: (type) async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TripMap()),
                );

                if (result != null && result is Map<String, dynamic>) {
                  setSheetState(() {
                    if (type == 'pickup') {
                      _pickupController.text = result['address'];
                      _pickupGeoPoint = result['location'];
                    } else if (type == 'destination') {
                      _destinationController.text = result['address'];
                      _destinationGeoPoint = result['location'];
                    }
                  });
                }
              },
              onSubmit: () {
                if (_pickupController.text.isEmpty || _destinationController.text.isEmpty || _priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('برجاء ملء جميع الحقول المطلوبة', style: TextStyle(fontFamily: 'Cairo'))),
                  );
                  return;
                }

                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  context.read<TripsServicesCubit>().requestNewTrip(
                    passengerId: currentUser.uid,
                    passengerName: currentUser.displayName ?? 'عميل جديد',
                    pickup: _pickupController.text,
                    destination: _destinationController.text,
                    suggestedPrice: _priceController.text,
                    vehicleType: _currentVehicleType,
                    pickupLocation: _pickupGeoPoint, 
                    destinationLocation: _destinationGeoPoint, 
                  );

                  _pickupController.clear();
                  _destinationController.clear();
                  _priceController.clear();
                  _pickupGeoPoint = null;
                  _destinationGeoPoint = null;
                  
                  Navigator.pop(sheetContext);
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<TripsServicesCubit, TripsServicesState>(
        builder: (context, state) {
          if (state is TripsServicesLoading || state is TripsServicesInitial) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          }

          if (state is TripsServicesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.errorMessage, 
                    style: const TextStyle(color: Colors.red, fontFamily: 'Cairo'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF121212)),
                    onPressed: () {
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                      context.read<TripsServicesCubit>().fetchTrips(currentUserId);
                    },
                    child: const Text('إعادة المحاولة', style: TextStyle(color: Color(0xFFD4AF37), fontFamily: 'Cairo')),
                  ),
                ],
              ),
            );
          }

          if (state is TripsServicesSuccess) {
            if (state.trips.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد رحلات متاحة حالياً',
                  style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Cairo'),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.trips.length,
              itemBuilder: (context, index) {
                final trip = state.trips[index];
                
                // 🟢 هنا الحل السحري: تم الاكتفاء بإرسال serviceData فقط ليتطابق مع الكارد
                return ServiceCardWidget(
                  serviceData: trip,
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openTripFormBottomSheet,
        backgroundColor: const Color(0xFF131E31), 
        icon: const Icon(Icons.add_location_alt_rounded, color: Color(0xFFD4AF37)), 
        label: const Text(
          'اطلب كابتن', 
          style: TextStyle(color: Color(0xFFD4AF37), fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}