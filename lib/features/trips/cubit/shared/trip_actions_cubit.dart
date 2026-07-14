import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:lamma_new/features/trips/data/models/trip_model.dart';
import '../../domain/usecases/cancel_trip_use_case.dart'; // 🟢 تم تصحيح الاسم هنا
import '../../domain/usecases/update_booking_seats_use_case.dart';
import '../../domain/usecases/submit_negotiation_use_case.dart';
import '../../domain/repositories/trip_repository.dart';
import 'trip_actions_state.dart';

class TripActionsCubit extends Cubit<TripActionsState> {
  final TripRepository tripRepository;
  final CancelTripUseCase cancelTripUseCase;
  final UpdateBookingSeatsUseCase updateBookingSeatsUseCase;
  final SubmitNegotiationUseCase submitNegotiationUseCase;

  TripActionsCubit({
    required this.tripRepository,
    required this.cancelTripUseCase,
    required this.updateBookingSeatsUseCase,
    required this.submitNegotiationUseCase,
  }) : super(TripActionsInitial());

  // ==========================================
  // 🌟 الدوال الجديدة (Clean Architecture)
  // ==========================================

  Future<void> cancelTripFully({required String tripId, required bool isDriver}) async {
    emit(TripActionsLoading());
    
    final result = await cancelTripUseCase(tripId: tripId, isDriver: isDriver);
    
    if (isClosed) return;
    result.fold(
      (failure) => emit(TripActionsError(failure.message)),
      (_) => emit(TripActionsSuccess(action: 'cancel', message: 'تم إلغاء الرحلة بنجاح')),
    );
  }

  Future<void> updateBookingSeats({required String bookingId, required int newSeats, required DateTime travelDate}) async {
    emit(TripActionsLoading());
    
    final result = await updateBookingSeatsUseCase(bookingId: bookingId, newSeats: newSeats, travelDate: travelDate);
    
    if (isClosed) return;
    result.fold(
      (failure) => emit(TripActionsError(failure.message)),
      (_) => emit(TripActionsSuccess(action: 'update_booking', message: 'تم تعديل الحجز بنجاح')),
    );
  }

  Future<void> submitNegotiationOffer({required String docId, required double offerPrice, required bool isDriver}) async {
    emit(TripActionsLoading());
    
    final result = await submitNegotiationUseCase(docId: docId, offerPrice: offerPrice, isDriver: isDriver);
    
    if (isClosed) return;
    result.fold(
      (failure) => emit(TripActionsError(failure.message)),
      (_) => emit(TripActionsSuccess(action: 'negotiate', message: 'تم إرسال العرض بنجاح')),
    );
  }

  // ==========================================
  // 🟠 الدوال القديمة (تعمل بشكل ممتاز)
  // ==========================================

