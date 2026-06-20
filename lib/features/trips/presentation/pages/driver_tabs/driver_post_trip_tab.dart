// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverPostTripTab extends StatefulWidget {
  final TabController tabController;
  const DriverPostTripTab({super.key, required this.tabController});

  @override
  State<DriverPostTripTab> createState() => _DriverPostTripTabState();
}

class _DriverPostTripTabState extends State<DriverPostTripTab> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color royalGreen = const Color(0xFF1B4332);

  final TextEditingController _postFromCtrl = TextEditingController();
  final TextEditingController _postToCtrl = TextEditingController();
  final TextEditingController _postTimeCtrl = TextEditingController();
  final TextEditingController _postVehicleTypeCtrl = TextEditingController();
  final TextEditingController _postSeatsCtrl = TextEditingController();
  final TextEditingController _postPriceCtrl = TextEditingController();

  @override
  void dispose() {
    _postFromCtrl.dispose();
    _postToCtrl.dispose();
    _postTimeCtrl.dispose();
    _postVehicleTypeCtrl.dispose(); 
    _postSeatsCtrl.dispose();
    _postPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: royalGreen, onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: royalGreen, onPrimary: Colors.white, onSurface: Colors.black),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          String amPm = pickedTime.period == DayPeriod.am ? 'ص' : 'م';
          int hour12 = pickedTime.hourOfPeriod == 0 ? 12 : pickedTime.hourOfPeriod;
          String minute = pickedTime.minute.toString().padLeft(2, '0');
          _postTimeCtrl.text = "${pickedDate.year}/${pickedDate.month}/${pickedDate.day} - $hour12:$minute $amPm";
        });
      }
    }
  }

  Future<void> _postNewTrip() async {
    if (_postFromCtrl.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('trips').add({
      'isDriverPost': true, 
      'driverId': currentUserId, 
      'driverName': 'كابتن', 
      'fromCity': _postFromCtrl.text.trim(), 
      'toCity': _postToCtrl.text.trim(), 
      'time': _postTimeCtrl.text.trim(), 
      'vehicleType': _postVehicleTypeCtrl.text.trim().isNotEmpty ? _postVehicleTypeCtrl.text.trim() : 'سيارة',
      'availableSeats': _postSeatsCtrl.text.trim(), 
      'price': _postPriceCtrl.text.trim(), 
      'status': 'available', 
      'createdAt': FieldValue.serverTimestamp()
    });
    if(mounted) { 
      _postFromCtrl.clear(); 
      _postToCtrl.clear();
      _postTimeCtrl.clear();
      _postVehicleTypeCtrl.clear(); 
      _postSeatsCtrl.clear();
      _postPriceCtrl.clear();
      widget.tabController.animateTo(2); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('طرح رحلة سفر جديدة', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              const SizedBox(height: 20),
              TextField(controller: _postFromCtrl, decoration: InputDecoration(labelText: 'مدينة التحرك', prefixIcon: const Icon(Icons.location_on), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              TextField(controller: _postToCtrl, decoration: InputDecoration(labelText: 'مدينة الوصول', prefixIcon: const Icon(Icons.flag), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              TextField(
                controller: _postTimeCtrl, 
                readOnly: true, 
                onTap: () => _selectDateTime(context),
                decoration: InputDecoration(labelText: 'موعد وتاريخ التحرك', prefixIcon: const Icon(Icons.calendar_month), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
              ),
              const SizedBox(height: 16),
              TextField(controller: _postVehicleTypeCtrl, decoration: InputDecoration(labelText: 'نوع العربية (مثال: ملاكي، ميكروباص 14)', prefixIcon: const Icon(Icons.directions_car_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              
              Row(children: [
                Expanded(child: TextField(controller: _postSeatsCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'المقاعد المتاحة', prefixIcon: const Icon(Icons.airline_seat_recline_normal), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))), 
                const SizedBox(width: 12), 
                Expanded(child: TextField(controller: _postPriceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'سعر المقعد (ج)', prefixIcon: const Icon(Icons.payments_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))))
              ]),
              const SizedBox(height: 24),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: royalGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _postNewTrip, child: const Text('نشر الرحلة للعملاء', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')))
            ],
          ),
        ),
      ),
    );
  }
}