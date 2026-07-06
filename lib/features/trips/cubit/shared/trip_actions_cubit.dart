import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lamma_new/features/trips/data/models/trip_model.dart';
import 'trip_actions_state.dart';

class TripActionsCubit extends Cubit<TripActionsState> {
  TripActionsCubit() : super(TripActionsInitial());

  // 1. إرسال إشعارات (FCM)
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

  // 2. إرسال عرض سعر (Negotiation)
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
      emit(TripActionsSuccess(action: 'negotiate', message: 'تم إرسال العرض بنجاح'));
    } catch (e) {
      debugPrint("Firebase Error in sendOffer: $e");
      emit(TripActionsError("حدث خطأ أثناء إرسال العرض."));
    }
  }

  // 3. قبول عرض
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
      emit(TripActionsSuccess(action: 'accept', message: 'تم قبول الرحلة بنجاح'));
    } catch (e) {
      emit(TripActionsError("حدث خطأ أثناء القبول."));
    }
  }

  // 4. إلغاء الرحلة
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
        emit(TripActionsSuccess(action: 'reject', message: 'تم رفض العرض والعودة للبحث'));
      } else {
        await FirebaseFirestore.instance.collection('trips').doc(trip.id ?? '').update({
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
        emit(TripActionsSuccess(action: 'cancel', message: 'تم إلغاء الرحلة بالكامل'));
      }
    } catch (e) {
      emit(TripActionsError("حدث خطأ أثناء الإلغاء."));
    }
  }

  // 5. نشر رحلة جديدة (سائق)
  Future<void> publishTravelPost(TripModel trip) async {
    emit(TripActionsLoading());
    try {
      await FirebaseFirestore.instance.collection('trips').add(trip.toMap());
      emit(TripActionsSuccess(action: 'publish', message: 'تم نشر الرحلة بنجاح!'));
    } catch (e) {
      emit(TripActionsError("حدث خطأ أثناء النشر."));
    }
  }

  // 🟢 6. بدء الرحلة (حالة in_progress)
  Future<void> startTrip(String tripId) async {
    emit(TripActionsLoading());
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
      });
      emit(TripActionsSuccess(action: 'start', message: 'تم بدء الرحلة!'));
    } catch (e) {
      emit(TripActionsError("خطأ في بدء الرحلة."));
    }
  }

  // 🟢 7. إنهاء الرحلة (حالة completed)
  Future<void> completeTrip(String tripId) async {
    emit(TripActionsLoading());
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      emit(TripActionsSuccess(action: 'complete', message: 'رحلة سعيدة!'));
    } catch (e) {
      emit(TripActionsError("خطأ في إنهاء الرحلة."));
    }
  }

  // 🟢 8. تحديث الموقع لايف
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
}