  Future<void> addTravelTrip({required TripModel trip}) async {
    emit(TripActionsLoading());
    try {
      await FirebaseFirestore.instance.collection('trips').add({
        'driverId': trip.driverId,
        'driverName': trip.driverName,
        'pickup': trip.pickup,
        'destination': trip.destination,
        'travelDate': trip.travelDate,
        'price': trip.price,
        'tripCategory': trip.tripCategory,
        'tripType': trip.tripType,
        'availableSeats': trip.availableSeats,
        'status': trip.status,
        'isDriverPost': trip.isDriverPost,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (isClosed) return; 
      emit(TripActionsSuccess(action: 'add', message: 'تم إضافة الرحلة بنجاح!'));
    } catch (e) {
      debugPrint("Error adding travel trip: $e");
      if (isClosed) return;
      emit(TripActionsError("حدث خطأ أثناء إضافة الرحلة."));
    }
  }

  Future<void> _notifyOtherParty(TripModel trip, bool isDriver, String title, String body) async {
    try {
      String targetUserId = isDriver ? (trip.passengerId ?? '') : (trip.driverId ?? '');
      if (targetUserId.isEmpty) return;

      var userDoc = await FirebaseFirestore.instance.collection('users').doc(targetUserId).get();
      String? fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        String serverKey = dotenv.env['FCM_SERVER_KEY'] ?? ''; 
        await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$serverKey',
          },
          body: jsonEncode({
            'to': fcmToken,
            'notification': {'title': title, 'body': body},
            'data': {'tripId': trip.id ?? '', 'channel_id': 'lamma_final_sound'}
          }),
        );
      }
    } catch (e) {
      debugPrint("FCM Error: $e");
    }
  }

  Future<void> sendOffer(TripModel trip, String price, bool isDriver, String currentUserId) async {
    if (price.trim().isEmpty) return;
    
    if (trip.id == null || trip.id!.isEmpty) {
      emit(TripActionsError("حدث خطأ: معرف الرحلة مفقود."));
      throw Exception('Trip ID is null');
    }

    emit(TripActionsLoading());
    try {
      await FirebaseFirestore.instance.collection('trips').doc(trip.id).update({
        'status': 'negotiating',
        'negotiationPrice': double.tryParse(price.trim()) ?? price.trim(), 
        'lastNegotiator': isDriver ? 'driver' : 'passenger',
        'updatedAt': FieldValue.serverTimestamp(), 
        if (isDriver && trip.driverId == null) 'driverId': currentUserId,
      });
      
      await _notifyOtherParty(trip, isDriver, 'عرض سعر جديد 💰', 'تم تقديم عرض سعر جديد بقيمة $price ج.م');
      if (isClosed) return;
      emit(TripActionsSuccess(action: 'negotiate', message: 'تم إرسال العرض بنجاح'));
    } catch (e) {
      debugPrint("Firebase Error in sendOffer: $e");
      if (isClosed) return;
      emit(TripActionsError("حدث خطأ أثناء إرسال العرض."));
    }
  }

  Future<void> acceptOffer(TripModel trip, bool isDriver, String currentUserId) async {
    emit(TripActionsLoading());
    try {
      String safePrice = trip.negotiationPrice?.toString() ?? trip.price?.toString() ?? trip.suggestedPrice?.toString() ?? '0';

      await FirebaseFirestore.instance.collection('trips').doc(trip.id ?? '').update({
        'status': 'accepted',
        'finalPrice': safePrice,
        'acceptedAt': FieldValue.serverTimestamp(), 
        if (isDriver) 'driverId': currentUserId,
      });

      await _notifyOtherParty(trip, isDriver, 'تم قبول الطلب! 🚖', 'تم الموافقة على السعر، الرحلة جاهزة للبدء.');
      if (isClosed) return;
      emit(TripActionsSuccess(action: 'accept', message: 'تم قبول الرحلة بنجاح'));
    } catch (e) {
      if (isClosed) return;
      emit(TripActionsError("حدث خطأ أثناء القبول."));
    }
  }

  Future<void> rejectOrCancelTrip(TripModel trip, bool isDriver) async {
    emit(TripActionsLoading());
    try {
      if (!isDriver && trip.status == 'negotiating') {
        await FirebaseFirestore.instance.collection('trips').doc(trip.id ?? '').update({
          'status': 'pending',
          'negotiationPrice': FieldValue.delete(),
          'lastNegotiator': FieldValue.delete(),
          'driverId': FieldValue.delete(), 
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (isClosed) return;
        emit(TripActionsSuccess(action: 'reject', message: 'تم رفض العرض والعودة للبحث'));
      } else {
        await FirebaseFirestore.instance.collection('trips').doc(trip.id ?? '').update({
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
        if (isClosed) return;
        emit(TripActionsSuccess(action: 'cancel', message: 'تم إلغاء الرحلة بالكامل'));
      }
    } catch (e) {
      if (isClosed) return;
      emit(TripActionsError("حدث خطأ أثناء الإلغاء."));
    }
  }

  Future<void> publishTravelPost(TripModel trip) async {
    emit(TripActionsLoading());
    try {
      await FirebaseFirestore.instance.collection('trips').add(trip.toMap());
      if (isClosed) return;
      emit(TripActionsSuccess(action: 'publish', message: 'تم نشر الرحلة بنجاح!'));
    } catch (e) {
      if (isClosed) return;
      emit(TripActionsError("حدث خطأ أثناء النشر."));
    }
  }

  Future<void> startTrip(String tripId) async {
    emit(TripActionsLoading());
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
      });
      if (isClosed) return;
      emit(TripActionsSuccess(action: 'start', message: 'تم بدء الرحلة!'));
    } catch (e) {
      if (isClosed) return;
      emit(TripActionsError("خطأ في بدء الرحلة."));
    }
  }

  Future<void> completeTrip(String tripId) async {
    emit(TripActionsLoading());
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      if (isClosed) return;
      emit(TripActionsSuccess(action: 'complete', message: 'رحلة سعيدة!'));
    } catch (e) {
      if (isClosed) return;
      emit(TripActionsError("خطأ في إنهاء الرحلة."));
    }
  }

  Future<void> updateDriverLocation(String tripId, GeoPoint location) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'driverCurrentLocation': location,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating location: $e");
    }
  }

  Future<void> submitRating({required String tripId, required double rating, required String comment}) async {
    emit(TripActionsLoading());
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'passengerRating': rating,
        'passengerComment': comment,
        'isRatedByPassenger': true,
      });
      if (isClosed) return;
      emit(TripActionsSuccess(action: 'rate', message: 'شكراً لتقييمك الكابتن!'));
    } catch (e) {
      debugPrint("Error submitting rating: $e");
      if (isClosed) return;
      emit(TripActionsError("حدث خطأ أثناء إرسال التقييم."));
    }
  }
}