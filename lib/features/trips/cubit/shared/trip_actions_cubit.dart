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

  // ⚠️ تنبيه أمني: إرسال الإشعارات من التطبيق غير آمن. سيتم نقل هذه الدالة للـ Backend (Cloud Functions) لاحقاً.
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
    emit(TripActionsLoading());
    try {
      await FirebaseFirestore.instance.collection('trips').doc(trip.id ?? '').update({
        'status': 'negotiating',
        'negotiationPrice': price.trim(),
        'lastNegotiator': isDriver ? 'driver' : 'passenger',
        'updatedAt': FieldValue.serverTimestamp(), 
        if (isDriver && trip.driverId == null) 'driverId': currentUserId,
      });
      
      await _notifyOtherParty(trip, isDriver, 'عرض سعر جديد 💰', 'تم تقديم عرض سعر جديد بقيمة $price ج.م');
      emit(TripActionsSuccess(action: 'negotiate', message: 'تم إرسال العرض بنجاح'));
    } catch (e) {
      emit(TripActionsError("حدث خطأ أثناء إرسال العرض."));
    }
  }

  Future<void> acceptOffer(TripModel trip, bool isDriver, String currentUserId) async {
    emit(TripActionsLoading());
    try {
      String safePrice = trip.negotiationPrice ?? trip.price ?? trip.suggestedPrice ?? '0';

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
        await _notifyOtherParty(trip, isDriver, 'تم رفض العرض ❌', 'العميل رفض العرض ويبحث عن كباتن آخرين.');
        emit(TripActionsSuccess(action: 'reject', message: 'تم رفض العرض والعودة للبحث'));
      } else {
        await FirebaseFirestore.instance.collection('trips').doc(trip.id ?? '').update({
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
        await _notifyOtherParty(trip, isDriver, 'إلغاء الرحلة ⚠️', 'تم إلغاء الرحلة.');
        emit(TripActionsSuccess(action: 'cancel', message: 'تم إلغاء الرحلة بالكامل'));
      }
    } catch (e) {
      emit(TripActionsError("حدث خطأ أثناء الإلغاء."));
    }
  }

  Future<void> deleteTripFromList(TripModel trip, bool isDriver) async {
    emit(TripActionsLoading());
    try {
      String fieldToUpdate = isDriver ? 'isDeletedForDriver' : 'isDeletedForPassenger';
      await FirebaseFirestore.instance.collection('trips').doc(trip.id ?? '').update({
        fieldToUpdate: true,
      });
      emit(TripActionsSuccess(action: 'delete', message: 'تم مسح الطلب من القائمة'));
    } catch (e) {
      emit(TripActionsError("حدث خطأ أثناء المسح."));
    }
  }
}